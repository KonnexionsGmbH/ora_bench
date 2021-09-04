package main

import (
	"bufio"
	"context"
	"database/sql"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	errors "golang.org/x/xerrors"

	"github.com/godror/godror"
	log "github.com/sirupsen/logrus"
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
	// log.SetLevel(log.DebugLevel)

	log.Println("Start OraBench.go")
	configs := loadConfig(os.Args[1])

	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	partitions := loadBulk(
		benchmarkNumberPartitions,
		configs["file.bulk.name"].(string),
		configs["file.bulk.delimiter"].(string))

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	trials := configs["benchmark.trials"].(int)
	resultPos := 0

	resultSlice := make([]result, trials*3+1)
	var wg sync.WaitGroup

	startBenchTs := time.Now()

	for t := 1; t <= trials; t++ {
		log.Println("Start trial no.", t)
		initDb(ctx, configs)

		startTrialTs := time.Now()

		start := time.Now()
		wg.Add(benchmarkNumberPartitions)
		for p := 0; p < benchmarkNumberPartitions; p++ {
			go doInsert(ctx, configs, t, p, partitions[p], &wg)
		}
		wg.Wait()

		end := time.Now()
		resultSlice[resultPos] = result{trial: t,
			sql:    configs["sql.insert"].(string),
			action: "query",
			start:  start,
			end:    end}
		resultPos++

		start = time.Now()
		wg.Add(benchmarkNumberPartitions)
		for p := 0; p < benchmarkNumberPartitions; p++ {
			go doSelect(ctx, configs, t, p, len(partitions[p].keys), &wg)
		}
		wg.Wait()

		end = time.Now()
		resultSlice[resultPos] = result{trial: t,
			sql:    configs["sql.select"].(string),
			action: "query",
			start:  start,
			end:    end}
		resultPos++

		endTrialTs := time.Now()
		resultSlice[resultPos] = result{trial: t,
			sql:    "",
			action: "trial",
			start:  startTrialTs,
			end:    endTrialTs}
		resultPos++
	}

	endBenchTs := time.Now()
	resultSlice[resultPos] = result{trial: 0,
		sql:    "",
		action: "benchmark",
		start:  startBenchTs,
		end:    endBenchTs}
	resultPos++

	resultWriter(configs, resultSlice)

	d := endBenchTs.Sub(startBenchTs)
	log.Printf("End   OraBench.go (%.0f sec, %d nsec)\n", d.Seconds(), d.Nanoseconds())

	os.Exit(0)
}

func doInsert(ctx context.Context, configs map[string]interface{}, trial int, partition int, rows bulkPartition, wg *sync.WaitGroup) {
	log.Debug(fmt.Sprintf("Start doInsert(%2d)", partition))

	defer wg.Done()

	log.Debug(fmt.Sprintf("      doInsert(%2d) - connection.dsn=%v", partition, configs["connection.dsn"]))

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("      doInsert(%2d) - %v: %w", configs["connection.dsn"], partition, err))
	}

	log.Debug(fmt.Sprintf("      doInsert(%2d) - db pointer=%p", partition, &db))

	// wwe
	//defer func(db *sql.DB) {
	//	log.Debug(fmt.Sprintf("Start doInsert(%2d) - defer(db)", partition))
	//	log.Debug(fmt.Sprintf("      doInsert(%2d) - defer(db) - db pointer=%p", partition, &db))
	//
	//	deferErr := db.Close()
	//	if err == nil {
	//		err = deferErr
	//	}
	//	if err != nil {
	//		log.Fatal(errors.Errorf("      doInsert(%2d) - %v: %w", "db.Close()", partition, err))
	//	}
	//
	//	log.Debug(fmt.Sprintf("End   doInsert(%2d) - defer(db)", partition))
	//}(db)

	sqlInsert := configs["sql.insert"].(string)

	resultInsert, err := db.ExecContext(ctx, sqlInsert, rows.keys, rows.vals)
	if err != nil {
		log.Fatal(
			errors.Errorf(
				"      doInsert(%2d) - Trial %d, Partition %d, SQL %s -> %w", partition, trial, partition, sqlInsert,
				err))
	}

	rowCount, err := resultInsert.RowsAffected()
	if err != nil {
		log.Fatal(err)
	}

	if int(rowCount) != len(rows.keys) {
		log.Fatalf(
			"      doInsert(%2d) - Trial %d, Partition %d: %d of %d rows inserted by %s", partition,
			trial, partition, len(rows.keys), rowCount, sqlInsert)
	}

	log.Debug(fmt.Sprintf("End   doInsert(%2d)", partition))
}

func doSelect(ctx context.Context, configs map[string]interface{}, trial int, partition int, expect int, wg *sync.WaitGroup) {
	log.Debug(fmt.Sprintf("Start doSelect(%2d)", partition))

	defer wg.Done()

	log.Debug(fmt.Sprintf("      doSelect(%2d) - connection.dsn=%v", partition, configs["connection.dsn"]))

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}

	log.Debug(fmt.Sprintf("      doSelect(%2d) - db pointer=%p", partition, &db))

	// wwe
	//defer func(db *sql.DB) {
	//	log.Debug(fmt.Sprintf("Start doSelect(%2d) - defer(db)", partition))
	//	log.Debug(fmt.Sprintf("      doSelect(%2d) - defer(db) - db pointer=%p", partition, &db))
	//
	//	deferErr := db.Close()
	//	if err == nil {
	//		err = deferErr
	//	}
	//	if err != nil {
	//		log.Fatal(errors.Errorf("      doSelect(%2d) - defer(db) - %v: %w", "db.Close()", partition, err))
	//	}
	//
	//	log.Debug(fmt.Sprintf("End   doSelect(%2d) - defer(db)", partition))
	//}(db)

	selectSQL := configs["sql.select"].(string) + " WHERE partition_key = " +
		strconv.Itoa(partition)
	opts := godror.FetchRowCount(configs["connection.fetch.size"].(int))

	rows, err := db.QueryContext(ctx, selectSQL, opts)
	if err != nil {
		log.Fatal(errors.Errorf("      doSelect(%2d) - %v: %w", "db.Close()", partition, err))
	}

	defer func(rows *sql.Rows) {
		log.Debug(fmt.Sprintf("Start doSelect(%2d) - defer(rows)", partition))
		log.Debug(fmt.Sprintf("      doSelect(%2d) - defer(rows) - db pointer=%p", partition, &db))

		deferErr := rows.Close()
		if err == nil {
			err = deferErr
		}
		if err != nil {
			log.Fatal(errors.Errorf("      doSelect(%2d) - defer(rows) - %v: %w", "rows.Close()", partition, err))
		}

		log.Debug(fmt.Sprintf("End   doSelect(%2d) - defer(rows)", partition))
	}(rows)

	i := 0
	for rows.Next() {
		i++
	}

	if i != expect {
		log.Fatal(
			errors.Errorf(
				"      doSelect(%2d) - Trial %d, Partition %d : failed to get %d rows (got %d)\n",
				trial, partition, expect, i))
	}

	log.Debug(fmt.Sprintf("Start doSelect(%2d)", partition))
}

func initDb(ctx context.Context, configs map[string]interface{}) {
	log.Debug("Start initDb()")

	db, err := sql.Open("godror",
		configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}

	defer func(db *sql.DB) {
		log.Debug("Start initDb() - defer(db)")

		err := db.Close()
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "db.Close()", err))
		}

		log.Debug("End   initDb() - defer(db)")
	}(db)

	_, err = db.ExecContext(ctx, configs["sql.create"].(string))
	if err != nil {
		_, err = db.ExecContext(ctx, configs["sql.drop"].(string))
		if err != nil {
			log.Println(errors.Errorf("%s -> %w", configs["sql.drop"].(string), err))
			os.Exit(1)
		}

		_, err = db.ExecContext(ctx, configs["sql.create"].(string))
		if err != nil {
			log.Println(errors.Errorf("%s -> %w", configs["sql.drop"].(string), err))
			os.Exit(1)
		}
	}

	log.Debug("End   initDb()")
}

func loadBulk(benchmarkNumberPartitions int, fileBulkName string, fileBulkDelimiter string) []bulkPartition {
	log.Debug("Start loadBulk()")

	log.Println("Start Distribution of the data in the partitions")

	partitions := make([]bulkPartition, benchmarkNumberPartitions)

	bulkFile, err := os.Open(fileBulkName)
	if err != nil {
		log.Fatal(err)
	}

	defer func(bulkFile *os.File) {
		log.Debug("Start loadBulk() - defer(bulkFile)")

		err := bulkFile.Close()
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "bulkFile.Close()", err))
		}

		log.Debug("end   loadBulk() - defer(bulkFile)")
	}(bulkFile)

	scanner := bufio.NewScanner(bulkFile)
	for scanner.Scan() {
		parts := strings.Split(scanner.Text(), fileBulkDelimiter)
		partition := (int(parts[0][0])*251 + int(parts[0][1])) % benchmarkNumberPartitions
		partitions[partition].keys = append(partitions[partition].keys, parts[0])
		partitions[partition].vals = append(partitions[partition].vals, parts[1])
	}

	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	for i, p := range partitions {
		log.Printf("Partition %d has %5d rows\n", i+1, len(p.keys))
	}

	log.Println("End   Distribution of the data in the partitions")

	log.Debug("End   loadBulk()")

	return partitions
}

func loadConfig(configFile string) map[string]interface{} {
	log.Debug("Start loadConfig()")

	configurations := make(map[string]interface{})

	confFile, err := os.Open(configFile)
	if err != nil {
		log.Fatal(err)
	}

	defer func(confFile *os.File) {
		log.Debug("Start loadConfig() - defer(confFile)")

		err := confFile.Close()
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "confFile.Close()", err))
		}

		log.Debug("End   loadConfig() - defer(confFile)")
	}(confFile)

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

	configurations["connection.dsn"] =
		configurations["connection.user"].(string) +
			"/" + configurations["connection.password"].(string) +
			"@" + configurations["connection.host"].(string) +
			":" + fmt.Sprintf("%v", configurations["connection.port"]) +
			"/" + configurations["connection.service"].(string)

	log.Debug("End   loadConfig()")

	return configurations
}

func resultWriter(configs map[string]interface{}, resultChn []result) {
	log.Debug("Start resultWriter()")

	fileResultDelimiter, err := strconv.Unquote("\"" +
		configs["file.result.delimiter"].(string) + "\"")
	if err != nil {
		log.Fatal(err)
	}

	rf, err := os.OpenFile(configs["file.result.name"].(string),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}

	defer func(rf *os.File) {
		log.Debug("Start resultWriter() - defer(rf)")

		err := rf.Close()
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "rf.Close()", err))
		}

		log.Debug("End   resultWriter() - defer(rf)")
	}(rf)

	resultFile := bufio.NewWriter(rf)

	for _, result := range resultChn {
		resultFormat := strings.Join([]string{
			configs["benchmark.release"].(string),
			configs["benchmark.id"].(string),
			configs["benchmark.comment"].(string),
			configs["benchmark.host.name"].(string),
			strconv.Itoa(configs["benchmark.number.cores"].(int)),
			configs["benchmark.os"].(string),
			configs["benchmark.user.name"].(string),
			configs["benchmark.database"].(string),
			"Go " + runtime.Version(),
			"godror " + godror.Version,
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

		d := result.end.Sub(result.start)
		fmt.Fprintf(resultFile, resultFormat, result.trial, result.sql,
			result.action, tsStr(result.start), tsStr(result.end), d.Seconds(),
			d.Nanoseconds())
	}

	resultFile.Flush()

	log.Debug("End   resultWriter()")
}

func tsStr(t time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d %02d:%02d:%02d.%09d", t.Year(), t.Month(),
		t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond())
}