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
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	log.Println("Start orabench.go")
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
	log.Printf("End   orabench.go (%.0f sec, %d nsec)\n", d.Seconds(), d.Nanoseconds())

	os.Exit(0)
}

func doInsert(ctx context.Context, configs map[string]interface{}, trial int, partition int, rows bulkPartition, wg *sync.WaitGroup) {
	log.Printf("Start doInsert()")
	defer wg.Done()

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Print(errors.Errorf("%v: %w", configs["connection.dsn"], err))
		os.Exit(1)
	}

	defer func(db *sql.DB) {
		log.Printf("      doInsert() - defer func")
		err := db.Close()
		if err != nil {
			errorsnt(errors.Errorf("%v: %w", "db.Close()", err))
			os.Exit(1)
		}
	}(db)

	sqlInsert := configs["sql.insert"].(string)

	resultInsert, err := db.ExecContext(ctx, sqlInsert, rows.keys, rows.vals)
	if err != nil {
		log.Print(
			errors.Errorf(
				"Trial %d, Partition %d, SQL %s -> %w", trial, partition, sqlInsert,
				err))
		os.Exit(1)
	}

	rowCount, err := resultInsert.RowsAffected()
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "resultInsert.RowsAffected()", err))
		os.Exit(1)
	}

	if int(rowCount) != len(rows.keys) {
		log.Printf(
			"Trial %d, Partition %d: %d of %d rows inserted by %s",
			trial, partition, len(rows.keys), rowCount, sqlInsert)
		os.Exit(1)
	}

	log.Printf("End   doInsert()")
}

func doSelect(ctx context.Context, configs map[string]interface{}, trial int, partition int, expect int, wg *sync.WaitGroup) {
	defer wg.Done()

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Print(errors.Errorf("%v: %w", configs["connection.dsn"], err))
		os.Exit(1)
	}

	defer func(db *sql.DB) {
		err := db.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "db.Close()", err))
			os.Exit(1)
		}
	}(db)

	selectSQL := configs["sql.select"].(string) + " WHERE partition_key = " +
		strconv.Itoa(partition)
	opts := godror.FetchRowCount(configs["connection.fetch.size"].(int))

	rows, err := db.QueryContext(ctx, selectSQL, opts)
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "db.QueryContext()", err))
		os.Exit(1)
	}

	defer func(rows *sql.Rows) {
		err := rows.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "rows.Close()", err))
			os.Exit(1)
		}
	}(rows)

	i := 0

	for rows.Next() {
		i++
	}

	if i != expect {
		log.Printf(
			"Trial %d, partition %d : failed to get %d rows (got %d)\n",
			trial, partition, expect, i)
		os.Exit(1)
	}
}

func loadBulk(benchmarkNumberPartitions int, fileBulkName string, fileBulkDelimiter string) []bulkPartition {
	log.Println("Start Distribution of the data in the partitions")

	partitions := make([]bulkPartition, benchmarkNumberPartitions)

	bulkFile, err := os.Open(fileBulkName)
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "os.Open()", err))
		os.Exit(1)
	}

	defer func(bulkFile *os.File) {
		err := bulkFile.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "bulkFile.Close()", err))
			os.Exit(1)
		}
	}(bulkFile)

	scanner := bufio.NewScanner(bulkFile)

	for scanner.Scan() {
		parts := strings.Split(scanner.Text(), fileBulkDelimiter)
		partition := (int(parts[0][0])*251 + int(parts[0][1])) % benchmarkNumberPartitions
		partitions[partition].keys = append(partitions[partition].keys, parts[0])
		partitions[partition].vals = append(partitions[partition].vals, parts[1])
	}

	if err := scanner.Err(); err != nil {
		log.Print(errors.Errorf("%v: %w", "scanner.Err()", err))
		os.Exit(1)
	}

	for i, p := range partitions {
		log.Printf("Partition %d has %5d rows\n", i+1, len(p.keys))
	}

	log.Println("End   Distribution of the data in the partitions")

	return partitions
}

func loadConfig(configFile string) map[string]interface{} {
	configurations := make(map[string]interface{})

	confFile, err := os.Open(configFile)
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "os.Open()", err))
		os.Exit(1)
	}

	defer func(confFile *os.File) {
		err := confFile.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "confFile.Close()", err))
			os.Exit(1)
		}
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
		log.Print(errors.Errorf("%v: %w", "scanner.Err()", err))
		os.Exit(1)
	}

	configurations["connection.dsn"] =
		configurations["connection.user"].(string) +
			"/" + configurations["connection.password"].(string) +
			"@" + configurations["connection.host"].(string) +
			":" + fmt.Sprintf("%v", configurations["connection.port"]) +
			"/" + configurations["connection.service"].(string)

	return configurations
}

func initDb(ctx context.Context, configs map[string]interface{}) {
	db, err := sql.Open("godror",
		configs["connection.dsn"].(string))
	if err != nil {
		log.Print(errors.Errorf("%v: %w", configs["connection.dsn"], err))
		os.Exit(1)
	}

	defer func(db *sql.DB) {
		err := db.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "db.Close()", err))
			os.Exit(1)
		}
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
}

func tsStr(t time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d %02d:%02d:%02d.%09d", t.Year(), t.Month(),
		t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond())
}

func resultWriter(configs map[string]interface{}, resultChn []result) {
	fileResultDelimiter, err := strconv.Unquote("\"" +
		configs["file.result.delimiter"].(string) + "\"")
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "strconv.Unquote()", err))
		os.Exit(1)
	}

	rf, err := os.OpenFile(configs["file.result.name"].(string),
		os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "os.OpenFile()", err))
		os.Exit(1)
	}

	defer func(rf *os.File) {
		err := rf.Close()
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "rf.Close()", err))
			os.Exit(1)
		}
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
		_, err := fmt.Fprintf(resultFile, resultFormat, result.trial, result.sql,
			result.action, tsStr(result.start), tsStr(result.end), d.Seconds(),
			d.Nanoseconds())
		if err != nil {
			log.Print(errors.Errorf("%v: %w", "fmt.Fprintf()", err))
			os.Exit(1)
		}
	}

	err = resultFile.Flush()
	if err != nil {
		log.Print(errors.Errorf("%v: %w", "resultFile.Flush()", err))
		os.Exit(1)
	}
}

// Control function for insertions into the database.
func helper_insert() {

}

// Retrieving data from the database.
func helper_select() {

}

// Performing a complete benchmark run that can consist of several trial runs.
func runBenchmark() {
	// save the current time as the start of the 'benchmark' action
	startBenchTs := time.Now()

	// READ the configuration parameters into the memory (config params `file.configuration.name ...`)
	configs := loadConfig(os.Args[1])

	// READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	partitions := loadBulk(
		benchmarkNumberPartitions,
		configs["file.bulk.name"].(string),
		configs["file.bulk.delimiter"].(string))

	// partition key = modulo (ASCII value of 1st byte of key * 256 + ASCII value of 2nd byte of key,
	//               	       number partitions (config param 'benchmark.number.partitions'))

	// Create a separate database connection (without auto commit behaviour) for each partition

	// trial_no = 0

	// WHILE trial_no < config_param 'benchmark.trials'
	//     DO run_trial(database connections, trial_no, bulk_data_partitions)
	// ENDWHILE

	// partition_no = 0

	// WHILE partition_no < config_param 'benchmark.number.partitions'
	//     close the database connection
	// ENDWHILE

	// WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')

}

// Performing a single trial run.
func runTrial() {

}

// Inserting a bulk of data into the database.
func runInsert() {

}

// Control function for retrieving data from the database.
func runSelect() {

}
