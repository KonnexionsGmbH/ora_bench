/*
 * 
 */

package ch.konnexions.orabench.threads;

import java.sql.Statement;
import java.util.ArrayList;

import org.apache.log4j.Logger;

import ch.konnexions.orabench.OraBench;
import ch.konnexions.orabench.utils.Config;

// TODO: Auto-generated Javadoc
/**
 * The Class Select.
 */
public class Select implements Runnable {
  private static final Logger       logger  = Logger.getLogger(Select.class);

  private final static boolean      isDebug = logger.isDebugEnabled();

  private final ArrayList<String[]> bulkDataPartition;

  private final Config              config;

  private final int                 partitionKey;

  private final Statement           statement;

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

    this.config            = config;
    this.statement         = statement;
    this.bulkDataPartition = bulkDataPartition;
    this.partitionKey      = partitionKey;

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

    OraBench.selectHelper(statement,
                          bulkDataPartition,
                          partitionKey,
                          config);

    if (isDebug) {
      logger.debug("End");
    }
  }
}
