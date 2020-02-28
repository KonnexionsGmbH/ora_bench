package main

import (
	"bufio"
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	godror "github.com/godror/godror"
	errors "golang.org/x/xerrors"
)

type bulkPartition struct{ keys, vals []string }

type result struct {
	trial  int
	sql    string
	action string
	start  time.Time
	end    time.Time
}

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	log.Println("Start")
	configs := loadConfig(os.Args[1])

	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	partitions := loadBulk(
		benchmarkNumberPartitions,
		configs["file.bulk.name"].(string),
		configs["file.bulk.delimiter"].(string))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	resultChn := make(chan result, benchmarkNumberPartitions)
	go resultWriter(configs, resultChn)
	var wg sync.WaitGroup
	startBenchTs := time.Now()
	for t := 0; t <= configs["benchmark.trials"].(int); t++ {
		log.Println("Trial:", t)
		initDb(ctx, configs)

		startTrialTs := time.Now()
		wg.Add(benchmarkNumberPartitions)
		for p := 0; p < benchmarkNumberPartitions; p++ {
			go doInsert(ctx, configs, t, p, partitions[p], resultChn, &wg)
		}
		wg.Wait()

		wg.Add(benchmarkNumberPartitions)
		for p := 0; p < benchmarkNumberPartitions; p++ {
			go doSelect(ctx, configs, t, p, len(partitions[p].keys), resultChn,
				&wg)
		}
		wg.Wait()
		endTrialTs := time.Now()
		resultChn <- result{trial: t,
			sql:    "",
			action: "trial",
			start:  startTrialTs,
			end:    endTrialTs}
	}
	endBenchTs := time.Now()
	resultChn <- result{trial: 0,
		sql:    "",
		action: "benchmark",
		start:  startBenchTs,
		end:    endBenchTs}

	close(resultChn)

	d := endBenchTs.Sub(startBenchTs)
	log.Printf("End (%.0f sec, %d nsec)\n", d.Seconds(), d.Nanoseconds())
}

func doInsert(ctx context.Context, configs map[string]interface{}, trial int, partition int, rows bulkPartition, resultChn chan result, wg *sync.WaitGroup) {
	defer wg.Done()

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}
	defer db.Close()
	sqlInsert := configs["sql.insert"].(string)

	start := time.Now()
	resultInsert, err := db.ExecContext(ctx, sqlInsert, rows.keys, rows.vals)
	if err != nil {
		log.Fatal(
			errors.Errorf(
				"Trial %d, Partition %d, SQL %s -> %w", trial, partition, sqlInsert,
				err))
	}
	rowCount, err := resultInsert.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	if int(rowCount) != len(rows.keys) {
		log.Fatalf(
			"Trial %d, Partition %d: %d of %d rows inserted by %s",
			trial, partition, len(rows.keys), rowCount, sqlInsert)
	}
	end := time.Now()
	resultChn <- result{trial: trial,
		sql:    sqlInsert,
		action: "query",
		start:  start,
		end:    end}
}

func doSelect(ctx context.Context, configs map[string]interface{}, trial int, partition int, expect int, resultChn chan result, wg *sync.WaitGroup) {
	defer wg.Done()

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}
	defer db.Close()
	selectSQL := configs["sql.select"].(string) + " WHERE partition_key = " +
		strconv.Itoa(partition)
	opts := godror.FetchRowCount(configs["connection.fetch.size"].(int))
	start := time.Now()
	rows, err := db.QueryContext(ctx, selectSQL, opts)
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	i := 0
	for rows.Next() {
		i++
	}
	end := time.Now()
	if i != expect {
		log.Fatalf(
			"Trial %d, partition %d : failed to get %d rows (got %d)\n",
			expect, i)
	}
	resultChn <- result{trial: trial,
		sql:    selectSQL,
		action: "query",
		start:  start,
		end:    end}
}

func loadBulk(benchmarkNumberPartitions int, fileBulkName string, fileBulkDelimiter string) []bulkPartition {
	partitions := make([]bulkPartition, benchmarkNumberPartitions)

	bulkFile, err := os.Open(fileBulkName)
	if err != nil {
		log.Fatal(err)
	}
	defer bulkFile.Close()

	scanner := bufio.NewScanner(bulkFile)
	for scanner.Scan() {
		parts := strings.Split(scanner.Text(), fileBulkDelimiter)
		partition := (int(parts[0][0])*256 + int(parts[0][1])) % benchmarkNumberPartitions
		partitions[partition].keys = append(partitions[partition].keys, parts[0])
		partitions[partition].vals = append(partitions[partition].vals, parts[1])
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	for i, p := range partitions {
		log.Printf("Partition %d has %d rows\n", i+1, len(p.keys))
	}

	return partitions
}

func loadConfig(configFile string) map[string]interface{} {
	configurations := make(map[string]interface{})

	confFile, err := os.Open(configFile)
	if err != nil {
		log.Fatal(err)
	}
	defer confFile.Close()

	scanner := bufio.NewScanner(confFile)
	for scanner.Scan() {
		parts := strings.Split(scanner.Text(), "=")
		if len(parts) > 1 {
			key := parts[0]
			val := strings.Join(parts[1:], "=")
			if n, err := strconv.Atoi(val); err == nil {
				configurations[key] = n
			} else {
				configurations[key] = val
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	configurations["connection.dsn"] = "oracle://" +
		configurations["connection.user"].(string) +
		":" + configurations["connection.password"].(string) +
		"@" + configurations["connection.host"].(string) +
		":" + fmt.Sprintf("%v", configurations["connection.port"]) +
		"/" + configurations["connection.service"].(string)

	return configurations
}

func initDb(ctx context.Context, configs map[string]interface{}) {
	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}
	defer db.Close()

	result, err := db.ExecContext(ctx, configs["sql.drop"].(string))
	if err != nil {
		log.Println(errors.Errorf("%s -> %w", configs["sql.drop"].(string), err))
	}
	rows, err := result.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	if rows != 0 && rows != 1 {
		log.Fatalf(
			"UNEXPECTED number of rows affected %d (%s)",
			rows, configs["sql.drop"].(string))
	}

	result, err = db.ExecContext(ctx, configs["sql.create"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%s -> %w", configs["sql.create"].(string), err))
	}
	rows, err = result.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}
	if rows != 1 {
		log.Fatalf(
			"UNEXPECTED number of rows affected %d (%s)",
			rows, configs["sql.create"].(string))
	}
}

func tsStr(t time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d %02d:%02d:%02d.%09d", t.Year(), t.Month(),
		t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond())
}

func resultWriter(configs map[string]interface{}, resultChn chan result) {
	fileResultDelimiter, err := strconv.Unquote("\"" +
		configs["file.result.delimiter"].(string) + "\"")
	if err != nil {
		log.Fatal(err)
	}

	fileResultHeader := strings.ReplaceAll(configs["file.result.header"].(string),
		";", fileResultDelimiter)

	resultFormat := strings.Join([]string{
		configs["benchmark.release"].(string),
		configs["benchmark.id"].(string),
		configs["benchmark.comment"].(string),
		configs["benchmark.host.name"].(string),
		strconv.Itoa(configs["benchmark.number.cores"].(int)),
		configs["benchmark.os"].(string),
		configs["benchmark.user.name"].(string),
		configs["benchmark.database"].(string),
		runtime.Version(), //	language
		"godror ", godror.Version,
		"%d", // trial no.
		"%s", // SQL statement
		strconv.Itoa(configs["benchmark.core.multiplier"].(int)),
		strconv.Itoa(configs["connection.fetch.size"].(int)),
		strconv.Itoa(configs["benchmark.transaction.size"].(int)),
		strconv.Itoa(configs["file.bulk.length"].(int)),
		strconv.Itoa(configs["file.bulk.size"].(int)),
		strconv.Itoa(configs["benchmark.batch.size"].(int)),
		"%s",   // action
		"%s",   // start day time
		"%s",   // end day time
		"%.0f", // duration (sec)
		"%d",   // duration (ns)
		"\n"}, fileResultDelimiter)

	rf, err := os.OpenFile(configs["file.result.name"].(string),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer rf.Close()

	resultFile := bufio.NewWriter(rf)
	fmt.Fprint(resultFile, fileResultHeader)
	for result := range resultChn {
		d := result.end.Sub(result.start)
		fmt.Fprintf(resultFile, resultFormat, result.trial, result.sql,
			result.action, tsStr(result.start), tsStr(result.end), d.Seconds(),
			d.Nanoseconds())
	}
	resultFile.Flush()
}