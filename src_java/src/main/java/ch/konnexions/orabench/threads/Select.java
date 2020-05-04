/*
 * 
 */

package ch.konnexions.orabench.threads;

import java.sql.Statement;
import java.util.ArrayList;

import ch.konnexions.orabench.OraBench;
import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Logger;

public class Select implements Runnable {
    private final ArrayList<String[]> bulkDataPartition;

    private final Config config;

    private final Logger log;

    private final int partitionKey;

    private final Statement statement;

    /**
     * Instantiates a new Select class.
     *
     * @param config            the configuration parameters
     * @param log               the logger
     * @param statement         the statement
     * @param bulkDataPartition the bulk data partition
     * @param partitionKey      the partition key
     */
    public Select(Config config, Logger log, Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey) {
        this.config = config;
        this.log = log;
        this.statement = statement;
        this.bulkDataPartition = bulkDataPartition;
        this.partitionKey = partitionKey;
    }

    /**
     * Runs the thread implementer.
     */
    @Override
    public final void run() {
        OraBench.selectHelper(statement, bulkDataPartition, partitionKey, config, log);
    }

}
