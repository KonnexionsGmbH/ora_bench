/*
 * 
 */

package ch.konnexions.orabench.actions;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;

import ch.konnexions.orabench.utils.Config;

public class Insert implements Runnable {
    private ArrayList<String[]> bulkDataPartition;

    private Config config;
    private Connection connection;

    private PreparedStatement preparedStatement;

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
        int count = 0;

        try {
            for (String[] value : bulkDataPartition) {
                preparedStatement.setString(1, value[0]);
                preparedStatement.setString(2, value[1]);

                count += 1;

                if (config.getBenchmarkBatchSize() == 0) {
                    preparedStatement.execute();
                } else {
                    preparedStatement.addBatch();
                    if (count % config.getBenchmarkBatchSize() == 0) {
                        preparedStatement.executeBatch();
                    }
                }

                if ((config.getBenchmarkTransactionSize() > 0) && (count % config.getBenchmarkTransactionSize() == 0)) {
                    connection.commit();
                }
            }

            if ((config.getBenchmarkBatchSize() > 0) && (count % config.getBenchmarkBatchSize() != 0)) {
                preparedStatement.executeBatch();
            }

            if ((config.getBenchmarkTransactionSize() == 0) || (count % config.getBenchmarkTransactionSize() != 0)) {
                connection.commit();
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

}