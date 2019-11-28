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

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;

import ch.konnexions.orabench.utils.Config;
import ch.konnexions.orabench.utils.Database;
import ch.konnexions.orabench.utils.Logger;
import ch.konnexions.orabench.utils.Result;
import ch.konnexions.orabench.utils.Setup;

/**
 * This class enables a simple benchmarking of the Oracle JDBC interface. The
 * data is written from a bulk file into a database table and then read again.
 * The write process is carried out with a prepared statement in batch mode. The
 * read process is also carried out with a PreparedStatement where the found
 * data is checked for plausibility..
 */
public class OraBench {

    private static final Config CONFIG = new Config();

    private static final Logger LOG = new Logger(OraBench.class);

    /**
     * Creates the database objects of type Connection, PreparedStatement, ResultSet
     * and Statement.
     *
     * @return the array list containing the database objects
     */
    private static ArrayList<Object> createDatabaseObjects() {
        ArrayList<Connection> connections = new ArrayList<Connection>(CONFIG.getBenchmarkNumberPartitions());
        ArrayList<PreparedStatement> preparedStatements = new ArrayList<PreparedStatement>(CONFIG.getBenchmarkNumberPartitions());
        ArrayList<Statement> statements = new ArrayList<Statement>(CONFIG.getBenchmarkNumberPartitions());

        Connection connection;
        Statement statement;

        for (int i = 0; i < CONFIG.getBenchmarkNumberPartitions(); i++) {
            Database database = new Database(CONFIG);

            try {
                connection = database.connect();
                connection.setAutoCommit(false);
                connections.add(connection);

                preparedStatements.add(connection.prepareStatement(CONFIG.getSqlInsert().replace(":key", "?").replace(":data", "?")));

                statement = connection.createStatement();
                statements.add(statement);
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }

        return new ArrayList<Object>(Arrays.asList(connections, preparedStatements, statements));
    }

    /**
     * Gets the bulk data.
     *
     * @return the bulk data
     */
    private static ArrayList<String[]> getBulkData() {
        ArrayList<String[]> bulkData = new ArrayList<String[]>(CONFIG.getFileBulkSize());

        try {
            BufferedReader bufferedReader = new BufferedReader(new FileReader(CONFIG.getFileBulkName()));
            Iterable<CSVRecord> records = CSVFormat.EXCEL.withDelimiter(CONFIG.getFileBulkDelimiter().charAt(0))
                    .withHeader(CONFIG.getFileBulkHeader().split(CONFIG.getFileBulkDelimiter())).parse(bufferedReader);

            for (CSVRecord record : records) {
                String keyValue = record.get("key");
                if (!(keyValue.equals("key"))) {
                    bulkData.add(new String[] { keyValue, record.get("data") });
                }
            }

            bufferedReader.close();

        } catch (IOException e) {
            e.printStackTrace();
        }

        return bulkData;
    }

    /**
     * This is the main method for the Oracle benchmark run. The operations to be
     * performed are determined with a command line argument:
     * <ul>
     * <li>setup - prepares the database and creates the bulk file
     * <li>runBenchmark - executes all database and driver-related activities of the
     * benchmark run
     * <li>finalise - resets the configuration file to its initial state
     * </ul>
     * 
     * @param args finalise / runBenchmark / setup
     */
    public static void main(String[] args) {

        LOG.info("Start OraBench.java");

        String args0 = null;
        if (args.length > 0) {
            args0 = args[0].toString();
        }

        LOG.info("args[0]=" + args0);

        if (args0.equals("finalise")) {
            LOG.info("Start Finalise Benchmark Run");
            new Config().resetNotAvailables();
            LOG.info("End   Finalise Benchmark Run");
        } else if (args0.equals("runBenchmark")) {
            LOG.info("Start Running Benchmark");
            runBenchmark();
            LOG.info("End   Running Benchmark");
        } else if (args0.equals("setup")) {
            LOG.info("Start Setup Benchmark Run");
            new Setup(CONFIG).createBulkFile();
            LOG.info("End   Setup Benchmark Run");
        } else if (args0.equals("setup_erlang")) {
            LOG.info("Start Setup Erlang Benchmark Run");
            CONFIG.createConfigurationFileOranifErlang();
            LOG.info("End   Setup Erlang Benchmark Run");
        } else if (args0.equals("setup_python")) {
            LOG.info("Start Setup Python Benchmark Run");
            CONFIG.createConfigurationFileCxOraclePython();
            LOG.info("End   Setup Python Benchmark Run");
        } else if (args0.contentEquals("")) {
            LOG.error("Command line argument missing");
        } else {
            LOG.error("Unknown command line argument");
        }

        LOG.info("End   OraBench.java");
    }

    /**
     * Run benchmark.
     */
    private static void runBenchmark() {
        int benchmarkTrials = CONFIG.getBenchmarkTrials();

        Result result = new Result(CONFIG);

        ArrayList<String[]> bulkData = getBulkData();

        ArrayList<Object> databaseObjects = createDatabaseObjects();

        @SuppressWarnings("unchecked")
        ArrayList<Connection> connections = (ArrayList<Connection>) databaseObjects.get(0);
        @SuppressWarnings("unchecked")
        ArrayList<PreparedStatement> preparedStatements = (ArrayList<PreparedStatement>) databaseObjects.get(1);
        @SuppressWarnings("unchecked")
        ArrayList<Statement> statements = (ArrayList<Statement>) databaseObjects.get(2);

        for (int i = 1; i <= benchmarkTrials; i++) {
            runBenchmarkTrial(connections, preparedStatements, statements, i, bulkData, result);
        }

        for (int i = 0; i < CONFIG.getBenchmarkNumberPartitions(); i++) {
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
     * Run benchmark INSERT: multiple connections and threads.
     *
     * @param connections        the database connections
     * @param preparedStatements the prepared statements
     * @param trialNumber        the trial number
     * @param bulkData           the bulk data
     * @param result             the result
     */
    private static void runBenchmarkInsert(ArrayList<Connection> connections, ArrayList<PreparedStatement> preparedStatements, int trialNumber,
            ArrayList<String[]> bulkData, Result result) {
        int count = 0;
        result.startQuery();

        try {
            for (String[] value : bulkData) {

                int partitionKey = (value[0].charAt(0) * 256 + value[0].charAt(1)) % CONFIG.getBenchmarkNumberPartitions();

                count += 1;

                runBenchmarkInsert(preparedStatements.get(partitionKey), count, value);

                if ((CONFIG.getBenchmarkTransactionSize() > 0) && (count % CONFIG.getBenchmarkTransactionSize() == 0)) {
                    connections.get(partitionKey).commit();
                }
            }

            for (int i = 0; i < CONFIG.getBenchmarkNumberPartitions(); i++) {
                if ((CONFIG.getBenchmarkBatchSize() > 0) && (count % CONFIG.getBenchmarkBatchSize() != 0)) {
                    preparedStatements.get(i).executeBatch();
                }

                if ((CONFIG.getBenchmarkTransactionSize() == 0) || (count % CONFIG.getBenchmarkTransactionSize() != 0)) {
                    connections.get(i).commit();
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQueryInsert(trialNumber, CONFIG.getSqlInsert());
    }

    /**
     * Run benchmark INSERT: single connection and thread.
     *
     * @param preparedStatement the prepared statement
     * @param count             the number of processed bulk data rows
     * @param bulkRow           the bulk data row
     */
    private static void runBenchmarkInsert(PreparedStatement preparedStatement, int count, String[] value) {

        try {
            preparedStatement.setString(1, value[0]);
            preparedStatement.setString(2, value[1]);

            if (CONFIG.getBenchmarkBatchSize() == 0) {
                preparedStatement.execute();
            } else {
                preparedStatement.addBatch();
                if (count % CONFIG.getBenchmarkBatchSize() == 0) {
                    preparedStatement.executeBatch();
                }

            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    /**
     * Run benchmark SELECT: multiple connections and threads.
     *
     * @param connections the database connections
     * @param statements  the statements
     * @param trialNumber the trial number
     * @param result      the result
     */
    private static void runBenchmarkSelect(ArrayList<Connection> connections, ArrayList<Statement> statements, int trialNumber, Result result) {
        int count = 0;
        result.startQuery();

        for (int i = 0; i < CONFIG.getBenchmarkNumberPartitions(); i++) {
            count += runBenchmarkSelect(statements.get(i), i);
        }

        if (count != CONFIG.getFileBulkSize()) {
            LOG.error("Number rows: expected=" + Integer.toString(CONFIG.getFileBulkSize()) + " - found=" + Integer.toString(count));
        }

        result.endQuerySelect(trialNumber, CONFIG.getSqlSelect());
    }

    /**
     * Run benchmark SELECT: single connection and thread.
     *
     * @param statement    the statement
     * @param threadNumber the thread number
     * 
     * @return the number of result rows
     */
    private static int runBenchmarkSelect(Statement statement, int threadNumber) {
        int count = 0;

        try {
            if (CONFIG.getConnectionFetchSize() > 0) {
                statement.setFetchSize(CONFIG.getConnectionFetchSize());
            }

            ResultSet resultSet = statement.executeQuery(CONFIG.getSqlSelect() + " WHERE partition_key = " + Integer.toString(threadNumber));

            while (resultSet.next()) {
                count += 1;
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return count;
    }

    /**
     * Run benchmark trial.
     *
     * @param connections        the database connections
     * @param statements         the statements
     * @param preparedStatements the prepared statements
     * @param trialNumber        the trial number
     * @param bulkData           the bulk data
     * @param result             the result
     */
    private static void runBenchmarkTrial(ArrayList<Connection> connections, ArrayList<PreparedStatement> preparedStatements, ArrayList<Statement> statements,
            int trialNumber, ArrayList<String[]> bulkData, Result result) {
        result.startTrial();

        LOG.info("Start trial no. " + Integer.toString(trialNumber));

        try {
            statements.get(0).executeUpdate(CONFIG.getSqlCreate());
            LOG.debug("last DDL statement=" + CONFIG.getSqlCreate());
        } catch (SQLException es1) {
            try {
                statements.get(0).executeUpdate(CONFIG.getSqlDrop());
                statements.get(0).executeUpdate(CONFIG.getSqlCreate());
                LOG.debug("last DDL statement after DROP=" + CONFIG.getSqlCreate());
            } catch (SQLException es2) {
                es2.printStackTrace();
            }
        }

        runBenchmarkInsert(connections, preparedStatements, trialNumber, bulkData, result);

        runBenchmarkSelect(connections, statements, trialNumber, result);

        try {
            statements.get(0).executeUpdate(CONFIG.getSqlDrop());
            LOG.debug("last DDL statement=" + CONFIG.getSqlDrop());
        } catch (SQLException es) {
            es.printStackTrace();
        }

        result.endTrial(trialNumber);
    }

}
