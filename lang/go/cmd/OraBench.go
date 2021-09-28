package main

import (
	"bufio"
	"context"
	"database/sql"
	"fmt"
	"math"
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
	//log.SetLevel(log.DebugLevel)

	log.Info("Start OraBench.go")

	numberArgs := len(os.Args)

	log.Info(fmt.Sprintf("main() - number arguments=%2d", numberArgs))

	if numberArgs == 0 {
		log.Fatal("main() - no command line argument available")
	}

	log.Info(fmt.Sprintf("main() - 1st argument=%v", os.Args[0]))

	if numberArgs == 1 {
		log.Fatal("main() - command line argument missing")
	}

	log.Info(fmt.Sprintf("main() - 2nd argument=%v", os.Args[1]))

	if numberArgs > 2 {
		log.Info(fmt.Sprintf("main() - 3rd argument=%v", os.Args[2]))
		log.Fatal("main() - more than one command line argument available")
	}

	runBenchmark()

	log.Info("End   OraBench.go")
	os.Exit(0)
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
			log.Info(errors.Errorf("%s -> %w", configs["sql.drop"].(string), err))
			os.Exit(1)
		}

		_, err = db.ExecContext(ctx, configs["sql.create"].(string))
		if err != nil {
			log.Info(errors.Errorf("%s -> %w", configs["sql.drop"].(string), err))
			os.Exit(1)
		}
	}

	log.Debug("End   initDb()")
}

func loadBulk(benchmarkNumberPartitions int, fileBulkDelimiter string, fileBulkName string) []bulkPartition {
	log.Debug("Start loadBulk()")

	log.Info("Start Distribution of the data in the partitions")

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
		log.Printf("Partition %d has %5d rows", i+1, len(p.keys))
	}

	log.Info("End   Distribution of the data in the partitions")

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
		log.Debug("Start loadConfig() - defer()")

		err := confFile.Close()
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "confFile.Close()", err))
		}

		log.Debug("End   loadConfig() - defer()")
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
			"%d"}, fileResultDelimiter)

		d := result.end.Sub(result.start)
		_, err := fmt.Fprintf(resultFile, resultFormat, result.trial, result.sql,
			result.action, tsStr(result.start), tsStr(result.end), d.Seconds(),
			d.Nanoseconds())
		if err != nil {
			log.Fatal(errors.Errorf("%v: %w", "resultWriter()", err))
		}
	}

	err = resultFile.Flush()
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", "resultWriter()", err))
	}

	log.Debug("End   resultWriter()")
}

/*
Performing a complete benchmark run that can consist of several trial runs.
*/
func runBenchmark() {
	log.Debug("Start runBenchmark()")

	// READ the configuration parameters into the memory (config params `file.configuration.name ...`)
	configs := loadConfig(os.Args[1])

	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	trials := configs["benchmark.trials"].(int)

	// save the current time as the start of the 'benchmark' action
	startBenchTs := time.Now()

	resultSlice := make([]result, trials*3+1)
	resultPos := 0

	// READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
	partitions := loadBulk(
		benchmarkNumberPartitions,
		configs["file.bulk.delimiter"].(string),
		configs["file.bulk.name"].(string))

	// create a separate database connection (without auto commit behaviour) for each partition
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	/*
	   trial_no = 0
	   WHILE trial_no < config_param 'benchmark.trials'
	       DO run_trial(database connections,
	                    trial_no,
	                    bulk_data_partitions)
	   ENDWHILE
	*/
	var duration int64
	var trial_max int64 = 0
	var trial_min int64 = 0
	var trial_sum int64 = 0

	for t := 1; t <= trials; t++ {
		duration = runTrial(ctx, configs, t, partitions, resultSlice, resultPos)
	}

	if trial_max == 0 {
		trial_max = duration
	} else if trial_max < duration {
		trial_max = duration
	}

	if trial_min == 0 {
		trial_min = duration
	} else if trial_min > duration {
		trial_min = duration
	}

	trial_sum += duration

	/*
	   partition_no = 0
	   WHILE partition_no < config_param 'benchmark.number.partitions'
	       close the database connection
	   ENDWHILE
	*/
	// n/a

	// WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
	endBenchTs := time.Now()
	resultSlice[resultPos] = result{trial: 0,
		sql:    "",
		action: "benchmark",
		start:  startBenchTs,
		end:    endBenchTs}
	resultPos++

	resultWriter(configs, resultSlice)

	log.Info("Duration (ms) trial min.    : ", math.Round(float64(trial_min/1000000)))
	log.Info("Duration (ms) trial max.    : ", math.Round(float64(trial_max/1000000)))
	log.Info("Duration (ms) trial average : ", math.Round(float64(trial_sum/1000000/int64(trials))))
	log.Info("Duration (ms) benchmark run : ", math.Round(float64(endBenchTs.Sub(startBenchTs).Nanoseconds()/1000000)))

	log.Debug("End   runBenchmark()")
}

/*
Supervise function for inserting data into the database.
*/
func runInsert(ctx context.Context, configs map[string]interface{}, trialNo int, partitions []bulkPartition, resultSlice []result, resultPos int) {
	log.Debug("Start runInsert()")

	// save the current time as the start of the 'query' action
	start := time.Now()

	/*
	   partition_no = 0
	   WHILE partition_no < config_param 'benchmark.number.partitions'
	       IF config_param 'benchmark.core.multiplier' = 0
	           DO run_insert_helper(database connections(partition_no),
	                   bulk_data_partitions(partition_no))
	       ELSE
	           DO run_insert_helper (database connections(partition_no),
	                   bulk_data_partitions(partition_no)) as a thread
	       ENDIF
	   ENDWHILE
	*/
	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	var wg sync.WaitGroup
	wg.Add(benchmarkNumberPartitions)
	for p := 0; p < benchmarkNumberPartitions; p++ {
		if configs["benchmark.core.multiplier"].(int) == 0 {
			runInsertHelper(ctx, configs, trialNo, p, partitions[p], &wg)
		} else {
			go runInsertHelper(ctx, configs, trialNo, p, partitions[p], &wg)
		}
	}

	// WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
	end := time.Now()
	resultSlice[resultPos] = result{trial: trialNo,
		sql:    configs["sql.insert"].(string),
		action: "query",
		start:  start,
		end:    end}
	resultPos++

	log.Debug("End   runInsert()")
}

/*
Helper function for inserting data into the database.
*/
func runInsertHelper(ctx context.Context, configs map[string]interface{}, trial int, partition int, rows bulkPartition, wg *sync.WaitGroup) {
	log.Debug("Start runInsertHelper()")

	defer wg.Done()

	/*
	   count = 0
	   collection batch_collection = empty
	   WHILE iterating through the collection bulk_data_partition
	     count + 1

	     add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection

	     IF config_param 'benchmark.batch.size' > 0
	         IF count modulo config param 'benchmark.batch.size' = 0
	             execute the SQL statements in the collection batch_collection
	             batch_collection = empty
	         ENDIF
	     ENDIF

	     IF  config param 'benchmark.transaction.size' > 0
	     AND count modulo config param 'benchmark.transaction.size' = 0
	         commit
	     ENDIF
	   ENDWHILE
	*/
	log.Debug(fmt.Sprintf("      doInsert(%2d) - connection.dsn=%v", partition, configs["connection.dsn"]))

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("      doInsert(%2d) - %v: %w", configs["connection.dsn"], partition, err))
	}

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

	/*
	   IF collection batch_collection is not empty
	     execute the SQL statements in the collection batch_collection
	   ENDIF
	*/

	// commit
	defer func(db *sql.DB) {
		log.Debug(fmt.Sprintf("Start doInsert(%2d) - defer(db)", partition))

		deferErr := db.Close()
		if err == nil {
			err = deferErr
		}
		if err != nil {
			log.Fatal(errors.Errorf("      doInsert(%2d) - %v: %w", "db.Close()", partition, err))
		}

		log.Debug(fmt.Sprintf("End   doInsert(%2d) - defer(db)", partition))
	}(db)

	log.Debug("End   runInsertHelper()")
}

/*
Supervise function for retrieving of the database data.
*/
func runSelect(ctx context.Context, configs map[string]interface{}, trialNo int, partitions []bulkPartition, resultSlice []result, resultPos int) {
	log.Debug("Start runSelect()")

	// save the current time as the start of the 'query' action
	start := time.Now()

	/*
	   partition_no = 0
	   WHILE partition_no < config_param 'benchmark.number.partitions'
	       IF config_param 'benchmark.core.multiplier' = 0
	           DO run_select_helper(database connections(partition_no),
	                                bulk_data_partitions(partition_no,
	                                partition_no)
	       ELSE
	           DO run_select_helper(database connections(partition_no),
	                                bulk_data_partitions(partition_no,
	                                partition_no) as a thread
	       ENDIF
	   ENDWHILE
	*/
	benchmarkNumberPartitions := configs["benchmark.number.partitions"].(int)
	var wg sync.WaitGroup
	wg.Add(benchmarkNumberPartitions)
	for p := 0; p < benchmarkNumberPartitions; p++ {
		if configs["benchmark.core.multiplier"].(int) == 0 {
			runSelectHelper(ctx, configs, trialNo, p, len(partitions[p].keys), &wg)
		} else {
			go runSelectHelper(ctx, configs, trialNo, p, len(partitions[p].keys), &wg)
		}
	}

	// WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
	end := time.Now()
	resultSlice[resultPos] = result{trial: trialNo,
		sql:    configs["sql.insert"].(string),
		action: "query",
		start:  start,
		end:    end}
	resultPos++

	log.Debug("End   runSelect()")
}

/*
Helper function for retrieving data from the database.
*/
func runSelectHelper(ctx context.Context, configs map[string]interface{}, trial int, partition int, expect int, wg *sync.WaitGroup) {
	log.Debug("Start runSelectHelper()")

	defer wg.Done()

	// execute the SQL statement in config param 'sql.select'
	log.Debug(fmt.Sprintf("      doSelect(%2d) - connection.dsn=%v", partition, configs["connection.dsn"]))

	db, err := sql.Open("godror", configs["connection.dsn"].(string))
	if err != nil {
		log.Fatal(errors.Errorf("%v: %w", configs["connection.dsn"], err))
	}

	selectSQL := configs["sql.select"].(string) + " WHERE partition_key = " +
		strconv.Itoa(partition)
	opts := godror.FetchRowCount(configs["connection.fetch.size"].(int))

	rows, err := db.QueryContext(ctx, selectSQL, opts)
	if err != nil {
		log.Fatal(errors.Errorf("      doSelect(%2d) - %v: %w", "db.Close()", partition, err))
	}

	/*
	   int count = 0;
	   WHILE iterating through the result set
	       count + 1
	   ENDWHILE
	*/
	i := 0
	for rows.Next() {
		i++
	}

	/*
	   IF NOT count = size(bulk_data_partition)
	       display an error message
	   ENDIF
	*/
	if i != expect {
		log.Fatal(
			errors.Errorf(
				"      doSelect(%2d) - Trial %d, Partition %d : failed to get %d rows (got %d)",
				trial, partition, expect, i))
	}

	log.Debug("End   runSelectHelper()")
}

/*
Performing a single trial run.
*/
func runTrial(ctx context.Context, configs map[string]interface{}, trialNo int, partitions []bulkPartition, resultSlice []result, resultPos int) int64 {
	log.Debug("Start runTrial()")

	// save the current time as the start of the 'trial' action
	startTrialTs := time.Now()

	log.Info("Start trial no.", trialNo)

	/*
	   create the database table (config param 'sql.create')
	   IF error
	       drop the database table (config param 'sql.drop')
	       create the database table (config param 'sql.create')
	   ENDIF
	*/
	initDb(ctx, configs)

	/*
	   DO run_insert(database connections,
	                 trial_no,
	                 bulk_data_partitions)
	*/
	runInsert(ctx, configs, trialNo, partitions, resultSlice, resultPos)

	/*
	   DO run_select(database connections,
	                 trial_no,
	                 bulk_data_partitions)
	*/
	runSelect(ctx, configs, trialNo, partitions, resultSlice, resultPos)

	// drop the database table (config param 'sql.drop')
	// n/a

	// WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
	endTrialTs := time.Now()
	resultSlice[resultPos] = result{trial: trialNo,
		sql:    "",
		action: "trial",
		start:  startTrialTs,
		end:    endTrialTs}
	resultPos++

	var duration = endTrialTs.Sub(startTrialTs).Nanoseconds()

	log.Info("Duration (ms) trial         : ", math.Round(float64(duration/1000000)))

	log.Debug("End   runTrial()")

	return duration
}

func tsStr(t time.Time) string {
	return fmt.Sprintf("%04d-%02d-%02d %02d:%02d:%02d.%09d", t.Year(), t.Month(),
		t.Day(), t.Hour(), t.Minute(), t.Second(), t.Nanosecond())
}
