package main.kotlin.ch.konnexions

import org.apache.logging.log4j.Logger
import java.sql.Connection
import java.sql.PreparedStatement

/**
 * Helper class for inserting data into the database.
 */
class RunInsertHelper(
    logger: Logger,
    connection: Connection,
    preparedStatement: PreparedStatement,
    partitionKey: Int,
    bulkDataPartition: ArrayList<Array<String>>,
    benchmarkSize: Int,
    benchmarkTransactionSize: Int,
    trialNumber: Int
) :
    Runnable {
    private val benchmarkSize: Int
    private val benchmarkTransactionSize: Int
    private val bulkDataPartition: ArrayList<Array<String>>
    private val connection: Connection
    private val logger: Logger
    private val partitionKey: Int
    private val preparedStatement: PreparedStatement
    private val trialNumber: Int

    /**
     * Instantiates a new Insert class.
     */
    init {
        logger.debug("Start <- init <- RunInsertHelper")

        this.benchmarkSize = benchmarkSize
        this.benchmarkTransactionSize = benchmarkTransactionSize
        this.bulkDataPartition = bulkDataPartition
        this.connection = connection
        this.logger = logger
        this.partitionKey = partitionKey
        this.preparedStatement = preparedStatement
        this.trialNumber = trialNumber

        logger.debug("End   <- init <- RunInsertHelper")
    }

    /**
     * Runs the thread implementer.
     */
    override fun run() {
        logger.debug("Start <- run <- RunInsertHelper")

        OraBench.runInsertHelper(
            logger,
            connection,
            preparedStatement,
            partitionKey,
            bulkDataPartition,
            benchmarkSize,
            benchmarkTransactionSize,
            trialNumber
        )

        logger.debug("End   <- run <- RunInsertHelper")
    }
}
