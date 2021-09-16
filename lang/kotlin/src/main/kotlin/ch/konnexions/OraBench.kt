package main.kotlin.ch.konnexions/*
 * 
 */

import org.apache.commons.csv.CSVFormat
import org.apache.commons.csv.CSVPrinter
import org.apache.commons.csv.CSVRecord
import org.apache.logging.log4j.LogManager
import org.apache.logging.log4j.Logger

import java.io.*
import java.nio.file.Files
import java.nio.file.Paths
import java.sql.*
import java.text.DecimalFormat
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

import kotlin.math.roundToLong
import kotlin.properties.Delegates
import kotlin.system.exitProcess

class OraBench {
    val logger: Logger = LogManager.getLogger(OraBench::class.java)
    val isDebug: Boolean = logger.isDebugEnabled

    private var benchmarkBatchSize by Delegates.notNull<Int>()
    private lateinit var benchmarkComment: String
    private var benchmarkCoreMultiplier by Delegates.notNull<Int>()
    private lateinit var benchmarkDatabase: String
    private lateinit var benchmarkDriver: String
    private lateinit var benchmarkHostName: String
    private lateinit var benchmarkId: String
    private lateinit var benchmarkLanguage: String
    private lateinit var benchmarkNumberCores: String
    private var benchmarkNumberPartitions by Delegates.notNull<Int>()
    private lateinit var benchmarkOs: String
    private lateinit var benchmarkRelease: String
    private var benchmarkTransactionSize by Delegates.notNull<Int>()
    private var benchmarkTrials by Delegates.notNull<Int>()
    private lateinit var benchmarkUserName: String

    private val config = Properties()
    private var connection: Connection? = null
    private var connectionFetchSize by Delegates.notNull<Int>()
    private lateinit var connectionHost: String
    private lateinit var connectionPassword: String
    private var connectionPort by Delegates.notNull<Int>()
    private lateinit var connectionService: String
    private lateinit var connectionUser: String

    private val decimalFormat: DecimalFormat = DecimalFormat("#########")

    private var executorService: ExecutorService? = null

    private lateinit var fileBulkDelimiter: String
    private lateinit var fileBulkHeader: String
    private var fileBulkLength by Delegates.notNull<Int>()
    private lateinit var fileBulkName: String
    private var fileBulkSize by Delegates.notNull<Int>()
    private val fileConfigurationName: File = File("priv/properties/ora_bench.properties")
    private lateinit var fileResultDelimiter: String
    private lateinit var fileResultHeader: String
    private lateinit var fileResultName: String

    @Suppress("SpellCheckingInspection")
    private val formatter: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn")

    private val lastBenchmark = LocalDateTime.now()
    private val lastBenchmarkNano = System.nanoTime()
    private var lastQuery: LocalDateTime? = null
    private var lastQueryNano: Long = 0
    private var lastTrial: LocalDateTime? = null
    private var lastTrialNano: Long = 0

    private var resultFile: CSVPrinter? = null

    private lateinit var sqlCreate: String
    private lateinit var sqlDrop: String
    private lateinit var sqlInsert: String
    private lateinit var sqlSelect: String

    companion object {
        /**
         * Helper function for inserting data into the database.
         *
         * @param connection        the database connection
         * @param preparedStatement the prepared statement
         * @param bulkDataPartition the bulk data partition
         */
        fun runInsertHelper(
            logger: Logger,
            isDebug: Boolean,
            connection: Connection,
            preparedStatement: PreparedStatement,
            bulkDataPartition: ArrayList<Array<String>>,
            benchmarkBatchSize: Int,
            benchmarkTransactionSize: Int
        ) {
            if (isDebug) {
                logger.debug("Start")
            }

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
            var count = 0

            try {
                for (value in bulkDataPartition) {
                    preparedStatement.setString(
                        1,
                        value[0]
                    )

                    preparedStatement.setString(
                        2,
                        value[1]
                    )

                    count += 1

                    if (benchmarkBatchSize == 0) {
                        preparedStatement.execute()
                    } else {
                        preparedStatement.addBatch()
                        if (count % benchmarkBatchSize == 0) {
                            preparedStatement.executeBatch()
                        }
                    }

                    if (benchmarkTransactionSize > 0 && count % benchmarkTransactionSize == 0) {
                        connection.commit()
                    }
                }
            } catch (e: SQLException) {
                e.printStackTrace()
                exitProcess(1)
            }


            /*      
            IF collection batch_collection is not empty
              execute the SQL statements in the collection batch_collection
            ENDIF
            */
            if (benchmarkBatchSize > 0 && count % benchmarkBatchSize != 0) {
                preparedStatement.executeBatch()
            }

            // commit
            if (benchmarkTransactionSize == 0 || count % benchmarkTransactionSize != 0) {
                connection.commit()
            }

            if (isDebug) {
                logger.debug("End")
            }
        }

        /**
         * Helper function for retrieving data from the database.
         *
         * @param statement         the statement
         * @param bulkDataPartition the bulk data partition
         * @param partitionKey      the partition key
         */
        fun runSelectHelper(
            logger: Logger,
            isDebug: Boolean,
            statement: Statement,
            bulkDataPartition: ArrayList<Array<String>>,
            partitionKey: Int,
            connectionFetchSize: Int,
            sqlSelect: String
        ) {
            if (isDebug) {
                logger.debug("Start")
            }

            var count = 0

            try {
                if (connectionFetchSize > 0) {
                    statement.fetchSize = connectionFetchSize
                }

                // execute the SQL statement in config param 'sql.select'
                val resultSet: ResultSet =
                    statement.executeQuery("$sqlSelect WHERE partition_key = $partitionKey")

                /*
                int count = 0;
                WHILE iterating through the result set
                    count + 1
                ENDWHILE
                */
                while (resultSet.next()) {
                    count += 1
                }

                /*
                IF NOT count = size(bulk_data_partition)
                    display an error message
                ENDIF     
                */
                if (count != bulkDataPartition.size) {
                    logger.error("Number rows: expected=" + bulkDataPartition.size + " - found=" + count)
                }
            } catch (e: SQLException) {
                e.printStackTrace()
                exitProcess(1)
            }

            if (isDebug) {
                logger.debug("End")
            }
        }
    }

    /**
     * Creates a database connection.
     *
     * @return the database connection
     */
    private fun connect(): Connection? {
        if (isDebug) {
            logger.debug("Start")
        }

        val url = "jdbc:oracle:thin:@//$connectionHost:$connectionPort/$connectionService?oracle.net.disableOob=true"

        if (connection == null) {
            try {
                connection = DriverManager.getConnection(
                    url,
                    connectionUser,
                    connectionPassword
                )

                connection.let {
                    val meta: DatabaseMetaData = connection!!.metaData
                    benchmarkDriver = "Oracle JDBC (Version " + meta.driverVersion.toString() + ")"
                }
            } catch (ec: SQLException) {
                logger.error("connection parameter url     =: $url")
                logger.error("connection parameter username=: $connectionUser")
                logger.error("connection parameter password=: $connectionPassword")
                ec.printStackTrace()
                exitProcess(1)
            }
        }

        if (isDebug) {
            logger.debug("End")
        }

        return connection
    }

    /**
     * Creates the database objects of type Connection, PreparedStatement, ResultSet
     * and Statement.
     *
     * @return the array list containing the database objects of the classes
     *         Connection, PreparedStatement and Statement
     */
    private fun createDatabaseObjects(): ArrayList<Any> {
        if (isDebug) {
            logger.debug("Start")
        }

        val connections: ArrayList<Connection> =
            ArrayList(benchmarkNumberPartitions)
        val preparedStatements: ArrayList<PreparedStatement> =
            ArrayList(benchmarkNumberPartitions)
        val statements: ArrayList<Statement> =
            ArrayList(benchmarkNumberPartitions)

        for (i in 0 until benchmarkNumberPartitions) {
            try {
                val connection: Connection = connect()!!
                connection.autoCommit = false
                connections.add(connection)

                preparedStatements.add(
                    connection.prepareStatement(
                        sqlInsert.replace(
                            ":key",
                            "?"
                        ).replace(
                            ":data",
                            "?"
                        )
                    )
                )

                statements.add(connection.createStatement())
            } catch (e: SQLException) {
                e.printStackTrace()
                exitProcess(1)
            }
        }

        if (isDebug) {
            logger.debug("End")
        }

        return ArrayList(
            listOf<ArrayList<out Any>>(
                connections,
                preparedStatements,
                statements
            )
        )
    }

    private fun createMeasuringPoint(
        trialNo: Int,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
        duration: Long
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        createMeasuringPoint(
            "trial",
            trialNo,
            null,
            startDateTime,
            endDateTime,
            duration
        )

        logger.info("Duration (ms) trial         : " + duration / 1000000);

        if (isDebug) {
            logger.debug("End")
        }
    }

    private fun createMeasuringPoint(endDateTime: LocalDateTime, duration: Long) {
        if (isDebug) {
            logger.debug("Start")
        }

        createMeasuringPoint(
            "benchmark",
            0,
            null,
            lastBenchmark,
            endDateTime,
            duration
        )

        logger.info("Duration (ms) benchmark run: " + duration / 1000000);

        if (isDebug) {
            logger.debug("End")
        }
    }

    private fun createMeasuringPoint(
        action: String,
        trialNo: Int,
        sqlStatement: String?,
        startDateTime: LocalDateTime,
        endDateTime: LocalDateTime,
        duration: Long
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        try {
            resultFile!!.printRecord(
                benchmarkRelease,
                benchmarkId,
                benchmarkComment,
                benchmarkHostName,
                benchmarkNumberCores,
                benchmarkOs,
                benchmarkUserName,
                benchmarkDatabase,
                benchmarkLanguage,
                benchmarkDriver,
                trialNo,
                sqlStatement,
                benchmarkCoreMultiplier,
                connectionFetchSize,
                benchmarkTransactionSize,
                fileBulkLength,
                fileBulkSize,
                benchmarkBatchSize,
                action,
                startDateTime.format(formatter),
                endDateTime.format(formatter),
                decimalFormat.format((duration / 1000000000.0).roundToLong()),
                duration.toString()
            )
        } catch (e: IOException) {
            logger.error("file result delimiter=: $fileResultDelimiter")
            logger.error("file result header   =: $fileResultHeader")
            logger.error("file result name     =: $fileBulkSize")
            e.printStackTrace()
            exitProcess(1)
        }

        if (isDebug) {
            logger.debug("End")
        }
    }

    private fun executorServiceShutdown() {
        if (isDebug) {
            logger.debug("Start")
        }

        if (benchmarkCoreMultiplier != 0) {
            executorService!!.shutdown()

            try {
                @Suppress("ControlFlowWithEmptyBody")
                while (!executorService!!.awaitTermination(
                        1,
                        TimeUnit.SECONDS
                    )
                ) {
                }
            } catch (e: InterruptedException) {
                e.printStackTrace()
                exitProcess(1)
            }
        }

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Gets the bulk data partitioned.
     *
     * @return the bulk data partitioned
     */
    private fun getBulkDataPartitions(): ArrayList<ArrayList<Array<String>>> {
        if (isDebug) {
            logger.debug("Start")
        }

        val bulkDataPartitions: ArrayList<ArrayList<Array<String>>> =
            ArrayList(benchmarkNumberPartitions)
        val expectedBulkDataSize: Int = fileBulkSize / benchmarkNumberPartitions

        for (i in 0 until benchmarkNumberPartitions) {
            bulkDataPartitions.add(ArrayList(expectedBulkDataSize))
        }

        try {
            val bufferedReader = BufferedReader(FileReader(fileBulkName))

            val records: Iterable<CSVRecord> =
                CSVFormat.EXCEL.builder().setDelimiter(fileBulkDelimiter[0]).setHeader(
                    *fileBulkHeader.split(fileBulkDelimiter[0].toString()).toTypedArray()
                ).build().parse(bufferedReader)

            for (record in records) {
                val keyValue: String = record.get("key")
                if (keyValue != "key") {
                    val partitionKey: Int =
                        (keyValue[0].code * 251 + keyValue[1].code) % benchmarkNumberPartitions
                    bulkDataPartitions[partitionKey].add(
                        arrayOf(
                            keyValue,
                            record.get("data")
                        )
                    )
                }
            }

            bufferedReader.close()

            logger.info("Start Distribution of the data in the partitions")

            for (i in 0 until benchmarkNumberPartitions) {
                logger.info(
                    "Partition p" + String.format(
                        "%05d",
                        i
                    ) + " contains " + String.format(
                        "%9d",
                        bulkDataPartitions[i].size
                    ) + " rows"
                )
            }

            logger.info("End   Distribution of the data in the partitions")
        } catch (e: IOException) {
            e.printStackTrace()
            exitProcess(1)
        }

        if (isDebug) {
            logger.debug("End")
        }

        return bulkDataPartitions
    }

    fun getConfig() {
        if (isDebug) {
            logger.debug("Start")
        }

        FileInputStream(fileConfigurationName).use { config.load(it) }

        benchmarkBatchSize = config.getProperty("benchmark.batch.size").toInt()
        benchmarkComment = config.getProperty("benchmark.comment")
        benchmarkCoreMultiplier = config.getProperty("benchmark.core.multiplier").toInt()
        benchmarkDatabase = config.getProperty("benchmark.database")
        benchmarkDriver = config.getProperty("benchmark.driver")
        benchmarkHostName = config.getProperty("benchmark.host.name")
        benchmarkId = config.getProperty("benchmark.id")
        benchmarkLanguage = "Kotlin " + KotlinVersion.CURRENT
        benchmarkNumberCores = config.getProperty("benchmark.number.cores")
        benchmarkNumberPartitions = config.getProperty("benchmark.number.partitions").toInt()
        benchmarkOs = config.getProperty("benchmark.os")
        benchmarkRelease = config.getProperty("benchmark.release")
        benchmarkTransactionSize = config.getProperty("benchmark.transaction.size").toInt()
        benchmarkTrials = config.getProperty("benchmark.trials").toInt()
        benchmarkUserName = config.getProperty("benchmark.user.name")

        connectionFetchSize = config.getProperty("connection.fetch.size").toInt()
        connectionHost = config.getProperty("connection.host")
        connectionPassword = config.getProperty("connection.password")
        connectionPort = config.getProperty("connection.port").toInt()
        connectionService = config.getProperty("connection.service")
        connectionUser = config.getProperty("connection.user")

        fileBulkDelimiter = config.getProperty("file.bulk.delimiter")
        fileBulkHeader = config.getProperty("file.bulk.header")
        fileBulkLength = config.getProperty("file.bulk.length").toInt()
        fileBulkName = config.getProperty("file.bulk.name")
        fileBulkSize = config.getProperty("file.bulk.size").toInt()
        fileResultDelimiter = config.getProperty("file.result.delimiter")
        fileResultHeader = config.getProperty("file.result.header")
        fileResultName = config.getProperty("file.result.name")

        sqlCreate = config.getProperty("sql.create")
        sqlDrop = config.getProperty("sql.drop")
        sqlInsert = config.getProperty("sql.insert")
        sqlSelect = config.getProperty("sql.select")

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * End of the whole benchmark run.
     */
    private fun resultBenchmarkEnd() {
        if (isDebug) {
            logger.debug("Start")
        }

        val endDateTime: LocalDateTime = LocalDateTime.now()
        val duration: Long = System.nanoTime() - lastBenchmarkNano

        createMeasuringPoint(
            endDateTime,
            duration
        )

        try {
            resultFile!!.close()
        } catch (e: IOException) {
            logger.error("file result delimiter=: $fileResultDelimiter")
            logger.error("file result header   =: $fileResultHeader")
            logger.error("file result name     =: $fileBulkSize")
            e.printStackTrace()
            exitProcess(1)
        }

        if (isDebug) {
            logger.debug("End")
        }
    }

    private fun resultBenchmarkStart() {
        if (isDebug) {
            logger.debug("Start")
        }

        val resultDelimiter = fileResultDelimiter
        val resultName = fileResultName

        try {
            val isFileExisting: Boolean = Files.exists(Paths.get(resultName))

            if (!isFileExisting) {
                logger.error("fatal error: program abort =====> result file \"$resultName\" is missing <=====")
                exitProcess(1)
            }

            val bufferedWriter = BufferedWriter(FileWriter(resultName, true))
            resultFile = CSVPrinter(bufferedWriter, CSVFormat.EXCEL.builder().setDelimiter(resultDelimiter[0]).build())
        } catch (e: IOException) {
            logger.error("file result delimiter=: $resultDelimiter")
            logger.error("file result header   =: $fileResultHeader")
            logger.error("file result name     =: $resultName")
            logger.error("-----------------------")
            e.printStackTrace()
            exitProcess(1)
        }

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * End of the current SQL statement.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    private fun resultQueryEnd(trialNo: Int, sqlStatement: String?) {
        if (isDebug) {
            logger.debug("Start")
        }

        val endDateTime = LocalDateTime.now()
        val duration = System.nanoTime() - lastQueryNano

        createMeasuringPoint(
            "query",
            trialNo,
            sqlStatement,
            lastQuery!!,
            endDateTime,
            duration
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Start a new query.
     */
    private fun resultQueryStart() {
        if (isDebug) {
            logger.debug("Start")
        }

        lastQuery = LocalDateTime.now()
        lastQueryNano = System.nanoTime()

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * End of the current trial.
     *
     * @param trialNo the current trial number
     */
    private fun resultTrialEnd(trialNo: Int) {
        if (isDebug) {
            logger.debug("Start")
        }

        createMeasuringPoint(
            trialNo,
            lastTrial!!,
            LocalDateTime.now(),
            System.nanoTime() - lastTrialNano
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Start a new trial.
     */
    private fun resultTrialStart() {
        if (isDebug) {
            logger.debug("Start")
        }

        lastTrial = LocalDateTime.now()
        lastTrialNano = System.nanoTime()

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Performing a complete benchmark run that can consist of several trial runs.
     */
    fun runBenchmark() {
        if (isDebug) {
            logger.debug("Start")
        }

        // save the current time as the start of the 'benchmark' action
        resultBenchmarkStart()

        // READ the bulk file data into the partitioned collection bulk_data_partitions (config param 'file.bulk.name')
        val bulkDataPartitions: ArrayList<ArrayList<Array<String>>> = getBulkDataPartitions()

        // create a separate database connection (without auto commit behaviour) for each partition
        val databaseObjects: ArrayList<Any> = createDatabaseObjects()

        @Suppress("UNCHECKED_CAST")
        val connections: ArrayList<Connection> = databaseObjects[0] as ArrayList<Connection>

        @Suppress("UNCHECKED_CAST")
        val preparedStatements: ArrayList<PreparedStatement> =
            databaseObjects[1] as ArrayList<PreparedStatement>

        @Suppress("UNCHECKED_CAST")
        val statements: ArrayList<Statement> = databaseObjects[2] as ArrayList<Statement>

        /*
        trial_no = 0
        WHILE trial_no < config_param 'benchmark.trials'
            DO run_trial(database connections,
                         trial_no,
                         bulk_data_partitions)
        ENDWHILE
        */
        for (i in 1..benchmarkTrials) {
            runTrial(
                connections,
                preparedStatements,
                statements,
                i,
                bulkDataPartitions
            )
        }

        /*  
        partition_no = 0
        WHILE partition_no < config_param 'benchmark.number.partitions'
            close the database connection
        ENDWHILE
        */
        for (i in 0 until benchmarkNumberPartitions) {
            try {
                preparedStatements[i].close()
                statements[i].close()
                connections[i].close()
            } catch (e: SQLException) {
                e.printStackTrace()
                exitProcess(1)
            }
        }

        // WRITE an entry for the action 'benchmark' in the result file (config param 'file.result.name')
        resultBenchmarkEnd()

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Supervise function for inserting data into the database.
     *
     * @param connections        the database connections
     * @param preparedStatements the prepared statements
     * @param trialNumber        the trial number
     * @param bulkDataPartitions the bulk data partitioned
     */
    private fun runInsert(
        connections: ArrayList<Connection>,
        preparedStatements: ArrayList<PreparedStatement>,
        trialNumber: Int,
        bulkDataPartitions: ArrayList<ArrayList<Array<String>>>
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        // save the current time as the start of the 'query' action
        resultQueryStart()

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
        if (benchmarkCoreMultiplier != 0) {
            executorService = Executors.newFixedThreadPool(benchmarkNumberPartitions)
        }

        for (i in 0 until benchmarkNumberPartitions) {
            if (benchmarkCoreMultiplier == 0) {
                runInsertHelper(
                    connections[i],
                    preparedStatements[i],
                    bulkDataPartitions[i]
                )
            } else {
                RunInsertHelper(
                    logger,
                    isDebug,
                    connections[i],
                    preparedStatements[i],
                    bulkDataPartitions[i],
                    benchmarkBatchSize,
                    benchmarkTransactionSize
                )
            }
        }

        executorServiceShutdown()

        // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')        
        resultQueryEnd(
            trialNumber,
            sqlInsert
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Helper function for inserting data into the database.
     *
     * @param connection        the database connection
     * @param preparedStatement the prepared statement
     * @param bulkDataPartition the bulk data partition
     */
    private fun runInsertHelper(
        connection: Connection,
        preparedStatement: PreparedStatement,
        bulkDataPartition: ArrayList<Array<String>>
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        runInsertHelper(
            logger,
            isDebug,
            connection,
            preparedStatement,
            bulkDataPartition,
            benchmarkBatchSize,
            benchmarkTransactionSize
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Supervise function for retrieving of the database data.
     *
     * @param statements         the statements
     * @param trialNumber        the trial number
     * @param bulkDataPartitions the bulk data partitioned
     */
    private fun runSelect(
        statements: ArrayList<Statement>,
        trialNumber: Int,
        bulkDataPartitions: ArrayList<ArrayList<Array<String>>>
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        // save the current time as the start of the 'query' action
        resultQueryStart()

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
        if (benchmarkCoreMultiplier != 0) {
            executorService = Executors.newFixedThreadPool(benchmarkNumberPartitions)
        }

        for (i in 0 until benchmarkNumberPartitions) {
            if (benchmarkCoreMultiplier == 0) {
                runSelectHelper(
                    statements[i],
                    bulkDataPartitions[i],
                    i
                )
            } else {
                executorService?.execute(
                    RunSelectHelper(
                        logger,
                        isDebug,
                        statements[i],
                        bulkDataPartitions[i],
                        i,
                        connectionFetchSize,
                        sqlSelect
                    )
                )
            }
        }

        executorServiceShutdown()

        // WRITE an entry for the action 'query' in the result file (config param 'file.result.name')
        resultQueryEnd(
            trialNumber,
            sqlSelect
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Helper function for retrieving data from the database.
     *
     * @param statement         the statement
     * @param bulkDataPartition the bulk data partition
     * @param partitionKey      the partition key
     */
    private fun runSelectHelper(statement: Statement, bulkDataPartition: ArrayList<Array<String>>, partitionKey: Int) {
        if (isDebug) {
            logger.debug("Start")
        }

        runSelectHelper(
            logger,
            isDebug,
            statement,
            bulkDataPartition,
            partitionKey,
            connectionFetchSize,
            sqlSelect
        )

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Performing a single trial run.
     *
     * @param connections        the database connections
     * @param statements         the statements
     * @param preparedStatements the prepared statements
     * @param trialNumber        the trial number
     * @param bulkDataPartitions the bulk data partitioned
     */
    private fun runTrial(
        connections: ArrayList<Connection>,
        preparedStatements: ArrayList<PreparedStatement>,
        statements: ArrayList<Statement>,
        trialNumber: Int,
        bulkDataPartitions: ArrayList<ArrayList<Array<String>>>
    ) {
        if (isDebug) {
            logger.debug("Start")
        }

        // save the current time as the start of the 'trial' action
        resultTrialStart()

        logger.info("Start trial no. $trialNumber")

        /*  
        create the database table (config param 'sql.create')
        IF error
            drop the database table (config param 'sql.drop')
            create the database table (config param 'sql.create')
        ENDIF
        */
        try {
            statements[0].executeUpdate(sqlCreate)

            if (isDebug) {
                logger.debug("last DDL statement=$sqlCreate")
            }
        } catch (es1: SQLException) {
            try {
                statements[0].executeUpdate(sqlDrop)
                statements[0].executeUpdate(sqlCreate)
                if (isDebug) {
                    logger.debug("last DDL statement after DROP=$sqlCreate")
                }
            } catch (es2: SQLException) {
                es2.printStackTrace()
                exitProcess(1)
            }
        }

        /*    
        DO run_insert(database connections,
                      trial_no,
                      bulk_data_partitions)
        */
        runInsert(
            connections,
            preparedStatements,
            trialNumber,
            bulkDataPartitions
        )

        /*
        DO run_select(database connections,
                      trial_no,
                      bulk_data_partitions)
        */
        runSelect(
            statements,
            trialNumber,
            bulkDataPartitions
        )

        // drop the database table (config param 'sql.drop')
        try {
            statements[0].executeUpdate(sqlDrop)

            if (isDebug) {
                logger.debug("last DDL statement=$sqlDrop")
            }
        } catch (es: SQLException) {
            es.printStackTrace()
            exitProcess(1)
        }

        // WRITE an entry for the action 'trial' in the result file (config param 'file.result.name')
        resultTrialEnd(trialNumber)

        if (isDebug) {
            logger.debug("End")
        }
    }

}

/**
 * This is the main function for the Oracle benchmark run.
 *
 * @param args n/a
 */
fun main(args: Array<String>) {
    val oraBench = OraBench()

    if (oraBench.isDebug) {
        oraBench.logger.debug("Start")
    }

    oraBench.logger.info("Start OraBench.kt")

    val numberArgs: Int = args.size

    oraBench.logger.info("main() - number arguments=$numberArgs")

    if (numberArgs != 0) {
        oraBench.logger.info("main() - 1st argument=" + args[0]);
        oraBench.logger.error("main() - Unknown command line argument(s)")
    }

    // READ the configuration parameters into the memory (config params `file.configuration.name ...`)
    oraBench.getConfig()

    oraBench.runBenchmark()

    oraBench.logger.info("End   OraBench.kt")

    if (oraBench.isDebug) {
        oraBench.logger.debug("End")
    }

    exitProcess(0)
}

