package ch.konnexions

import org.apache.logging.log4j.Logger
import java.sql.Statement

/**
 * Helper class for retrieving data from the database.
 */
class RunSelectHelper(
    logger: Logger,
    isDebug: Boolean,
    statement: Statement,
    bulkDataPartition: ArrayList<Array<String>>,
    partitionKey: Int,
    connectionFetchSize: Int,
    sqlSelect: String
) : Runnable {
    private val bulkDataPartition: ArrayList<Array<String>>
    private val connectionFetchSize: Int
    private val isDebug: Boolean
    private val logger: Logger
    private val partitionKey: Int
    private val sqlSelect: String
    private val statement: Statement

    /**
     * Instantiates a new Select class.
     */
    init {
        if (isDebug) {
            logger.debug("Start")
        }

        this.bulkDataPartition = bulkDataPartition
        this.connectionFetchSize = connectionFetchSize
        this.isDebug = isDebug
        this.logger = logger
        this.partitionKey = partitionKey
        this.sqlSelect = sqlSelect
        this.statement = statement

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

        OraBench.runSelectHelper(
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
}
