/*
 * 
 */

package ch.konnexions.orabench;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;
import org.apache.log4j.Logger;

import ch.konnexions.orabench.threads.Insert;
import ch.konnexions.orabench.threads.Select;
import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Database;
import ch.konnexions.orabench.utils.Result;
import ch.konnexions.orabench.utils.Setup;

public class OraBench {

  private static final Logger  logger  = Logger.getLogger(OraBench.class);

  private final static boolean isDebug = logger.isDebugEnabled();

  public static void insertHelper(Connection connection, PreparedStatement preparedStatement, ArrayList<String[]> bulkDataPartition, Config config) {
    if (isDebug) {
      logger.debug("Start");
    }

    int count = 0;

    try {
      for (String[] value : bulkDataPartition) {
        preparedStatement.setString(1,
                                    value[0]);
        preparedStatement.setString(2,
                                    value[1]);

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

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * This is the main method for the Oracle benchmark run. The operations to be
   * performed are determined with a command line argument:
   * <ul>
   * <li>finalise - resets the configuration file to its initial state
   * <li>runBenchmark - executes all database and driver-related activities of the
   * benchmark run
   * <li>setup - creates the bulk file
   * <li>setup_erlang - creates a configuration parameter file suited for Erlang
   * <li>setup_json - creates a JSON configuration parameter file
   * <li>setup_python - creates a configuration parameter file suited for Python
   * </ul>
   * 
   * @param args finalise / runBenchmark / setup / setup_erlang / setup_python / setup_json
   */
  public static void main(String[] args) {
    if (isDebug) {
      logger.debug("Start");
    }

    final Config config = new Config();

    logger.info("Start OraBench.java");

    String args0 = null;
    if (args.length > 0) {
      args0 = args[0];
    }

    logger.info("args[0]=" + args0);

    if (null == args0) {
      logger.error("Command line argument missing");
    } else if (args0.equals("finalise")) {
      logger.info("Start Finalise OraBench Run");
      new Config().resetNotAvailables();
      logger.info("End   Finalise OraBench Run");
    } else if (args0.equals("runBenchmark")) {
      logger.info("Start Running OraBench");
      new OraBench().runBenchmark();
      logger.info("End   Running OraBench");
    } else if (args0.equals("setup")) {
      logger.info("Start Setup OraBench Run");
      new Setup(config).createBulkFile();
      logger.info("End   Setup OraBench Run");
    } else if (args0.equals("setup_c")) {
      logger.info("Start Setup ODPI-C OraBench Run");
      config.createConfigurationFileC();
      logger.info("End   Setup ODPI-C OraBench Run");
    } else if (args0.equals("setup_elixir")) {
      logger.info("Start Setup Elixir OraBench Run");
      new Config();
      logger.info("End   Setup Elixir OraBench Run");
    } else if (args0.equals("setup_erlang")) {
      logger.info("Start Setup Erlang OraBench Run");
      config.createConfigurationFileErlang();
      logger.info("End   Setup Erlang OraBench Run");
    } else if (args0.equals("setup_json")) {
      logger.info("Start Setup JSON OraBench Run");
      config.createConfigurationFileJson();
      logger.info("End   Setup Erlang OraBench Run");
    } else if (args0.equals("setup_python")) {
      logger.info("Start Setup Python OraBench Run");
      config.createConfigurationFilePython();
      logger.info("End   Setup Python OraBench Run");
    } else if (args0.contentEquals("")) {
      logger.error("Command line argument missing");
    } else {
      logger.error("Unknown command line argument");
    }

    logger.info("End   OraBench.java");

    if (isDebug) {
      logger.debug("End");
    }

    System.exit(0);
  }

  public static void selectHelper(Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey, Config config) {
    if (isDebug) {
      logger.debug("Start");
    }

    int count = 0;

    try {
      if (config.getConnectionFetchSize() > 0) {
        statement.setFetchSize(config.getConnectionFetchSize());
      }

      ResultSet resultSet = statement.executeQuery(config.getSqlSelect() + " WHERE partition_key = " + partitionKey);

      while (resultSet.next()) {
        count += 1;
      }

      if (count != bulkDataPartition.size()) {
        logger.error("Number rows: expected=" + bulkDataPartition.size() + " - found=" + count);
      }

    } catch (SQLException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  private final Config    config          = new Config();

  private ExecutorService executorService = null;

  /**
   * Creates the database objects of type Connection, PreparedStatement, ResultSet
   * and Statement.
   *
   * @return the array list containing the database objects of the classes
   *         Connection, PreparedStatement and Statement
   */
  private ArrayList<Object> createDatabaseObjects() {
    if (isDebug) {
      logger.debug("Start");
    }

    ArrayList<Connection>        connections        = new ArrayList<>(config.getBenchmarkNumberPartitions());
    ArrayList<PreparedStatement> preparedStatements = new ArrayList<>(config.getBenchmarkNumberPartitions());
    ArrayList<Statement>         statements         = new ArrayList<>(config.getBenchmarkNumberPartitions());

    Connection                   connection;

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      Database database = new Database(config);

      try {
        connection = database.connect();
        connection.setAutoCommit(false);
        connections.add(connection);

        preparedStatements.add(connection.prepareStatement(config.getSqlInsert().replace(":key",
                                                                                         "?").replace(":data",
                                                                                                      "?")));

        statements.add(connection.createStatement());
      } catch (SQLException e) {
        e.printStackTrace();
      }
    }

    if (isDebug) {
      logger.debug("End");
    }

    return new ArrayList<>(Arrays.asList(connections,
                                         preparedStatements,
                                         statements));
  }

  /**
   * Gets the bulk data partitioned.
   *
   * @return the bulk data partitioned
   */
  private ArrayList<ArrayList<String[]>> getBulkDataPartitions() {
    if (isDebug) {
      logger.debug("Start");
    }

    ArrayList<ArrayList<String[]>> bulkDataPartitions   = new ArrayList<>(config.getBenchmarkNumberPartitions());

    int                            expectedBulkDataSize = config.getFileBulkSize() / config.getBenchmarkNumberPartitions();

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      bulkDataPartitions.add(new ArrayList<>(expectedBulkDataSize));
    }

    try {
      BufferedReader      bufferedReader = new BufferedReader(new FileReader(config.getFileBulkName()));
      Iterable<CSVRecord> records        = CSVFormat.EXCEL.withDelimiter(config.getFileBulkDelimiter().charAt(0)).withHeader(config.getFileBulkHeader().split(
                                                                                                                                                              config
                                                                                                                                                                  .getFileBulkDelimiter()))
          .parse(bufferedReader);

      int                 partitionKey;

      for (CSVRecord record : records) {
        String keyValue = record.get("key");
        if (!(keyValue.equals("key"))) {
          partitionKey = (keyValue.charAt(0) * 256 + keyValue.charAt(1)) % config.getBenchmarkNumberPartitions();
          bulkDataPartitions.get(partitionKey).add(new String[] {
              keyValue,
              record.get("data") });
        }
      }

      bufferedReader.close();

      logger.info("Start Distribution of the data in the partitions");

      for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
        logger.info("Partition p" + String.format("%05d",
                                                  i) + " contains " + String.format("%9d",
                                                                                    bulkDataPartitions.get(i).size()) + " rows");
      }

      logger.info("End   Distribution of the data in the partitions");

    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }

    return bulkDataPartitions;
  }

  /**
   * INSERT: single connection and thread.
   *
   * @param connection        the database connection
   * @param preparedStatement the prepared statement
   * @param bulkDataPartition the bulk data partition
   */
  private void insert(Connection connection, PreparedStatement preparedStatement, ArrayList<String[]> bulkDataPartition) {
    if (isDebug) {
      logger.debug("Start");
    }

    insertHelper(connection,
                 preparedStatement,
                 bulkDataPartition,
                 config);

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Run a benchmark.
   */
  private final void runBenchmark() {
    if (isDebug) {
      logger.debug("Start");
    }

    int                            benchmarkTrials    = config.getBenchmarkTrials();

    Result                         result             = new Result(config);

    ArrayList<ArrayList<String[]>> bulkDataPartitions = getBulkDataPartitions();

    ArrayList<Object>              databaseObjects    = createDatabaseObjects();

    @SuppressWarnings("unchecked")
    ArrayList<Connection>          connections        = (ArrayList<Connection>) databaseObjects.get(0);
    @SuppressWarnings("unchecked")
    ArrayList<PreparedStatement>   preparedStatements = (ArrayList<PreparedStatement>) databaseObjects.get(1);
    @SuppressWarnings("unchecked")
    ArrayList<Statement>           statements         = (ArrayList<Statement>) databaseObjects.get(2);

    for (int i = 1; i <= benchmarkTrials; i++) {
      runTrial(connections,
               preparedStatements,
               statements,
               i,
               bulkDataPartitions,
               result);
    }

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      try {
        preparedStatements.get(i).close();
        statements.get(i).close();
        connections.get(i).close();
      } catch (SQLException e) {
        e.printStackTrace();
      }
    }

    result.endBenchmark();

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Run INSERT: multiple connections and eventually multiple threads.
   *
   * @param connections        the database connections
   * @param preparedStatements the prepared statements
   * @param trialNumber        the trial number
   * @param bulkDataPartitions the bulk data partitioned
   * @param result             the result
   */
  private void runInsert(ArrayList<Connection> connections,
                         ArrayList<PreparedStatement> preparedStatements,
                         int trialNumber,
                         ArrayList<ArrayList<String[]>> bulkDataPartitions,
                         Result result) {
    if (isDebug) {
      logger.debug("Start");
    }

    result.startQuery();

    if (config.getBenchmarkCoreMultiplier() != 0) {
      executorService = Executors.newFixedThreadPool(config.getBenchmarkNumberPartitions());
    }

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      if (config.getBenchmarkCoreMultiplier() == 0) {
        insert(connections.get(i),
               preparedStatements.get(i),
               bulkDataPartitions.get(i));
      } else {
        executorService.execute(new Insert(config, connections.get(i), preparedStatements.get(i), bulkDataPartitions.get(i)));
      }
    }

    if (config.getBenchmarkCoreMultiplier() != 0) {
      executorService.shutdown();
      try {
        while (!executorService.awaitTermination(1,
                                                 TimeUnit.SECONDS)) {
        }
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }

    result.endQueryInsert(trialNumber,
                          config.getSqlInsert());

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Run SELECT: multiple connections and eventually multiple threads.
   *
   * @param statements         the statements
   * @param trialNumber        the trial number
   * @param bulkDataPartitions the bulk data partitioned
   * @param result             the result
   */
  private void runSelect(ArrayList<Statement> statements, int trialNumber, ArrayList<ArrayList<String[]>> bulkDataPartitions, Result result) {
    if (isDebug) {
      logger.debug("Start");
    }

    result.startQuery();

    if (config.getBenchmarkCoreMultiplier() != 0) {
      executorService = Executors.newFixedThreadPool(config.getBenchmarkNumberPartitions());
    }

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      if (config.getBenchmarkCoreMultiplier() == 0) {
        select(statements.get(i),
               bulkDataPartitions.get(i),
               i);
      } else {
        executorService.execute(new Select(config, statements.get(i), bulkDataPartitions.get(i), i));
      }
    }

    if (config.getBenchmarkCoreMultiplier() != 0) {
      executorService.shutdown();
      try {
        while (!executorService.awaitTermination(1,
                                                 TimeUnit.SECONDS)) {
        }
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }

    result.endQuerySelect(trialNumber,
                          config.getSqlSelect());

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Run a trial.
   *
   * @param connections        the database connections
   * @param statements         the statements
   * @param preparedStatements the prepared statements
   * @param trialNumber        the trial number
   * @param bulkDataPartitions the bulk data partitioned
   * @param result             the result
   */
  private void runTrial(ArrayList<Connection> connections,
                        ArrayList<PreparedStatement> preparedStatements,
                        ArrayList<Statement> statements,
                        int trialNumber,
                        ArrayList<ArrayList<String[]>> bulkDataPartitions,
                        Result result) {
    if (isDebug) {
      logger.debug("Start");
    }

    result.startTrial();

    logger.info("Start trial no. " + trialNumber);

    try {
      statements.get(0).executeUpdate(config.getSqlCreate());
      if (isDebug) {
        logger.debug("last DDL statement=" + config.getSqlCreate());
      }
    } catch (SQLException es1) {
      try {
        statements.get(0).executeUpdate(config.getSqlDrop());
        statements.get(0).executeUpdate(config.getSqlCreate());
        if (isDebug) {
          logger.debug("last DDL statement after DROP=" + config.getSqlCreate());
        }
      } catch (SQLException es2) {
        es2.printStackTrace();
      }
    }

    runInsert(connections,
              preparedStatements,
              trialNumber,
              bulkDataPartitions,
              result);

    runSelect(statements,
              trialNumber,
              bulkDataPartitions,
              result);

    try {
      statements.get(0).executeUpdate(config.getSqlDrop());
      if (isDebug) {
        logger.debug("last DDL statement=" + config.getSqlDrop());
      }
    } catch (SQLException es) {
      es.printStackTrace();
    }

    result.endTrial(trialNumber);

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * SELECT: single connection and thread.
   *
   * @param statement         the statement
   * @param bulkDataPartition the bulk data partition
   * @param partitionKey      the partition key
   */
  private void select(Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey) {
    if (isDebug) {
      logger.debug("Start");
    }

    selectHelper(statement,
                 bulkDataPartition,
                 partitionKey,
                 config);

    if (isDebug) {
      logger.debug("End");
    }
  }

}
