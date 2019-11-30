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

import ch.konnexions.orabench.threads.Insert;
import ch.konnexions.orabench.threads.Select;
import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Database;
import ch.konnexions.orabench.utils.Logger;
import ch.konnexions.orabench.utils.Result;
import ch.konnexions.orabench.utils.Setup;

public class OraBench {

    /**
     * This is the main method for the Oracle benchmark run. The operations to be
     * performed are determined with a command line argument:
     * <ul>
     * <li>finalise - resets the configuration file to its initial state
     * <li>runBenchmark - executes all database and driver-related activities of the
     * benchmark run
     * <li>setup - creates the bulk file
     * <li>setup_erlang - creates a configuration parameter file suited for Erlang
     * <li>setup_python - creates a configuration parameter file suited for Python
     * </ul>
     * 
     * @param args finalise / runBenchmark / setup / setup_erlang / setup_python
     */
    public static void main(String[] args) {

        final Config config = new Config();

        final Logger log = new Logger(OraBench.class);

        log.info("Start OraBench.java");

        String args0 = null;
        if (args.length > 0) {
            args0 = args[0].toString();
        }

        log.info("args[0]=" + args0);

        if (args0.equals("finalise")) {
            log.info("Start Finalise OraBench Run");
            new Config().resetNotAvailables();
            log.info("End   Finalise OraBench Run");
        } else if (args0.equals("runBenchmark")) {
            log.info("Start Running OraBench");
            new OraBench().runBenchmark();
            log.info("End   Running OraBench");
        } else if (args0.equals("setup")) {
            log.info("Start Setup OraBench Run");
            new Setup(config).createBulkFile();
            log.info("End   Setup OraBench Run");
        } else if (args0.equals("setup_erlang")) {
            log.info("Start Setup Erlang OraBench Run");
            config.createConfigurationFileOranifErlang();
            log.info("End   Setup Erlang OraBench Run");
        } else if (args0.equals("setup_python")) {
            log.info("Start Setup Python OraBench Run");
            config.createConfigurationFileCxOraclePython();
            log.info("End   Setup Python OraBench Run");
        } else if (args0.contentEquals("")) {
            log.error("Command line argument missing");
        } else {
            log.error("Unknown command line argument");
        }

        log.info("End   OraBench.java");
    }

    private final Config config = new Config();

    private ExecutorService executorService = null;

    private final Logger log = new Logger(OraBench.class);

    /**
     * Creates the database objects of type Connection, PreparedStatement, ResultSet
     * and Statement.
     *
     * @return the array list containing the database objects of the classes
     *         Connection, PreparedStatement and Statement
     */
    private final ArrayList<Object> createDatabaseObjects() {
        ArrayList<Connection> connections = new ArrayList<Connection>(config.getBenchmarkNumberPartitions());
        ArrayList<PreparedStatement> preparedStatements = new ArrayList<PreparedStatement>(config.getBenchmarkNumberPartitions());
        ArrayList<Statement> statements = new ArrayList<Statement>(config.getBenchmarkNumberPartitions());

        Connection connection;
        Statement statement;

        for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
            Database database = new Database(config);

            try {
                connection = database.connect();
                connection.setAutoCommit(false);
                connections.add(connection);

                preparedStatements.add(connection.prepareStatement(config.getSqlInsert().replace(":key", "?").replace(":data", "?")));

                statement = connection.createStatement();
                statements.add(statement);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return new ArrayList<Object>(Arrays.asList(connections, preparedStatements, statements));
    }

    /**
     * Gets the bulk data partitioned.
     *
     * @return the bulk data partitioned
     */
    private final ArrayList<ArrayList<String[]>> getBulkDataPartitions() {
        ArrayList<ArrayList<String[]>> bulkDataPartitions = new ArrayList<ArrayList<String[]>>(config.getBenchmarkNumberPartitions());

        int expectedBulkDataSize = config.getFileBulkSize() / config.getBenchmarkNumberPartitions();

        for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
            bulkDataPartitions.add(new ArrayList<String[]>(expectedBulkDataSize));
        }

        try {
            BufferedReader bufferedReader = new BufferedReader(new FileReader(config.getFileBulkName()));
            Iterable<CSVRecord> records = CSVFormat.EXCEL.withDelimiter(config.getFileBulkDelimiter().charAt(0))
                    .withHeader(config.getFileBulkHeader().split(config.getFileBulkDelimiter())).parse(bufferedReader);

            int partitonKey;

            for (CSVRecord record : records) {
                String keyValue = record.get("key");
                if (!(keyValue.equals("key"))) {
                    partitonKey = (keyValue.charAt(0) * 256 + keyValue.charAt(1)) % config.getBenchmarkNumberPartitions();
                    bulkDataPartitions.get(partitonKey).add(new String[] { keyValue, record.get("data") });
                }
            }

            bufferedReader.close();

            log.info("Start Distribution of the data in the partitions");

            for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
                log.info("Partition p" + String.format("%05d", i) + " contains " + String.format("%9d", bulkDataPartitions.get(i).size()) + " rows");
            }

            log.info("End   Distribution of the data in the partitions");

        } catch (IOException e) {
            e.printStackTrace();
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
    private final void insert(Connection connection, PreparedStatement preparedStatement, ArrayList<String[]> bulkDataPartition) {
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

    /**
     * Run a benchmark.
     */
    public final void runBenchmark() {
        int benchmarkTrials = config.getBenchmarkTrials();

        Result result = new Result(config);

        ArrayList<ArrayList<String[]>> bulkDataPartitions = getBulkDataPartitions();

        ArrayList<Object> databaseObjects = createDatabaseObjects();

        @SuppressWarnings("unchecked")
        ArrayList<Connection> connections = (ArrayList<Connection>) databaseObjects.get(0);
        @SuppressWarnings("unchecked")
        ArrayList<PreparedStatement> preparedStatements = (ArrayList<PreparedStatement>) databaseObjects.get(1);
        @SuppressWarnings("unchecked")
        ArrayList<Statement> statements = (ArrayList<Statement>) databaseObjects.get(2);

        for (int i = 1; i <= benchmarkTrials; i++) {
            runTrial(connections, preparedStatements, statements, i, bulkDataPartitions, result);
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
    private final void runInsert(ArrayList<Connection> connections, ArrayList<PreparedStatement> preparedStatements, int trialNumber,
            ArrayList<ArrayList<String[]>> bulkDataPartitions, Result result) {
        result.startQuery();

        if (config.getBenchmarkCoreMultiplier() != 0) {
            executorService = Executors.newFixedThreadPool(config.getBenchmarkNumberPartitions());
        }

        for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
            if (config.getBenchmarkCoreMultiplier() == 0) {
                insert(connections.get(i), preparedStatements.get(i), bulkDataPartitions.get(i));
            } else {
                executorService.execute(new Insert(config, connections.get(i), preparedStatements.get(i), bulkDataPartitions.get(i)));
            }
        }

        if (config.getBenchmarkCoreMultiplier() != 0) {
            executorService.shutdown();
            try {
                while (!executorService.awaitTermination(1, TimeUnit.SECONDS)) {
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        result.endQueryInsert(trialNumber, config.getSqlInsert());
    }

    /**
     * Run SELECT: multiple connections and eventually multiple threads.
     *
     * @param connections        the database connections
     * @param statements         the statements
     * @param trialNumber        the trial number
     * @param bulkDataPartitions the bulk data partitioned
     * @param result             the result
     */
    private final void runSelect(ArrayList<Connection> connections, ArrayList<Statement> statements, int trialNumber,
            ArrayList<ArrayList<String[]>> bulkDataPartitions, Result result) {
        result.startQuery();

        if (config.getBenchmarkCoreMultiplier() != 0) {
            executorService = Executors.newFixedThreadPool(config.getBenchmarkNumberPartitions());
        }

        for (int i = 0; i < config.getBenchmarkNumberPartitions(); i++) {
            if (config.getBenchmarkCoreMultiplier() == 0) {
                select(statements.get(i), bulkDataPartitions.get(i), i);
            } else {
                executorService.execute(new Select(config, log, statements.get(i), bulkDataPartitions.get(i), i));
            }
        }

        if (config.getBenchmarkCoreMultiplier() != 0) {
            executorService.shutdown();
            try {
                while (!executorService.awaitTermination(1, TimeUnit.SECONDS)) {
                }
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        result.endQuerySelect(trialNumber, config.getSqlSelect());
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
    private final void runTrial(ArrayList<Connection> connections, ArrayList<PreparedStatement> preparedStatements, ArrayList<Statement> statements,
            int trialNumber, ArrayList<ArrayList<String[]>> bulkDataPartitions, Result result) {
        result.startTrial();

        log.info("Start trial no. " + Integer.toString(trialNumber));

        try {
            statements.get(0).executeUpdate(config.getSqlCreate());
            log.info("last DDL statement=" + config.getSqlCreate());
        } catch (SQLException es1) {
            try {
                statements.get(0).executeUpdate(config.getSqlDrop());
                statements.get(0).executeUpdate(config.getSqlCreate());
                log.info("last DDL statement after DROP=" + config.getSqlCreate());
            } catch (SQLException es2) {
                es2.printStackTrace();
            }
        }

        runInsert(connections, preparedStatements, trialNumber, bulkDataPartitions, result);

        runSelect(connections, statements, trialNumber, bulkDataPartitions, result);

        try {
            statements.get(0).executeUpdate(config.getSqlDrop());
            log.info("last DDL statement=" + config.getSqlDrop());
        } catch (SQLException es) {
            es.printStackTrace();
        }

        result.endTrial(trialNumber);
    }

    /**
     * SELECT: single connection and thread.
     *
     * @param statement         the statement
     * @param bulkDataPartition the bulk data partition
     * @param partitionKey      the partition key
     */
    private final void select(Statement statement, ArrayList<String[]> bulkDataPartition, int partitionKey) {
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
