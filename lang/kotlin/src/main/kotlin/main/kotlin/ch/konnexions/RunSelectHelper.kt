package main.kotlin.ch.konnexions

import org.apache.logging.log4j.Logger
import java.sql.Statement

/**
 * Helper class for retrieving data from the database.
 */
class RunSelectHelper(
    logger: Logger,
    statement: Statement,
    bulkDataPartition: ArrayList<Array<String>>,
    partitionKey: Int,
    connectionFetchSize: Int,
    sqlSelect: String,
    trialNumber: Int
) : Runnable {
    private val bulkDataPartition: ArrayList<Array<String>>
    private val connectionFetchSize: Int
    private val logger: Logger
    private val partitionKey: Int
    private val sqlSelect: String
    private val statement: Statement
    private val trialNumber: Int

    /**
     * Instantiates a new Select class.
     */
    init {
        logger.debug("Start <- init <- RunSelectHelper")

        this.bulkDataPartition = bulkDataPartition
        this.connectionFetchSize = connectionFetchSize
        this.logger = logger
        this.partitionKey = partitionKey
        this.sqlSelect = sqlSelect
        this.statement = statement
        this.trialNumber = trialNumber

        logger.debug("End   <- init <- RunSelectHelper")
    }

    /**
     * Runs the thread implementer.
     */
    override fun run() {
        logger.debug("Start <- run <- RunSelectHelper")

        OraBench.runSelectHelper(
            logger,
            statement,
            bulkDataPartition,
            partitionKey,
            connectionFetchSize,
            sqlSelect,
            trialNumber
        )

        logger.debug("End   <- run <- RunSelectHelper")
    }
}
