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
import org.apache.commons.math3.util.Precision;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import ch.konnexions.orabench.threads.Insert;
import ch.konnexions.orabench.threads.Select;
import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Database;
import ch.konnexions.orabench.utils.Result;
import ch.konnexions.orabench.utils.Setup;

/**
 * The Class OraBench.
 */
public class OraBench {

  private static final Logger  logger          = LogManager.getLogger(OraBench.class);

  private final static boolean isDebug         = logger.isDebugEnabled();
  private final Config         config          = new Config();
  private ExecutorService      executorService = null;
  private final int            noThreads       = Runtime.getRuntime().availableProcessors();

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
   * <li>setup_python - creates a configuration parameter file suited for Python 3
   * </ul>
   *
   * @param args finalise / runBenchmark / setup / setup_erlang / setup_python /
   *             setup_json
   */
  public static void main(String[] args) {
    if (isDebug) {
      logger.debug("Start");
    }

    System.out.println("Start OraBench.java");

    int numberArgs = args.length;

    System.out.println("main() - number arguments=" + numberArgs);

    if (numberArgs == 0) {
      logger.error("main() - no command line argument available");
    }

    System.out.println("main() - 1st argument=" + args[0]);

    if (numberArgs > 1) {
      System.out.println("main() - 2nd argument=" + args[1]);
      logger.error("main() - more than one command line argument available");
    }

    // READ the configuration parameters into the memory (config params
    // `file.configuration.name ...`)
    final Config config = new Config();

    if (args[0].equals("finalise")) {
      System.out.println("Start Finalise OraBench Run");
      new Config().resetNotAvailables();
      System.out.println("End   Finalise OraBench Run");
    } else if (args[0].equals("runBenchmark")) {
      System.out.println("Start Running OraBench");
      new OraBench().runBenchmark();
      System.out.println("End   Running OraBench");
    } else if (args[0].equals("setup")) {
      System.out.println("Start Setup OraBench Run");
      new Setup(config).createBulkFile();
      System.out.println("End   Setup OraBench Run");
    } else if (args[0].equals("setup_c")) {
      System.out.println("Start Setup ODPI-C OraBench Run");
      config.createConfigurationFileC();
      System.out.println("End   Setup ODPI-C OraBench Run");
    } else if (args[0].equals("setup_default")) {
      System.out.println("Start Setup Properties OraBench Run");
      System.out.println("End   Setup Properties OraBench Run");
    } else if (args[0].equals("setup_elixir")) {
      System.out.println("Start Setup Elixir OraBench Run");
      new Config();
      System.out.println("End   Setup Elixir OraBench Run");
    } else if (args[0].equals("setup_erlang")) {
      System.out.println("Start Setup Erlang OraBench Run");
      config.createConfigurationFileErlang();
      System.out.println("End   Setup Erlang OraBench Run");
    } else if (args[0].equals("setup_json")) {
      System.out.println("Start Setup JSON OraBench Run");
      config.createConfigurationFileJson();
      System.out.println("End   Setup Erlang OraBench Run");
    } else if (args[0].equals("setup_python")) {
      System.out.println("Start Setup Python 3 OraBench Run");
      config.createConfigurationFilePython();
      System.out.println("End   Setup Python 3 OraBench Run");
    } else if (args[0].equals("setup_toml")) {
      System.out.println("Start Setup TOML OraBench Run");
      config.createConfigurationFileToml();
      System.out.println("End   Setup TOML OraBench Run");
    } else if (args[0].equals("setup_yaml")) {
      System.out.println("Start Setup YAML OraBench Run");
      config.createConfigurationFileYaml();
      System.out.println("End   Setup YAML OraBench Run");
    } else if (args[0].contentEquals("")) {
      logger.error("Command line argument missing");
    } else {
      logger.error("Unknown command line argument");
    }

    System.out.println("End   OraBench.java");

    if (isDebug) {
      logger.debug("End");
    }

    System.exit(0);
  }

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

    int                            numberPartitions     = config.getBenchmarkNumberPartitions();
    int                            expectedBulkDataSize = config.getFileBulkSize() / numberPartitions;

    for (int i = 0; i < numberPartitions; i++) {
      bulkDataPartitions.add(new ArrayList<>(expectedBulkDataSize));
    }

    try {
      BufferedReader      bufferedReader = new BufferedReader(new FileReader(config.getFileBulkName()));
      Iterable<CSVRecord> records        = CSVFormat.EXCEL.builder().setDelimiter(config.getFileBulkDelimiter().charAt(0)).setHeader(config.getFileBulkHeader()
          .split(config.getFileBulkDelimiter())).build().parse(bufferedReader);

      int                 partitionKey;

      for (CSVRecord record : records) {
        String keyValue = record.get("key");
        if (!(keyValue.equals("key"))) {
          /*
           * partition key = modulo (ASCII value of 1st byte of key 
           *                       * 251 
           *                       + ASCII value of 2nd byte of key), 
           *                         number partitions (config param
           * 'benchmark.number.partitions')
           */
          partitionKey = (keyValue.charAt(0) * 251 + keyValue.charAt(1)) % numberPartitions;
          bulkDataPartitions.get(partitionKey).add(new String[] {
              keyValue,
              record.get("data") });
        }
      }

      bufferedReader.close();

      System.out.println("Start Distribution of the data in the partitions");

      for (int i = 0; i < numberPartitions; i++) {
        System.out.println("Partition p" + String.format("%05d",
                                                         i) + " contains " + String.format("%9d",
                                                                                           bulkDataPartitions.get(i).size()) + " rows");
      }

      System.out.println("End   Distribution of the data in the partitions");

    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }

    return bulkDataPartitions;
  }

  /**
   * Performing a complete benchmark run that can consist of several trial runs.
   */
  private void runBenchmark() {
    if (isDebug) {
      logger.debug("Start");
    }

    if (config.getBenchmarkCoreMultiplier() > 0) {
      System.out.println("Available threads=" + noThreads);
    }

    // save the current time as the start time of the 'benchmark' action
    Result                         result             = new Result(config);

    int                            benchmarkTrials    = config.getBenchmarkTrials();

    // READ the bulk file data into the partitioned collection bulk_data_partitions
    // (config param 'file.bulk.name')
    ArrayList<ArrayList<String[]>> bulkDataPartitions = getBulkDataPartitions();

    // create a separate database connection (without auto commit behaviour) for
    // each partition
    ArrayList<Object>              databaseObjects    = createDatabaseObjects();

    @SuppressWarnings("unchecked")
    ArrayList<Connection>          connections        = (ArrayList<Connection>) databaseObjects.get(0);
    @SuppressWarnings("unchecked")
    ArrayList<PreparedStatement>   preparedStatements = (ArrayList<PreparedStatement>) databaseObjects.get(1);
    @SuppressWarnings("unchecked")
    ArrayList<Statement>           statements         = (ArrayList<Statement>) databaseObjects.get(2);

    /*
     * trial_max = 0 
     * trial_min = 0 
     * trial_no = 0 
     * trial_sum = 0 
     * WHILE trial_no < config_param 'benchmark.trials' 
     *       duration_trial = DO run_trial(database connections, 
     *                                     trial_no, 
     *                                     bulk_data_partitions) 
     *       IF trial_max == 0 OR duration_trial > trial_max 
     *          trial_max = duration_trial 
     *       END IF 
     *       IF trial_min == 0 OR duration_trial < trial_min 
     *          trial_min = duration_trial 
     *       END IF 
     *       trial_sum + duration_trial 
     * ENDWHILE
     */
    long                           maxTrialNano       = 0L;
    long                           minTrialNano       = 0L;
    long                           sumTrialNano       = 0L;

    for (int i = 1; i <= benchmarkTrials; i++) {
      long durationTrial = runTrial(connections,
                                    preparedStatements,
                                    statements,
                                    i,
                                    bulkDataPartitions,
                                    result);

      if ((maxTrialNano == 0) || (maxTrialNano < durationTrial)) {
        maxTrialNano = durationTrial;
      }

      if ((minTrialNano == 0) || (minTrialNano > durationTrial)) {
        minTrialNano = durationTrial;
      }

      sumTrialNano += durationTrial;
    }

    /*
     * partition_key = 0 
     * WHILE partition_key < config_param 'benchmark.number.partitions' 
     *       close the database connection 
     * ENDWHILE
     */
    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      try {
        preparedStatements.get(i).close();
        statements.get(i).close();
        connections.get(i).close();
      } catch (SQLException e) {
        e.printStackTrace();
      }
    }

    // WRITE an entry for the action 'benchmark' in the result file (config param
    // 'file.result.name')
    long durationBenchmark = result.endBenchmark(benchmarkTrials);

    // INFO Duration (ms) trial min. : trial_min
    // INFO Duration (ms) trial max. : trial_max
    // INFO Duration (ms) trial average : trial_sum / config_param
    // 'benchmark.trials'
    System.out.println("Duration (ms) trial min.    : " + (long) Precision.round(minTrialNano / 1000000.0,
                                                                                 0));
    System.out.println("Duration (ms) trial max.    : " + (long) Precision.round(maxTrialNano / 1000000.0,
                                                                                 0));
    System.out.println("Duration (ms) trial average : " + (long) Precision.round(sumTrialNano / 1000000.0 / benchmarkTrials,
                                                                                 0));

    // INFO Duration (ms) benchmark run : duration_benchmark
    System.out.println("Duration (ms) benchmark run : " + (long) Precision.round(durationBenchmark / 1000000.0,
                                                                                 0));

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Supervise function for inserting data into the database.
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

    // save the current time as the start time of the 'query' action
    result.startQuery();

    /*
     * partition_key = 0 
     * WHILE partition_key < config_param 'benchmark.number.partitions' 
     *       IF config_param 'benchmark.core.multiplier' == 0
     *          DO run_insert_helper(database connections(partition_key),
     *                               bulk_data_partitions(partition_key), 
     *                               partition_key) 
     *       ELSE 
     *          DO run_insert_helper(database connections(partition_key),
     *                               bulk_data_partitions(partition_key), 
     *                               partition_key) as a thread 
     *       ENDIF
     * ENDWHILE
     */
    if (config.getBenchmarkCoreMultiplier() > 0) {
      executorService = Executors.newFixedThreadPool(noThreads);
    }

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      if (config.getBenchmarkCoreMultiplier() == 0) {
        runInsertHelper(connections.get(i),
                        preparedStatements.get(i),
                        bulkDataPartitions.get(i),
                        i,
                        trialNumber,
                        config);
      } else {
        executorService.execute(new Insert(config, connections.get(i), preparedStatements.get(i), bulkDataPartitions.get(i), i, trialNumber));
      }
    }

    if (config.getBenchmarkCoreMultiplier() > 0) {
      executorService.shutdown();
      try {
        while (!executorService.awaitTermination(1,
                                                 TimeUnit.SECONDS)) {
          ;
        }
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }

    // WRITE an entry for the action 'query' in the result file (config param
    // 'file.result.name')
    result.endQueryInsert(trialNumber,
                          config.getSqlInsert());

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Helper function for inserting data into the database.
   *
   * @param connection        the database connection
   * @param preparedStatement the prepared statement
   * @param bulkDataPartition the bulk data partition
   * @param partitionKey      the partition key
   * @param trialNumber       the trial number
   * @param config            the configuration parameters
   */
  public static void runInsertHelper(Connection connection,
                                     PreparedStatement preparedStatement,
                                     ArrayList<String[]> bulkDataPartition,
                                     int partitionKey,
                                     int trialNumber,
                                     Config config) {
    if (isDebug) {
      logger.debug("Start - threadName=" + Thread.currentThread().getName());
    }

    /*
     *  IF trial_no == 1
     *     INFO Start insert partition_key=partition_key
     *  ENDIF
     */
    if (trialNumber == 1) {
      System.out.println("Start insert partitionKey=" + partitionKey);
    }

    try {
      /*
       * count = 0 
       * collection batch_collection = empty 
       * WHILE iterating through the collection bulk_data_partition 
       *       count + 1
       * 
       *       add the SQL statement in config param 'sql.insert' with the current bulk_data entry to the collection batch_collection
       * 
       *       IF config_param 'benchmark.batch.size' > 0 
       *          IF count modulo config param 'benchmark.batch.size' == 0 
       *             execute the SQL statements in the collection batch_collection 
       *             batch_collection = empty 
       *          ENDIF
       *       ENDIF
       * 
       *       IF config param 'benchmark.transaction.size' > 0 AND count modulo config param 'benchmark.transaction.size' == 0 
       *          commit
       *       ENDIF 
       * ENDWHILE
       */
      int count = 0;

      for (String[] value : bulkDataPartition) {
        preparedStatement.setString(1,
                                    value[0]);
        preparedStatement.setString(2,
                                    value[1]);

        count += 1;

        if (config.getBenchmarkBatchSize() == 1) {
          preparedStatement.execute();
        } else {
          preparedStatement.addBatch();
          if (config.getBenchmarkBatchSize() != 0 && count % config.getBenchmarkBatchSize() == 0) {
            preparedStatement.executeBatch();
          }
        }

        if ((config.getBenchmarkTransactionSize() > 0) && (count % config.getBenchmarkTransactionSize() == 0)) {
          connection.commit();
        }
      }

      /*
       * IF collection batch_collection is not empty 
       *    execute the SQL statements in the collection batch_collection 
       * ENDIF
       */
      if ((config.getBenchmarkBatchSize() == 0) || (count % config.getBenchmarkBatchSize() != 0)) {
        preparedStatement.executeBatch();
      }

      // commit
      connection.commit();
    } catch (SQLException e) {
      e.printStackTrace();
    }

    /*
     *  IF trial_no == 1
     *     INFO End   insert partition_key=partition_key
     *  ENDIF
     */
    if (trialNumber == 1) {
      System.out.println("End   insert partitionKey=" + partitionKey);
    }

    if (isDebug) {
      logger.debug("End   - threadName=" + Thread.currentThread().getName());
    }
  }

  /**
   * Supervise function for retrieving of the database data.
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

    // save the current time as the start time of the 'query' action
    result.startQuery();

    /*
     * partition_key = 0 
     * WHILE partition_key < config_param 'benchmark.number.partitions' 
     *       IF config_param 'benchmark.core.multiplier' == 0
     *          DO run_select_helper(database connections(partition_key),
     *                               bulk_data_partitions(partition_key, 
     *                               partition_key) 
     *       ELSE 
     *          DO run_select_helper(database connections(partition_key),
     *                               bulk_data_partitions(partition_key, 
     *                               partition_key) as a thread 
     *       ENDIF 
     * ENDWHILE
     */
    if (config.getBenchmarkCoreMultiplier() > 0) {
      executorService = Executors.newFixedThreadPool(noThreads);
    }

    for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
      if (config.getBenchmarkCoreMultiplier() == 0) {
        runSelectHelper(statements.get(i),
                        bulkDataPartitions.get(i),
                        i,
                        trialNumber,
                        config);
      } else {
        executorService.execute(new Select(config, statements.get(i), bulkDataPartitions.get(i), i, trialNumber));
      }
    }

    if (config.getBenchmarkCoreMultiplier() > 0) {
      executorService.shutdown();
      try {
        while (!executorService.awaitTermination(1,
                                                 TimeUnit.SECONDS)) {
          ;
        }
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }

    // WRITE an entry for the action 'query' in the result file (config param
    // 'file.result.name')
    result.endQuerySelect(trialNumber,
                          config.getSqlSelect());

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Helper function for retrieving data from the database.
   *
   * @param statement         the statement
   * @param bulkDataPartition the bulk data partition
   * @param partitionKey      the partition key
   * @param trialNumber       the trial number 
   * @param config            the config
   */
  public static void runSelectHelper(Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey, int trialNumber, Config config) {
    if (isDebug) {
      logger.debug("Start - threadName=" + Thread.currentThread().getName());
    }

    /*
     *  IF trial_no == 1
     *     INFO Start select partition_key=partition_key
     *  ENDIF
     */
    if (trialNumber == 1) {
      System.out.println("Start select partitionKey=" + partitionKey);
    }

    try {
      if (config.getConnectionFetchSize() > 0) {
        statement.setFetchSize(config.getConnectionFetchSize());
      }

      // execute the SQL statement in config param 'sql.select'
      ResultSet resultSet = statement.executeQuery(config.getSqlSelect() + " WHERE partition_key = " + partitionKey);

      /*
       * count = 0 
       * WHILE iterating through the result set 
       *       count + 1 
       * ENDWHILE
       */
      int       count     = 0;

      while (resultSet.next()) {
        count += 1;
      }

      /*
       * IF NOT count = size(bulk_data_partition) 
       *    display an error message 
       * ENDIF
       */
      if (count != bulkDataPartition.size()) {
        logger.error("Number rows: expected=" + bulkDataPartition.size() + " - found=" + count);
      }

    } catch (SQLException e) {
      e.printStackTrace();
    }

    /*
     *  IF trial_no == 1
     *     INFO End   select partition_key=partition_key
     *  ENDIF
     */
    if (trialNumber == 1) {
      System.out.println("End   select partitionKey=" + partitionKey);
    }

    if (isDebug) {
      logger.debug("End   - threadName=" + Thread.currentThread().getName());
    }
  }

  /**
   * Performing a single trial run.
   *
   * @param connections        the database connections
   * @param preparedStatements the prepared statements
   * @param statements         the statements
   * @param trialNumber        the trial number
   * @param bulkDataPartitions the bulk data partitioned
   * @param result             the result
   * @return duration (nanoseconds)
   */
  private long runTrial(ArrayList<Connection> connections,
                        ArrayList<PreparedStatement> preparedStatements,
                        ArrayList<Statement> statements,
                        int trialNumber,
                        ArrayList<ArrayList<String[]>> bulkDataPartitions,
                        Result result) {
    if (isDebug) {
      logger.debug("Start");
    }

    // save the current time as the start time of the 'trial' action
    result.startTrial();

    // INFO  Start trial no. trial_no
    System.out.println("Start trial no. " + trialNumber);

    /*
     * create the database table (config param 'sql.create') 
     * IF error 
     *    drop the database table (config param 'sql.drop') 
     *    create the database table (config param 'sql.create') 
     * ENDIF
     */
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

    /*
     * DO run_benchmark_insert(database connections, trial_no, bulk_data_partitions)
     */
    runInsert(connections,
              preparedStatements,
              trialNumber,
              bulkDataPartitions,
              result);

    /*
     * DO run_benchmark_select(database connections, 
     *                         trial_no, 
     *                         bulk_data_partitions)
     */
    runSelect(statements,
              trialNumber,
              bulkDataPartitions,
              result);

    // drop the database table (config param 'sql.drop')
    try {
      statements.get(0).executeUpdate(config.getSqlDrop());
      if (isDebug) {
        logger.debug("last DDL statement=" + config.getSqlDrop());
      }
    } catch (SQLException es) {
      es.printStackTrace();
    }

    // WRITE an entry for the action 'trial' in the result file (config param
    // 'file.result.name')
    long duration = result.endTrial(trialNumber);

    if (isDebug) {
      logger.debug("End");
    }

    return duration;
  }
}
