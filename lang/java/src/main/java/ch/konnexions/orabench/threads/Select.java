/*
 *
 */

package ch.konnexions.orabench.threads;

import java.sql.Statement;
import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import ch.konnexions.orabench.OraBench;
import ch.konnexions.orabench.utils.Config;

// TODO: Auto-generated Javadoc

/**
 * The Class Select.
 */
public class Select implements Runnable {

    /** The Constant logger. */
    private static final Logger logger = LogManager.getLogger(Select.class);

    /** The Constant isDebug. */
    private final static boolean isDebug = logger.isDebugEnabled();

    /** The bulk data partition. */
    private final ArrayList<String[]> bulkDataPartition;

    /** The config. */
    private final Config config;

    /** The partition key. */
    private final int partitionKey;

    /** The statement. */
    private final Statement statement;

    /**
     * Instantiates a new Select class.
     *
     * @param config            the configuration parameters
     * @param statement         the statement
     * @param bulkDataPartition the bulk data partition
     * @param partitionKey      the partition key
     */
    public Select(Config config, Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey) {
        if (isDebug) {
            logger.debug("Start");
        }

        this.config = config;
        this.statement = statement;
        this.bulkDataPartition = bulkDataPartition;
        this.partitionKey = partitionKey;

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * Runs the thread implementer.
     */
    @Override
    public final void run() {
        if (isDebug) {
            logger.debug("Start");
        }

        OraBench.runSelectHelper(statement, bulkDataPartition, partitionKey, config);

        if (isDebug) {
            logger.debug("End");
        }
    }
}
