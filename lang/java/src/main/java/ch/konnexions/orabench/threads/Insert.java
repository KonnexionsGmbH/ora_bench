/*
 *
 */

package ch.konnexions.orabench.threads;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.util.ArrayList;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import ch.konnexions.orabench.OraBench;
import ch.konnexions.orabench.utils.Config;

// TODO: Auto-generated Javadoc

/**
 * The Class Insert.
 */
public class Insert implements Runnable {
  private static final Logger       logger  = LogManager.getLogger(Insert.class);

  private final static boolean      isDebug = logger.isDebugEnabled();
  private final ArrayList<String[]> bulkDataPartition;

  private final Config              config;

  private final Connection          connection;

  private final int                 partitionKey;

  private final PreparedStatement   preparedStatement;

  private final int                 trialNumber;

  /**
   * Instantiates a new Insert class.
   *
   * @param config            the configuration parameters
   * @param connection        the database connection
   * @param preparedStatement the prepared statement
   * @param bulkDataPartition the bulk data partition
   * @param partitionKey      the partition key
   * @param trialNumber       the trial number
   */
  public Insert(Config config,
                Connection connection,
                PreparedStatement preparedStatement,
                ArrayList<String[]> bulkDataPartition,
                int partitionKey,
                int trialNumber) {
    if (isDebug) {
      logger.debug("Start");
    }

    this.config            = config;
    this.connection        = connection;
    this.preparedStatement = preparedStatement;
    this.bulkDataPartition = bulkDataPartition;
    this.partitionKey      = partitionKey;
    this.trialNumber       = trialNumber;

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

    OraBench.runInsertHelper(connection,
                             preparedStatement,
                             bulkDataPartition,
                             partitionKey,
                             trialNumber,
                             config);

    if (isDebug) {
      logger.debug("End");
    }
  }
}
