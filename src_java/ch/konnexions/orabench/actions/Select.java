/*
 * 
 */

package ch.konnexions.orabench.actions;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;

import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Logger;

public class Select implements Runnable {
    private ArrayList<String[]> bulkDataPartition;

    private Config config;

    public Logger log;

    private int partitionKey;

    private Statement statement;

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
     * Run.
     */
    @Override
    public void run() {
        int count = 0;

        try {
            if (config.getConnectionFetchSize() > 0) {
                statement.setFetchSize(config.getConnectionFetchSize());
            }

            ResultSet resultSet = statement.executeQuery(config.getSqlSelect() + " WHERE partition_key = " + Integer.toString(partitionKey));

            while (resultSet.next()) {
                count += 1;
            }

            if (count != bulkDataPartition.size()) {
                log.error("Number rows: expected=" + Integer.toString(bulkDataPartition.size()) + " - found=" + Integer.toString(count));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

}