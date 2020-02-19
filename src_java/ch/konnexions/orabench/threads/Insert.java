/*
 * 
 */

package ch.konnexions.orabench.threads;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.ArrayList;

import ch.konnexions.orabench.OraBench;
import ch.konnexions.orabench.utils.Config;

public class Insert implements Runnable {
    private final ArrayList<String[]> bulkDataPartition;

    private final Config config;
    private final Connection connection;

    private final PreparedStatement preparedStatement;

    /**
     * Instantiates a new Insert class.
     *
     * @param config            the configuration parameters
     * @param connection        the database connection
     * @param preparedStatement the prepared statement
     * @param bulkDataPartition the bulk data partition
     */
    public Insert(Config config, Connection connection, PreparedStatement preparedStatement, ArrayList<String[]> bulkDataPartition) {
        this.config = config;
        this.connection = connection;
        this.preparedStatement = preparedStatement;
        this.bulkDataPartition = bulkDataPartition;
    }

    /**
     * Runs the thread implementer.
     */
    @Override
    public final void run() {
        OraBench.insertHelper(connection, preparedStatement, bulkDataPartition, config);

    }

}
