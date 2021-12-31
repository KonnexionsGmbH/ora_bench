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
  BulkRecordType = seq[string]

type
  ConfigType = Table[string, string]

type
  ConnectionsType = seq[db_oracle.OracleConnection]

type
  PartitionType = seq[BulkRecordType]

type
  PartitionsType = Table[uint, PartitionType]

type
  ParamsRunInsertType = object
    benchmarkBatchSize: uint
    benchmarkCoreMultiplier: uint
    benchmarkNumberPartitions: uint
    benchmarkTransactionSize: uint
    partitions: PartitionsType
    sqlInsertStr: string

type
  ParamsRunSelectType = object
    benchmarkCoreMultiplier: uint
    benchmarkNumberPartitions: uint
    partitions: PartitionsType
    sqlSelectStr: string

type
  ParamsRunTrialType = object
    benchmarkBatchSize: uint
    benchmarkCoreMultiplier: uint
    benchmarkNumberPartitions: uint
    benchmarkTransactionSize: uint
    partitions: PartitionsType
    sqlCreateStr: string
    sqlDropStr: string
    sqlInsertStr: string
    sqlSelectStr: string

type
  StatisticsEntryType = object
    action: string
    endTime: DateTime
    sqlStmnt: string
    startTime: DateTime
    trialNo: uint

type
  StatisticsType = seq[StatisticsEntryType]

# ==============================================================================
# Forward declarations
# ------------------------------------------------------------------------------

proc commit(connection: db_oracle.OracleConnection)
proc createConnections(logger: Logger, config: ConfigType,
    octx: var db_oracle.OracleContext, benchmarkNumberPartitions: uint): ConnectionsType
proc getConfig(logger: Logger, fileNameConfig: string): Table[string, string]
proc loadBulk(logger: Logger, config: ConfigType,
    benchmarkNumberPartitions: uint): PartitionsType
proc main()
proc runBenchmark(logger: Logger, fileNameConfig: string)
proc runInsert(logger: Logger, connections: var ConnectionsType,
    paramsRunInsert: ParamsRunInsertType,

statistics: StatisticsType, trialNo: uint)
proc runInsertHelper(logger: Logger, benchmarkBatchSize: uint,
    benchmarkTransactionSize: uint, connection: db_oracle.OracleConnection,
    partitionNo: uint, partition: PartitionType, sqlInsert: string, trialNo: uint)
proc runSelect(logger: Logger, connections: var ConnectionsType,
    paramsRunSelect: ParamsRunSelectType,

statistics: StatisticsType, trialNo: uint)
proc runSelectHelper(logger: Logger, connection: db_oracle.OracleConnection,
    partitionNo: uint, partition: PartitionType, sqlSelect: string, trialNo: uint)
proc runTrial(logger: Logger, connections: var ConnectionsType,
    paramsRunTrial: ParamsRunTrialType,

statistics: StatisticsType, trialNo: uint)

# ==============================================================================
# Program start
# ------------------------------------------------------------------------------

main()

# ==============================================================================
# Commit the transaction.
# -----------------------------------------------------------------------------

proc commit(connection: db_oracle.OracleConnection) =
  connection.commit()

# ==============================================================================
# Create a separate database connection (without auto commit behaviour)
# for each partition.
# -----------------------------------------------------------------------------

proc createConnections(logger: Logger, config: ConfigType,
    octx: var db_oracle.OracleContext, benchmarkNumberPartitions: uint): ConnectionsType =
  logger.log(lvlDebug, "Start createConnections()")

  let connectionStr: string = "//" &
    config["connection.host"] &
    ":" &
    config["connection.port"] &
    "/" &
    config["connection.service"]
  let password: string = config["connection.password"]
  let user: string = config["connection.user"]

  var connection: db_oracle.OracleConnection
  var connections: ConnectionsType

  for i in 0..benchmarkNumberPartitions - 1:
    try:
      db_oracle.createConnection(octx, connectionStr, user, password, connection)
    except:
      logger.log(lvlFatal, "Problem creating database connection #", i, ": ",
          getCurrentExceptionMsg())

    connections.add(connection)

  logger.log(lvlDebug, "End   createConnections()")

  connections

# ==============================================================================
# Create the result file.
# -----------------------------------------------------------------------------

proc createResultFile(logger: Logger, config: ConfigType,
    statistics: StatisticsType): (int64, int64, int64) =
  logger.log(lvlDebug, "Start createStatisticsFile()")

#     let fileDelimiter: u8 = *config
#         ["file.result.delimiter")

#         .clone()
#         .asBytes()
#         [0)

#     let filePath = Path::new(config["file.result.name"))

#     let existing: bool = std::path::Path::new(filePath).isFile()

#     let file = match OpenOptions::new()
#         .write(true)
#         .create(true)
#         .append(true)
#         .open(filePath)
#     {
#         Ok(file) => file,
#         Err(error) => {
#             error!(
#                 "createResultFile() - Problem opening the result file: {}",
#                 error
#             )
#             std::process::exit(1)
#         }
#     }

#     var writer: Writer<File> = csv::WriterBuilder::new()
#         .delimiter(fileDelimiter)
#         .fromWriter(file)

#     if !existing {
#         let fileHeader = config["file.result.header").split('')

#         match writer.writeRecord(fileHeader) {
#             Ok(result) => result,
#             Err(error) => {
#                 error!(
#                     "createResultFile() - Problem writing the header of the result file: {}",
#                     error
#                 )
#                 std::process::exit(1)
#             }
#         }
#     }

#     var resultEntry: Vec<String> = Vec::withCapacity((POS_DURATION_NS + 1) as uint)

#     resultEntry.push(config["benchmark.release"])
#     resultEntry.push(config["benchmark.id"])
#     resultEntry.push(config["benchmark.comment"])
#     resultEntry.push(config["benchmark.host.name"])
#     resultEntry.push(config["benchmark.number.cores"])
#     resultEntry.push(config["benchmark.os"])
#     resultEntry.push(config["benchmark.user.name"])
#     resultEntry.push(config["benchmark.database"])

#     var language: string = "Rust ".toString()
#     language.pushStr(&version().toString())
#     resultEntry.push(language)

#     var driver: string = "Rust-oracle ".toString()
#     driver.pushStr("0.5.3")
#     resultEntry.push(driver)

#     resultEntry.push("".toString())
#     resultEntry.push("".toString())
#     resultEntry.push(config["benchmark.core.multiplier"])
#     resultEntry.push(config["connection.fetch.size"])
#     resultEntry.push(config["benchmark.transaction.size"])
#     resultEntry.push(config["file.bulk.length"])
#     resultEntry.push(config["file.bulk.size"])
#     resultEntry.push(config["benchmark.batch.size"])
#     resultEntry.push("".toString())
#     resultEntry.push("".toString())
#     resultEntry.push("".toString())
#     resultEntry.push("".toString())
#     resultEntry.push("".toString())

  var trialMax: int64 = 0
  var trialMin: int64 = 0
  var trialTotal: int64 = 0

#     for statisticsEntry in statistics.iter() {
#         let action = &statisticsEntry.action

#         let endTime: DateTime<Local> = if action == "benchmark" {
#             Local::now()
#         } else {
#             statisticsEntry.endTime
#         }

  let startTime: DateTime = now()

#         let difference: Duration = endTime - startTime

#         resultEntry[POS_TRIAL_NO] = statisticsEntry.trialNo.toString()
#         resultEntry[POS_SQL_STMNT] = statisticsEntry.sqlStmnt.clone()
#         resultEntry[POS_ACTION] = action.clone()
#         resultEntry[POS_START_TIME] = startTime.toString()
#         resultEntry[POS_END_TIME] = endTime.toString()

#         resultEntry[POS_DURATION_SEC] = difference.numSeconds().toString()
#         resultEntry[POS_DURATION_NS] = difference.numNanoseconds().toString()

#         match writer.writeRecord(&resultEntry) {
#             Ok(result) => result,
#             Err(error) => {
#                 error!(
#                     "createResultFile() - Problem writing result file entries: {}",
#                     error
#                 )
#                 std::process::exit(1)
#             }
#         }

#         if action.eq("trial") {
#             let differenceMs = difference.numMilliseconds()

#             if trialMax == 0 || trialMax < differenceMs {
#                 trialMax = differenceMs
#             }

#             if trialMin == 0 || trialMin > differenceMs {
#                 trialMin = differenceMs
#             }

#             trialTotal += differenceMs
#         }
#     }

#     match writer.flush() {
#         Ok(result) => result,
#         Err(error) => {
#             error!(
#                 "createResultFile(9 - Problem flushing the result file: {}",
#                 error
#             )
#             std::process::exit(1)
#         }
#     }

  logger.log(lvlDebug, "End   createStatisticsFile()")

  (trialMin, trialMax, trialTotal)

# ==============================================================================
# Execute batch processing.
# -----------------------------------------------------------------------------

# proc executeBatch(batchCollection: &mut Batch) {
#     match batchCollection.execute() {
#         Ok(_) => {}
#         Err(error) => {
#             error!(
#                 "runInsertHelper() - Problem with batch.execute(): {}",
#                 error
#             )
#             std::process::exit(1)

# ==============================================================================
# Load properties from properties file.
# ------------------------------------------------------------------------------

proc getConfig(logger: Logger, fileNameConfig: string): Table[string, string] =
  logger.log(lvlDebug, "Start getConfig()")

  var config: ConfigType

  for line in lines(fileNameConfig):
    var columns = split(line, '=', 1)
    config[columns[0]] = columns[1]

  logger.log(lvlDebug, "End   getConfig()")

  config

# ==============================================================================
# Load bulk data from csv / tsv file.
# ------------------------------------------------------------------------------

proc loadBulk(logger: Logger, config: ConfigType,
    benchmarkNumberPartitions: uint): PartitionsType =
  logger.log(lvlDebug, "Start loadBulk()")

  let fileBulkDelimiter: char = char(config["file.bulk.delimiter"][0])
  let fileBulkName: string = config["file.bulk.name"]
  let fileBulkSize: uint = parseuint(config["file.bulk.size"])
  let partitionSize: uint = (fileBulkSize div benchmarkNumberPartitions)+1

  var isFirst: bool = true
  var partitions: PartitionsType

  for i in 0..benchmarkNumberPartitions - 1:
    partitions[uint(i)] = newSeq[BulkRecordType](partitionSize)

  stdout.writeline "Start Distribution of the data in the partitions"

  for line in lines(fileBulkName):
    if isFirst:
      isFirst = false
      continue

    let columns = split(line, fileBulkDelimiter)
    let partition: uint = (uint(char(columns[0][0])) * 251 + uint(char(
        columns[0][1]))) mod benchmark_number_partitions

    partitions[partition].add(columns)

  for i in 0..benchmarkNumberPartitions - 1:
    stdout.writeline "PartitionType ", i, " has ", partitions[uint(i)].len(), " rows"

  stdout.writeline "End   Distribution of the data in the partitions"

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

  stdout.writeline "main() - number arguments=", numberArgs

  if numberArgs < 1:
    logger.log(lvlFatal, "main() - not enough command line arguments available")

  fileNameConfig = paramStr(1)

  stdout.writeline "main() - 1st argument=", fileNameConfig

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
  var config: ConfigType = getConfig(logger, fileNameConfig)

  ## save the current time as the start of the 'benchmark' action
  let startTime: DateTime = now()

  let benchmarkNumberPartitions: uint = parseuint(config["benchmark.number.partitions"])

  ## READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
  var partitions: PartitionsType = loadBulk(logger, config, benchmarkNumberPartitions)

  var octx: db_oracle.OracleContext

  db_oracle.newOracleContext(octx, DpiAuthMode.DEFAULTAUTHMODE)

  var connections: ConnectionsType = createConnections(logger, config, octx, benchmarkNumberPartitions)

  #[
  trialNo = 0
  WHILE trialNo < config_param 'benchmark.trials'
    DO runTrial(database connections,
      trialNo,
      bulk_data_partitions)
    ENDWHILE
  ]#
  let sqlInsertStr: string = replaceWord(replaceWord(("\"" & config[
      "sql.insert"]) & "\"", ":key", ":1"), ":data", ":2")
  let trials: uint = parseuint(config["benchmark.trials"])

  var paramsRunTrial = ParamsRunTrialType(
        benchmarkBatchSize: parseuint(config["benchmark.batch.size"]),
        benchmarkCoreMultiplier: parseuint(config["benchmark.core.multiplier"]),
        benchmarkNumberPartitions: benchmarkNumberPartitions,
        benchmarkTransactionSize: parseuint(config[
            "benchmark.transaction.size"]),
        partitions: partitions,
        sqlCreateStr: ("\"" & config["sql.create"]) & "\"",
        sqlDropStr: ("\"" & config["sql.drop"]) & "\"",
        sqlInsertStr: sqlInsertStr,
        sqlSelectStr: ("\"" & config["sql.select"]) & "\"")
  var statistics = newSeq[StatisticsEntryType](trials * 3 + 1)

  for trialNo in 1..trials:
    runTrial(logger, connections, paramsRunTrial, statistics, uint(trialNo))

  #[
  partition_no = 0
  WHILE partition_no < config_param 'benchmark.number.partitions'
    close the database connection
  ENDWHILE
  ]#
  for i in 0..benchmarkNumberPartitions - 1:
    try:
      connections[i].releaseConnection
    except:
      logger.log(lvlFatal, "Problem releasing database connection #", i, ": ",
          getCurrentExceptionMsg())

  try:
    db_oracle.destroyOracleContext(octx)
  except:
    logger.log(lvlFatal, "Problem destroying Oracle context: ",
        getCurrentExceptionMsg())

  ## WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
  let endTime: DateTime = now()

  # statistics.push(StatisticsEntryType {
  #     action: "benchmark".to_string(),
  #     endTime,
  #     sqlStmnt: "".to_string(),
  #     startTime,
  #     trialNo: 0,
  # })

  # let (trialMin, trialMax, trialTotal) = createResultFile(&config, &mut statistics)

  # stdout.writeline "Duration (ms) trial min.    : ", trialMin
  # stdout.writeline "Duration (ms) trial max.    : ", trialMax
  # stdout.writeline "Duration (ms) trial average : ", math::round::half_up((trialTotal / trials as int64) as f64, 2)
  stdout.writeline "Duration (ms) benchmark run : ", (endTime -
      startTime).inMilliseconds()

  destroyOracleContext(octx)

  logger.log(lvlDebug, "End   runBenchmark()")

# ==============================================================================
# Supervise function for inserting data into the database.
# -----------------------------------------------------------------------------

proc runInsert(logger: Logger, connections: var ConnectionsType,
    paramsRunInsert: ParamsRunInsertType,

statistics: StatisticsType, trialNo: uint) =
  logger.log(lvlDebug, "Start runInsert()")

  # save the current time as the start of the 'query' action
  let startTime: DateTime = now()

#     /*
#     partitionNo = 0
#     WHILE partitionNo < configParam 'benchmark.number.partitions'
#         IF configParam 'benchmark.core.multiplier' = 0
#             DO runInsertHelper(database connections(partitionNo),
#                     bulkDataPartitions(partitionNo))
#         ELSE
#             DO runInsertHelper (database connections(partitionNo),
#                     bulkDataPartitions(partitionNo)) as a thread
#         ENDIF
#     ENDWHILE
#     */
#     if params.benchmarkCoreMultiplier == 0 {
#         for partitionNo in 0..params.benchmarkNumberPartitions {
#             runInsertHelper(
#                 params.benchmarkBatchSize,
#                 params.benchmarkTransactionSize,
#                 &params.connections[partitionNo],
#                 partitionNo,
#                 &params.partitions[partitionNo],
#                 params.sqlInsert,
#                 trialNo,
#             )
#         }
#     } else {
#         thread::scope(|s| {
#             for partitionNo in 0..params.benchmarkNumberPartitions {
#                 s.spawn(move |_| {
#                     runInsertHelper(
#                         params.benchmarkBatchSize,
#                         params.benchmarkTransactionSize,
#                         &params.connections[partitionNo],
#                         partitionNo,
#                         &params.partitions[partitionNo],
#                         params.sqlInsert,
#                         trialNo,
#                     )
#                 })
#             }
#         })

#     }

#     # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
#     statistics.push(StatisticsEntryType {
#         action: "insert".toString(),
#         endTime: Local::now(),
#         sqlStmnt: params.sqlInsert.parse(),
#         startTime,
#         trialNo,
#     })

  logger.log(lvlDebug, "End   runInsert()")

# ==============================================================================
# Helper function for inserting data into the database.
# -----------------------------------------------------------------------------

proc runInsertHelper(logger: Logger, benchmarkBatchSize: uint,
    benchmarkTransactionSize: uint, connection: OracleConnection,
    partitionNo: uint, partition: PartitionType, sqlInsert: string,
    trialNo: uint) =
  logger.log(lvlDebug, "Start runInsertHelper()")

  #[
  IF trialNo == 1
    INFO Start insert partitionKey=partitionKey
  ENDIF
  ]#
  if trialNo == 1:
    stdout.writeline "Start insert partitionKey=", partitionNo

  #[
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
  ]#

#     var batchCollection = connection
#         .batch(
#             sqlInsert,
#             if benchmarkBatchSize == 0 {
#                 partition.len()
#             } else {
#                 benchmarkBatchSize as uint
#             },
#         )
#         .build()


#     var statement = connection.prepare(sqlInsert, &[])

#     var count = 0
#     for record in partition.iter() {
#         count += 1

#         if benchmarkBatchSize == 1 {
#             match statement.execute(&[&record.0, &record.1]) {
#                 Ok(_) => {}
#                 Err(error) => {
#                     error!(
#                         "runInsertHelper() - Problem with statement.execute(): {}",
#                         error
#                     )
#                     std::process::exit(1)
#                 }
#             }
#         } else {
#             match batchCollection.appendRow(&[&record.0, &record.1]) {
#                 Ok(_) => {}
#                 Err(error) => {
#                     error!(
#                         "runInsertHelper() - Problem with batch.appendRow(): {}",
#                         error
#                     )
#                     std::process::exit(1)
#                 }
#             }

#             if benchmarkBatchSize > 1 && (count % benchmarkBatchSize == 0) {
#                 executeBatch(&mut batchCollection)
#             }
#         }

#         if benchmarkTransactionSize > 0 && (count % benchmarkTransactionSize == 0) {
#             commit(connection)
#         }
#     }

  #[
  IF collection batchCollection is not empty
    execute the SQL statements in the collection batchCollection
  ENDIF
  ]#
#     if benchmarkBatchSize != 1 {
#         executeBatch(&mut batchCollection)
#     }

#     # commit
#     commit(connection)

  #[
  IF trialNo == 1
    INFO End   insert partitionKey=partitionKey
  ENDIF
  ]#
  if trialNo == 1:
    stdout.writeline "End   insert partitionKey=", partitionNo

  logger.log(lvlDebug, "End   runInsertHelper()")

# ==============================================================================
# Supervise function for retrieving of the database data.
# -----------------------------------------------------------------------------

proc runSelect(logger: Logger, connections: var ConnectionsType,
    paramsRunSelect: ParamsRunSelectType,

statistics: StatisticsType, trialNo: uint) =
  logger.log(lvlDebug, "Start runSelect()")

  # save the current time as the start of the 'query' action
  let startTime: DateTime = now()

  #[
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
  ]#
#     if benchmarkCoreMultiplier == 0 {
#         for partitionNo in 0..benchmarkNumberPartitions {
#             runSelectHelper(
#                 &connections[partitionNo],
#                 partitionNo,
#                 &partitions[partitionNo],
#                 sqlSelect,
#                 trialNo,
#             )
#         }
#     } else {
#         thread::scope(|s| {
#             for partitionNo in 0..benchmarkNumberPartitions {
#                 s.spawn(move |_| {
#                     runSelectHelper(
#                         &connections[partitionNo],
#                         partitionNo,
#                         &partitions[partitionNo],
#                         sqlSelect,
#                         trialNo,
#                     )
#                 })
#             }
#         })

#     }

  # WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
#     statistics.push(StatisticsEntryType {
#         action: "select".toString(),
#         endTime: Local::now(),
#         sqlStmnt: sqlSelect.parse(),
#         startTime,
#         trialNo,
#     })

  logger.log(lvlDebug, "End   runSelect()")

# ==============================================================================
# Helper function for retrieving data from the database.
# -----------------------------------------------------------------------------

proc runSelectHelper(logger: Logger, connection: OracleConnection,
    partitionNo: uint, partition: PartitionType, sqlSelect: string,
    trialNo: uint) =
  logger.log(lvlDebug, "Start runSelectHelper()")

  #[
  IF trialNo == 1
    INFO Start select partitionKey=partitionKey
  ENDIF
  ]#
  if trialNo == 1:
    stdout.writeline "Start select partitionKey=", partitionNo

#     # execute the SQL statement in config param 'sql.select
#     var sqlSelectComplete: string = sqlSelect.toString()
#     sqlSelectComplete.pushStr(" where partitionKey = ")
#     sqlSelectComplete.pushStr(&partitionNo.toString())
#     let rows = match connection.query(&sqlSelectComplete, &[]) {
#         Ok(rows) => rows,
#         Err(error) => {
#             error!(
#                 "createResultFile() - Problem with select '{}': {}",
#                 sqlSelectComplete, error
#             )
#             std::process::exit(1)
#         }
#     }

  #[
  int count = 0
  WHILE iterating through the result set
    count + 1
  ENDWHILE
  ]#
#     var count: uint = 0
#     for Row in rows {
#         count += 1
#     }

  #[
  IF NOT count = size(bulkDataPartition)
    display an error message
  ENDIF
  ]#
#     if count != partition.len() {
#         error!(
#             "Number rows: expected={} - found={}",
#             partition.len(),
#             count
#         )
#         std::process::exit(1)
#     }

  #[
  IF trialNo == 1
    INFO End   select partitionKey=partitionKey
  ENDIF
  ]#
  if trialNo == 1:
    stdout.writeline "End   select partitionKey=", partitionNo

  logger.log(lvlDebug, "End   runSelectHelper()")

# ==============================================================================
# Performing a single trial run.
# -----------------------------------------------------------------------------

proc runTrial(logger: Logger, connections: var ConnectionsType,
    paramsRunTrial: ParamsRunTrialType,

statistics: StatisticsType, trialNo: uint) =
  logger.log(lvlDebug, "Start runTrial()")

  # save the current time as the start of the 'trial' action
  let startTime: DateTime = now()

  # INFO  Start trial no. trialNo
  stdout.writeline "Start trial no. ", trialNo

  #[
  create the database table (config param 'sql.create')
  IF error
    drop the database table (config param 'sql.drop')
    create the database table (config param 'sql.create')
  ENDIF
  ]#
  var resultSet: db_oracle.ResultSet

  var sqlCreateSql: db_oracle.SqlQuery = osql paramsRunTrial.sqlCreateStr
  var sqlCreatePS: db_oracle.PreparedStatement

  var sqlDropSql: db_oracle.SqlQuery = osql paramsRunTrial.sqlDropStr
  var sqlDropPS: db_oracle.PreparedStatement

  db_oracle.newPreparedStatement(connections[0], sqlCreateSql,
      sqlCreatePS, 1)
  db_oracle.newPreparedStatement(connections[0], sqlDropSql,
      sqlDropPS, 1)

  try:
    executeStatement(sqlCreatePS, resultSet)
    logger.log(lvlDebug, "last DDL statement=", paramsRunTrial.sqlCreateStr)
  except:
    try:
      executeStatement(sqlDropPS, resultSet)
      executeStatement(sqlCreatePS, resultSet)
      logger.log(lvlDebug, "last DDL statement after DROP=",
          paramsRunTrial.sqlCreateStr)
    except:
      logger.log(lvlFatal, "runTrial() - Problem dropping the database table: ",
          getCurrentExceptionMsg())

  #[
  DO runInsert(database connections,
               trialNo,
               bulkDataPartitions)
  ]#
#     let paramsRunInsert = ParamsRunInsert {
#         benchmarkBatchSize: params.benchmarkBatchSize,
#         benchmarkCoreMultiplier: params.benchmarkCoreMultiplier,
#         benchmarkNumberPartitions: params.benchmarkNumberPartitions,
#         benchmarkTransactionSize: params.benchmarkTransactionSize,
#         connections: params.connections,
#         partitions: params.partitions,
#         sqlInsert: params.sqlInsert,
#     }

#     let resultRunInsert = runInsert(paramsRunInsert, statistics, trialNo)
#     if resultRunInsert.isErr() {
#         error!(
#             "runTrial() - Problem in runInsert: {}",
#             resultRunInsert.err()
#         )
#         std::process::exit(1)
#     }

  #[
  DO runSelect(database connections,
               trialNo,
               bulkDataPartitions)
  ]#
#     let resultRunSelect = runSelect(
#         params.benchmarkCoreMultiplier,
#         params.benchmarkNumberPartitions,
#         params.connections,
#         params.partitions,
#         params.sqlSelect,
#         statistics,
#         trialNo,
#     )
#     if resultRunSelect.isErr() {
#         error!(
#             "runTrial() - Problem in runSelect: {}",
#             resultRunSelect.err()
#         )
#         std::process::exit(1)
#     }

  # drop the database table (config param 'sql.drop')
#     resultCreateDrop = params.connections[0].execute(params.sqlDrop, &[])
#     if resultCreateDrop.isErr() {
#         error!(
#             "runTrial() - Problem dropping the database table: {}",
#             resultCreateDrop.err()
#         )
#         std::process::exit(1)
#     }
#     logger.log(lvlDebug, "last DDL statement={}", params.sqlCreate)

  # WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
  let endTime: DateTime = now()

#     statistics.push(StatisticsEntryType {
#         action: "trial".toString(),
#         endTime,
#         sqlStmnt: "".toString(),
#         startTime,
#         trialNo,
#     })

  stdout.writeline "Duration (ms) trial         : ", (endTime -
      startTime).inMilliseconds()

  logger.log(lvlDebug, "End   runTrial()")
