import db_oracle

import std/logging
import std/os
import std/strutils
import std/tables
import std/times

# ==============================================================================
# Type declarations
# ------------------------------------------------------------------------------

type
  BulkRecord = seq[string]

  Config = Table[string, string]

  Connections = Table[uint, OracleConnection]

  ParamsRunTrial = object
    benchmarkBatchSize: uint
    benchmarkCoreMultiplier: uint
    benchmarkNumberPartitions: uint
    benchmark_transaction_size: uint
    connections: Connections
    partitions: Partitions
    sql_create: string
    sql_drop: string
    sql_insert: string
    sql_select: string

  Partition = seq[BulkRecord]

  Partitions = Table[uint, Partition]

  StatisticsEntry = object
    action: string
    endTime: DateTime
    sqlStmnt: string
    startTime: DateTime
    trialNo: uint

# ==============================================================================
# Forward declarations
# ------------------------------------------------------------------------------

proc createConnections(logger: Logger, config: Config, octx: var OracleContext,
    benchmarkNumberPartitions: uint): Connections
proc getConfig(logger: Logger, fileNameConfig: string): Table[string, string]
proc loadBulk(logger: Logger, config: Config,
    benchmarkNumberPartitions: uint): Partitions
proc main()
proc runBenchmark(logger: Logger, fileNameConfig: string)

# ==============================================================================
# Program start
# ------------------------------------------------------------------------------

main()

# ==============================================================================
# Commit the transaction.
# -----------------------------------------------------------------------------

proc commit(connection: &Connection) {
    match connection.commit() {
        Ok(_) => {}
        Err(error) => {
            error!("commit() - Problem with connection.commit(): {}", error)
            std::process::exit(1)
        }
    }
}

# ==============================================================================
# Create a separate database connection (without auto commit behaviour)
# for each partition.
# -----------------------------------------------------------------------------

proc createConnections(logger: Logger, config: Config, octx: var OracleContext,
    benchmarkNumberPartitions: uint): Connections =
  logger.log(lvlDebug, "Start createConnections()")

  let connectionString: string = "//" &
    config["connection.host"] &
    ":" &
    config["connection.port"] &
    "/" &
    config["connection.service"]
  # wwe  
  # let connectionString: string = "(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = " &
  #   config["connection.host"] &
  #   ")(PORT = " &
  #   config["connection.port"] &
  #   "))(CONNECT_DATA =(SERVER = DEDICATED)(SERVICE_NAME = " &
  #   config["connection.service"] & " )))"
  let password: string = config["connection.password"]
  let user: string = config["connection.user"]

  var connection: OracleConnection
  var connections: Connections

  for i in 0..benchmarkNumberPartitions - 1:

    # connections[uint(i)] = connection

    logger.log(lvlDebug, "1. of ", i)
    createConnection(octx, connectionString, user, password, connections[uint(i)])
    logger.log(lvlDebug, "2. of ", i)

  logger.log(lvlDebug, "End   createConnections()")

  connections

# ==============================================================================
# Create the result file.
# -----------------------------------------------------------------------------

proc createResultFile(
    config: &HashMap<String, String>,
    statistics: &mut Vec<StatisticsEntry>,
) -> (i64, i64, i64) {
    logger.log(lvlDebug, "Start createStatisticsFile()")

    let fileDelimiter: u8 = *config
        .get("file.result.delimiter")
        
        .clone()
        .asBytes()
        .get(0)
        
    let filePath = Path::new(config["file.result.name"))

    let existing: bool = std::path::Path::new(filePath).isFile()

    let file = match OpenOptions::new()
        .write(true)
        .create(true)
        .append(true)
        .open(filePath)
    {
        Ok(file) => file,
        Err(error) => {
            error!(
                "createResultFile() - Problem opening the result file: {}",
                error
            )
            std::process::exit(1)
        }
    }

    let mut writer: Writer<File> = csv::WriterBuilder::new()
        .delimiter(fileDelimiter)
        .fromWriter(file)

    if !existing {
        let fileHeader = config["file.result.header").split('')

        match writer.writeRecord(fileHeader) {
            Ok(result) => result,
            Err(error) => {
                error!(
                    "createResultFile() - Problem writing the header of the result file: {}",
                    error
                )
                std::process::exit(1)
            }
        }
    }

    let mut resultEntry: Vec<String> = Vec::withCapacity((POS_DURATION_NS + 1) as uint)

    resultEntry.push(config["benchmark.release"])
    resultEntry.push(config["benchmark.id"])
    resultEntry.push(config["benchmark.comment"])
    resultEntry.push(config["benchmark.host.name"])
    resultEntry.push(config["benchmark.number.cores"])
    resultEntry.push(config["benchmark.os"])
    resultEntry.push(config["benchmark.user.name"])
    resultEntry.push(config["benchmark.database"])

    let mut language: string = "Rust ".toString()
    language.pushStr(&version().toString())
    resultEntry.push(language)

    let mut driver: string = "Rust-oracle ".toString()
    driver.pushStr("0.5.3")
    resultEntry.push(driver)

    resultEntry.push("".toString())
    resultEntry.push("".toString())
    resultEntry.push(config["benchmark.core.multiplier"])
    resultEntry.push(config["connection.fetch.size"])
    resultEntry.push(config["benchmark.transaction.size"])
    resultEntry.push(config["file.bulk.length"])
    resultEntry.push(config["file.bulk.size"])
    resultEntry.push(config["benchmark.batch.size"])
    resultEntry.push("".toString())
    resultEntry.push("".toString())
    resultEntry.push("".toString())
    resultEntry.push("".toString())
    resultEntry.push("".toString())

    let mut trialMax: i64 = 0
    let mut trialMin: i64 = 0
    let mut trialTotal: i64 = 0

    for statisticsEntry in statistics.iter() {
        let action = &statisticsEntry.action

        let endTime: DateTime<Local> = if action == "benchmark" {
            Local::now()
        } else {
            statisticsEntry.endTime
        }

        let startTime: DateTime<Local> = statisticsEntry.startTime

        let difference: Duration = endTime - startTime

        resultEntry[POS_TRIAL_NO] = statisticsEntry.trialNo.toString()
        resultEntry[POS_SQL_STMNT] = statisticsEntry.sqlStmnt.clone()
        resultEntry[POS_ACTION] = action.clone()
        resultEntry[POS_START_TIME] = startTime.toString()
        resultEntry[POS_END_TIME] = endTime.toString()

        resultEntry[POS_DURATION_SEC] = difference.numSeconds().toString()
        resultEntry[POS_DURATION_NS] = difference.numNanoseconds().toString()

        match writer.writeRecord(&resultEntry) {
            Ok(result) => result,
            Err(error) => {
                error!(
                    "createResultFile() - Problem writing result file entries: {}",
                    error
                )
                std::process::exit(1)
            }
        }

        if action.eq("trial") {
            let differenceMs = difference.numMilliseconds()

            if trialMax == 0 || trialMax < differenceMs {
                trialMax = differenceMs
            }

            if trialMin == 0 || trialMin > differenceMs {
                trialMin = differenceMs
            }

            trialTotal += differenceMs
        }
    }

    match writer.flush() {
        Ok(result) => result,
        Err(error) => {
            error!(
                "createResultFile(9 - Problem flushing the result file: {}",
                error
            )
            std::process::exit(1)
        }
    }

    logger.log(lvlDebug, "End   createStatisticsFile()")

    (trialMin, trialMax, trialTotal)
}

# ==============================================================================
# Execute batch processing.
# -----------------------------------------------------------------------------

proc executeBatch(batchCollection: &mut Batch) {
    match batchCollection.execute() {
        Ok(_) => {}
        Err(error) => {
            error!(
                "runInsertHelper() - Problem with batch.execute(): {}",
                error
            )
            std::process::exit(1)
        }
    }
}

# ==============================================================================
# Load properties from properties file.
# ------------------------------------------------------------------------------

proc getConfig(logger: Logger, fileNameConfig: string): Table[string, string] =
  logger.log(lvlDebug, "Start getConfig()")

  var config: Config

  for line in lines(fileNameConfig):
    var columns = split(line, '=')
    config[columns[0]] = columns[1]

  logger.log(lvlDebug, "End   getConfig()")

  config

# ==============================================================================
# Load bulk data from csv / tsv file.
# ------------------------------------------------------------------------------

proc loadBulk(logger: Logger, config: Config,
    benchmarkNumberPartitions: uint): Partitions =
  logger.log(lvlDebug, "Start loadBulk()")

  let fileBulkDelimiter: char = char(config["file.bulk.delimiter"][0])
  let fileBulkName: string = config["file.bulk.name"]
  let fileBulkSize: uint = parseuint(config["file.bulk.size"])
  let partitionSize: uint = (fileBulkSize div benchmarkNumberPartitions)+1

  var isFirst: bool = true
  var partitions: Partitions

  for i in 0..benchmarkNumberPartitions - 1:
    partitions[uint(i)] = newSeq[BulkRecord](partitionSize)

  logger.log(lvlInfo, "Start Distribution of the data in the partitions")


  for line in lines(fileBulkName):
    if isFirst:
      isFirst = false
      continue

    let columns = split(line, fileBulkDelimiter)
    let partition: uint = (uint(char(columns[0][0])) * 251 + uint(char(
        columns[0][1]))) mod benchmark_number_partitions

    partitions[partition].add(columns)

  for i in 0..benchmarkNumberPartitions - 1:
    logger.log(lvlInfo, "Partition ", i, " has ", partitions[uint(i)].len(), " rows")

  logger.log(lvlInfo, "End   Distribution of the data in the partitions")

  logger.log(lvlDebug, "End   loadBulk()")

  partitions

# ==============================================================================
# Main procedure
# ------------------------------------------------------------------------------

proc main() =
  var fileNameConfig: string

  var logger = newConsoleLogger(levelThreshold = lvlAll,
  #var logger = newConsoleLogger(levelThreshold = lvlInfo,
    fmtStr = "[$time] $appname.nim - $levelname: ")

  let numberArgs = paramCount()

  logger.log(lvlDebug, "Start main()")

  logger.log(lvlInfo, "main() - number arguments=", numberArgs)

  if numberArgs < 1:
    logger.log(lvlFatal, "main() - not enough command line arguments available")

  fileNameConfig = paramStr(1)

  logger.log(lvlInfo, "main() - 1st argument=", fileNameConfig)

  if numberArgs > 1:
    logger.log(lvlFatal, "main() - more than one command line arguments available")

  runBenchmark(logger, fileNameConfig)

  logger.log(lvlDebug, "End   main()")

# ==============================================================================
# Performing a complete benchmark run that can consist of several trial runs.
# ------------------------------------------------------------------------------

proc runBenchmark(logger: Logger, fileNameConfig: string) =
  logger.log(lvlDebug, "Start runBenchmark()")

  ## READ the configuration parameters into the memory (config params `file.configuration.name ...`)
  var config: Config = getConfig(logger, fileNameConfig)

  ## save the current time as the start of the 'benchmark' action
  let startTime: DateTime = now()

  let benchmarkNumberPartitions: uint = parseuint(config["benchmark.number.partitions"])

  ## READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
  var partitions: Partitions = loadBulk(logger, config, benchmarkNumberPartitions)

  var octx: OracleContext

  newOracleContext(octx, DpiAuthMode.SYSDBA)

  var connections: Connections = createConnections(logger, config, octx, benchmarkNumberPartitions)

  #[
  trial_no = 0
  WHILE trial_no < config_param 'benchmark.trials'
    DO run_trial(database connections,
      trial_no,
      bulk_data_partitions)
    ENDWHILE
    ]#
  let trials: uint = parseuint(config["benchmark.trials"])

  let sql_insert: string = replaceWord(replaceWord(config["sql.insert"], ":key",
      ":1"), ":data", ":2")

  var statistics = newSeq[StatisticsEntry](trials * 3 + 1)

    # let params_run_trial: ParamsRunTrial = ParamsRunTrial {
    #     benchmark_batch_size: config
    #         .get("benchmark.batch.size")
    #         .unwrap()
    #         .parse::<u32>()
    #         .unwrap(),
    #     benchmark_core_multiplier: config
    #         .get("benchmark.core.multiplier")
    #         .unwrap()
    #         .parse::<u32>()
    #         .unwrap(),
    #     benchmarkNumberPartitions,
    #     benchmark_transaction_size: config
    #         .get("benchmark.transaction.size")
    #         .unwrap()
    #         .parse::<u32>()
    #         .unwrap(),
    #     connections: &connections,
    #     partitions: &partitions,
    #     sql_create: config.get("sql.create").unwrap(),
    #     sql_drop: config.get("sql.drop").unwrap(),
    #     sql_insert: &sql_insert,
    #     sql_select: config.get("sql.select").unwrap(),
    # }

    # for trial_no in 1..=trials {
    #     run_trial(params_run_trial, &mut statistics, trial_no)
    # }

    #[
    partition_no = 0
    WHILE partition_no < config_param 'benchmark.number.partitions'
      close the database connection
    ENDWHILE
    ]#
    # for connection in connections.iter() {
    #     match connection.close() {
    #         Ok(_) => {}
    #         Err(error) => {
    #             error!("runBenchmark() - Problem connection.close(): {}", error)
    #             std::process::exit(1)
    #         }
    #     }
    # }

  ## WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
  let endTime: DateTime = now()

  # statistics.push(StatisticsEntry {
  #     action: "benchmark".to_string(),
  #     endTime,
  #     sql_stmnt: "".to_string(),
  #     startTime,
  #     trial_no: 0,
  # })

  # let (trial_min, trial_max, trial_total) = create_result_file(&config, &mut statistics)

  # info!("Duration (ms) trial min.    : {}", trial_min)
  # info!("Duration (ms) trial max.    : {}", trial_max)
  # info!(
  #     "Duration (ms) trial average : {}",
  #     math::round::half_up((trial_total / trials as i64) as f64, 2)
  # )
  # info!(
  #     "Duration (ms) benchmark run : {}",
  #     (endTime - startTime).num_milliseconds()
  # )

  destroyOracleContext(octx)

  logger.log(lvlDebug, "End   runBenchmark()")

# ==============================================================================
# Supervise function for inserting data into the database.
# -----------------------------------------------------------------------------

proc runInsert(
    params: ParamsRunInsert,
    statistics: &mut Vec<StatisticsEntry>,
    trialNo: u32,
) -> Result<(), Error> {
    logger.log(lvlDebug, "Start runInsert()")

    # save the current time as the start of the 'query' action
    let startTime: DateTime<Local> = Local::now()

    /*
    partitionNo = 0
    WHILE partitionNo < configParam 'benchmark.number.partitions'
        IF configParam 'benchmark.core.multiplier' = 0
            DO runInsertHelper(database connections(partitionNo),
                    bulkDataPartitions(partitionNo))
        ELSE
            DO runInsertHelper (database connections(partitionNo),
                    bulkDataPartitions(partitionNo)) as a thread
        ENDIF
    ENDWHILE
    */
    if params.benchmarkCoreMultiplier == 0 {
        for partitionNo in 0..params.benchmarkNumberPartitions {
            runInsertHelper(
                params.benchmarkBatchSize,
                params.benchmarkTransactionSize,
                &params.connections[partitionNo],
                partitionNo,
                &params.partitions[partitionNo],
                params.sqlInsert,
                trialNo,
            )
        }
    } else {
        thread::scope(|s| {
            for partitionNo in 0..params.benchmarkNumberPartitions {
                s.spawn(move |_| {
                    runInsertHelper(
                        params.benchmarkBatchSize,
                        params.benchmarkTransactionSize,
                        &params.connections[partitionNo],
                        partitionNo,
                        &params.partitions[partitionNo],
                        params.sqlInsert,
                        trialNo,
                    )
                })
            }
        })
        
    }

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    statistics.push(StatisticsEntry {
        action: "insert".toString(),
        endTime: Local::now(),
        sqlStmnt: params.sqlInsert.parse(),
        startTime,
        trialNo,
    })

    logger.log(lvlDebug, "End   runInsert()")

    Ok(())
}

# ==============================================================================
# Helper function for inserting data into the database.
# -----------------------------------------------------------------------------

proc runInsertHelper<'a>(
    benchmarkBatchSize: u32,
    benchmarkTransactionSize: u32,
    connection: &'a Connection,
    partitionNo: uint,
    partition: &'a [(String, String)],
    sqlInsert: &'a str,
    trialNo: u32,
) {
    logger.log(lvlDebug, "Start runInsertHelper()")

    /*
    IF trialNo == 1
       INFO Start insert partitionKey=partitionKey
    ENDIF
    */
    if trialNo == 1 {
        info!("Start insert partitionKey={}", partitionNo)
    }

    /*
    count = 0
    collection batchCollection = empty
    WHILE iterating through the collection bulkDataPartition
      count + 1

      add the SQL statement in config param 'sql.insert' with the current bulkData entry to the collection batchCollection

      IF configParam 'benchmark.batch.size' > 0
          IF count modulo config param 'benchmark.batch.size' = 0
              execute the SQL statements in the collection batchCollection
              batchCollection = empty
          ENDIF
      ENDIF

      IF  config param 'benchmark.transaction.size' > 0
      AND count modulo config param 'benchmark.transaction.size' = 0
          commit
      ENDIF
    ENDWHILE
    */

    let mut batchCollection = connection
        .batch(
            sqlInsert,
            if benchmarkBatchSize == 0 {
                partition.len()
            } else {
                benchmarkBatchSize as uint
            },
        )
        .build()
        

    let mut statement = connection.prepare(sqlInsert, &[])

    let mut count = 0
    for record in partition.iter() {
        count += 1

        if benchmarkBatchSize == 1 {
            match statement.execute(&[&record.0, &record.1]) {
                Ok(_) => {}
                Err(error) => {
                    error!(
                        "runInsertHelper() - Problem with statement.execute(): {}",
                        error
                    )
                    std::process::exit(1)
                }
            }
        } else {
            match batchCollection.appendRow(&[&record.0, &record.1]) {
                Ok(_) => {}
                Err(error) => {
                    error!(
                        "runInsertHelper() - Problem with batch.appendRow(): {}",
                        error
                    )
                    std::process::exit(1)
                }
            }

            if benchmarkBatchSize > 1 && (count % benchmarkBatchSize == 0) {
                executeBatch(&mut batchCollection)
            }
        }

        if benchmarkTransactionSize > 0 && (count % benchmarkTransactionSize == 0) {
            commit(connection)
        }
    }

    /*
    IF collection batchCollection is not empty
      execute the SQL statements in the collection batchCollection
    ENDIF
    */
    if benchmarkBatchSize != 1 {
        executeBatch(&mut batchCollection)
    }

    # commit
    commit(connection)

    /*
    IF trialNo == 1
       INFO End   insert partitionKey=partitionKey
    ENDIF
    */
    if trialNo == 1 {
        info!("End   insert partitionKey={}", partitionNo)
    }

    logger.log(lvlDebug, "End   runInsertHelper()")
}

# ==============================================================================
# Supervise function for retrieving of the database data.
# -----------------------------------------------------------------------------

proc runSelect<'a>(
    benchmarkCoreMultiplier: u32,
    benchmarkNumberPartitions: uint,
    connections: &'a [Connection],
    partitions: &'a [Vec<(String, String)>],
    sqlSelect: &'a str,
    statistics: &'a mut Vec<StatisticsEntry>,
    trialNo: u32,
) -> Result<(), Error> {
    logger.log(lvlDebug, "Start runSelect()")

    # save the current time as the start of the 'query' action
    let startTime: DateTime<Local> = Local::now()

    /*
    partitionNo = 0
    WHILE partitionNo < configParam 'benchmark.number.partitions'
        IF configParam 'benchmark.core.multiplier' = 0
            DO runSelectHelper(database connections(partitionNo),
                                 bulkDataPartitions(partitionNo,
                                 partitionNo)
        ELSE
            DO runSelectHelper(database connections(partitionNo),
                                 bulkDataPartitions(partitionNo,
                                 partitionNo) as a thread
        ENDIF
    ENDWHILE
    */
    if benchmarkCoreMultiplier == 0 {
        for partitionNo in 0..benchmarkNumberPartitions {
            runSelectHelper(
                &connections[partitionNo],
                partitionNo,
                &partitions[partitionNo],
                sqlSelect,
                trialNo,
            )
        }
    } else {
        thread::scope(|s| {
            for partitionNo in 0..benchmarkNumberPartitions {
                s.spawn(move |_| {
                    runSelectHelper(
                        &connections[partitionNo],
                        partitionNo,
                        &partitions[partitionNo],
                        sqlSelect,
                        trialNo,
                    )
                })
            }
        })
        
    }

    # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
    statistics.push(StatisticsEntry {
        action: "select".toString(),
        endTime: Local::now(),
        sqlStmnt: sqlSelect.parse(),
        startTime,
        trialNo,
    })

    logger.log(lvlDebug, "End   runSelect()")

    Ok(())
}

# ==============================================================================
# Helper function for retrieving data from the database.
# -----------------------------------------------------------------------------

proc runSelectHelper<'a>(
    connection: &'a Connection,
    partitionNo: uint,
    partition: &'a [(String, String)],
    sqlSelect: &'a str,
    trialNo: u32,
) {
    logger.log(lvlDebug, "Start runSelectHelper()")

    /*
    IF trialNo == 1
       INFO Start select partitionKey=partitionKey
    ENDIF
    */
    if trialNo == 1 {
        info!("Start select partitionKey={}", partitionNo)
    }

    # execute the SQL statement in config param 'sql.select
    let mut sqlSelectComplete: string = sqlSelect.toString()
    sqlSelectComplete.pushStr(" where partitionKey = ")
    sqlSelectComplete.pushStr(&partitionNo.toString())
    let rows = match connection.query(&sqlSelectComplete, &[]) {
        Ok(rows) => rows,
        Err(error) => {
            error!(
                "createResultFile() - Problem with select '{}': {}",
                sqlSelectComplete, error
            )
            std::process::exit(1)
        }
    }

    /*
    int count = 0
    WHILE iterating through the result set
        count + 1
    ENDWHILE
    */
    let mut count: uint = 0
    for Row in rows {
        count += 1
    }

    /*
    IF NOT count = size(bulkDataPartition)
        display an error message
    ENDIF
    */

    if count != partition.len() {
        error!(
            "Number rows: expected={} - found={}",
            partition.len(),
            count
        )
        std::process::exit(1)
    }

    /*
    IF trialNo == 1
       INFO End   select partitionKey=partitionKey
    ENDIF
    */
    if trialNo == 1 {
        info!("End   select partitionKey={}", partitionNo)
    }

    logger.log(lvlDebug, "End   runSelectHelper()")
}

# ==============================================================================
# Performing a single trial run.
# -----------------------------------------------------------------------------

proc runTrial(params: ParamsRunTrial, statistics: &mut Vec<StatisticsEntry>, trialNo: u32) {
    logger.log(lvlDebug, "Start runTrial()")

    # save the current time as the start of the 'trial' action
    let startTime: DateTime<Local> = Local::now()

    # INFO  Start trial no. trialNo
    info!("Start trial no. {}", trialNo)

    /*
    create the database table (config param 'sql.create')
    IF error
        drop the database table (config param 'sql.drop')
        create the database table (config param 'sql.create')
    ENDIF
    */
    let mut resultCreateDrop = params.connections[0].execute(params.sqlCreate, &[])
    if resultCreateDrop.isOk() {
        logger.log(lvlDebug, "last DDL statement={}", params.sqlCreate)
    } else {
        resultCreateDrop = params.connections[0].execute(params.sqlDrop, &[])
        if resultCreateDrop.isErr() {
            error!(
                "runTrial() - Problem dropping the database table: {}",
                resultCreateDrop.err()
            )
            std::process::exit(1)
        }

        resultCreateDrop = params.connections[0].execute(params.sqlCreate, &[])
        if resultCreateDrop.isErr() {
            error!(
                "runTrial() - Problem creating the database table: {}",
                resultCreateDrop.err()
            )
            std::process::exit(1)
        }

        logger.log(lvlDebug, "last DDL statement after DROP={}", params.sqlCreate)
    }

    /*
    DO runInsert(database connections,
                  trialNo,
                  bulkDataPartitions)
    */
    let paramsRunInsert = ParamsRunInsert {
        benchmarkBatchSize: params.benchmarkBatchSize,
        benchmarkCoreMultiplier: params.benchmarkCoreMultiplier,
        benchmarkNumberPartitions: params.benchmarkNumberPartitions,
        benchmarkTransactionSize: params.benchmarkTransactionSize,
        connections: params.connections,
        partitions: params.partitions,
        sqlInsert: params.sqlInsert,
    }

    let resultRunInsert = runInsert(paramsRunInsert, statistics, trialNo)
    if resultRunInsert.isErr() {
        error!(
            "runTrial() - Problem in runInsert: {}",
            resultRunInsert.err()
        )
        std::process::exit(1)
    }

    /*
    DO runSelect(database connections,
                  trialNo,
                  bulkDataPartitions)
    */
    let resultRunSelect = runSelect(
        params.benchmarkCoreMultiplier,
        params.benchmarkNumberPartitions,
        params.connections,
        params.partitions,
        params.sqlSelect,
        statistics,
        trialNo,
    )
    if resultRunSelect.isErr() {
        error!(
            "runTrial() - Problem in runSelect: {}",
            resultRunSelect.err()
        )
        std::process::exit(1)
    }

    # drop the database table (config param 'sql.drop')
    resultCreateDrop = params.connections[0].execute(params.sqlDrop, &[])
    if resultCreateDrop.isErr() {
        error!(
            "runTrial() - Problem dropping the database table: {}",
            resultCreateDrop.err()
        )
        std::process::exit(1)
    }
    logger.log(lvlDebug, "last DDL statement={}", params.sqlCreate)

    # WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
    let endTime: DateTime<Local> = Local::now()

    statistics.push(StatisticsEntry {
        action: "trial".toString(),
        endTime,
        sqlStmnt: "".toString(),
        startTime,
        trialNo,
    })

    info!(
        "Duration (ms) trial         : {}",
        (endTime - startTime).numMilliseconds()
    )

    logger.log(lvlDebug, "End   runTrial()")
}
