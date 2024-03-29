package main.kotlin.ch.konnexions

import org.apache.logging.log4j.Logger
import java.sql.Connection
import java.sql.PreparedStatement

/**
 * Helper class for inserting data into the database.
 */
class RunInsertHelper(
    logger: Logger,
    isDebug: Boolean,
    connection: Connection,
    preparedStatement: PreparedStatement,
    benchmarkCoreMultiplier: Int,
    partitionKey: Int,
    bulkDataPartition: ArrayList<Array<String>>,
    benchmarkSize: Int,
    benchmarkTransactionSize: Int
) :
    Runnable {
    private val benchmarkCoreMultiplier: Int
    private val benchmarkSize: Int
    private val benchmarkTransactionSize: Int
    private val bulkDataPartition: ArrayList<Array<String>>
    private val connection: Connection
    private val isDebug: Boolean
    private val logger: Logger
    private val partitionKey: Int
    private val preparedStatement: PreparedStatement

    /**
     * Instantiates a new Insert class.
     */
    init {
        if (isDebug) {
            logger.debug("Start")
        }

        this.benchmarkCoreMultiplier = benchmarkCoreMultiplier
        this.benchmarkSize = benchmarkSize
        this.benchmarkTransactionSize = benchmarkTransactionSize
        this.bulkDataPartition = bulkDataPartition
        this.connection = connection
        this.isDebug = isDebug
        this.logger = logger
        this.partitionKey = partitionKey
        this.preparedStatement = preparedStatement

        if (isDebug) {
            logger.debug("End")
        }
    }

    /**
     * Runs the thread implementer.
     */
    override fun run() {
        if (isDebug) {
            logger.debug("Start")
        }

        OraBench.runInsertHelper(
            logger,
            isDebug,
            connection,
            preparedStatement,
            benchmarkCoreMultiplier,
            partitionKey,
            bulkDataPartition,
            benchmarkSize,
            benchmarkTransactionSize
        )

        if (isDebug) {
            logger.debug("End")
        }
    }
}
