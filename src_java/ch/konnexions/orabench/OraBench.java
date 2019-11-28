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
     * Gets the database connections.
     *
     * @param database the database
     * @return the database connections
     */
    private static ArrayList<Connection> getConnections(Database database) {
        int numberConnections = (CONFIG.getBenchmarkCoreMultiplier() == 0) ? 1 : CONFIG.getBenchmarkNumberCoresNum();

        ArrayList<Connection> connections = new ArrayList<Connection>(numberConnections);

        for (int i = 0; i < numberConnections; i++) {
            Connection connection = database.connect();

            try {
                connection.setAutoCommit(false);
            } catch (SQLException e) {
                e.printStackTrace();
            }

            connections.add(connection);
        }

        return connections;
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

        Database database = new Database(CONFIG);

        ArrayList<Connection> connections = getConnections(database);

        for (int i = 1; i <= benchmarkTrials; i++) {
            runBenchmarkTrial(connections, i, bulkData, result);
        }

        database.disconnect();

        result.endBenchmark();
    }

    /**
     * Run benchmark INSERT: multiple connections and threads.
     *
     * @param connections the database connections
     * @param trialNumber the trial number
     * @param bulkData    the bulk data
     * @param result      the result
     */
    private static void runBenchmarkInsert(ArrayList<Connection> connections, int trialNumber, ArrayList<String[]> bulkData, Result result) {
        int count = 0;
        result.startQuery();

        try {
            PreparedStatement preparedStatement = connections.get(0).prepareStatement(CONFIG.getSqlInsert().replace(":key", "?").replace(":data", "?"));

            for (String[] value : bulkData) {
                preparedStatement.setString(1, value[0]);
                preparedStatement.setString(2, value[1]);

                count += 1;

                if (CONFIG.getBenchmarkBatchSize() == 0) {
                    preparedStatement.execute();
                } else {
                    preparedStatement.addBatch();
                    if (count % CONFIG.getBenchmarkBatchSize() == 0) {
                        preparedStatement.executeBatch();
                    }
                }

                if ((CONFIG.getBenchmarkTransactionSize() > 0) && (count % CONFIG.getBenchmarkTransactionSize() == 0)) {
                    connections.get(0).commit();
                }
            }

            if ((CONFIG.getBenchmarkBatchSize() > 0) && (count % CONFIG.getBenchmarkBatchSize() != 0)) {
                preparedStatement.executeBatch();
            }

            if ((CONFIG.getBenchmarkTransactionSize() == 0) || (count % CONFIG.getBenchmarkTransactionSize() != 0)) {
                connections.get(0).commit();
            }

            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQueryInsert(trialNumber, CONFIG.getSqlInsert());
    }

    /**
     * Run benchmark INSERT: single connection and thread.
     *
     * @param connection  the database connection
     * @param trialNumber the trial number
     * @param bulkData    the bulk data
     * @param result      the result
     */
    private static void runBenchmarkInsert(Connection connection, int trialNumber, ArrayList<String[]> bulkData, Result result) {
        int count = 0;
        result.startQuery();

        try {
            PreparedStatement preparedStatement = connection.prepareStatement(CONFIG.getSqlInsert().replace(":key", "?").replace(":data", "?"));

            for (String[] value : bulkData) {
                preparedStatement.setString(1, value[0]);
                preparedStatement.setString(2, value[1]);

                count += 1;

                if (CONFIG.getBenchmarkBatchSize() == 0) {
                    preparedStatement.execute();
                } else {
                    preparedStatement.addBatch();
                    if (count % CONFIG.getBenchmarkBatchSize() == 0) {
                        preparedStatement.executeBatch();
                    }
                }

                if ((CONFIG.getBenchmarkTransactionSize() > 0) && (count % CONFIG.getBenchmarkTransactionSize() == 0)) {
                    connection.commit();
                }
            }

            if ((CONFIG.getBenchmarkBatchSize() > 0) && (count % CONFIG.getBenchmarkBatchSize() != 0)) {
                preparedStatement.executeBatch();
            }

            if ((CONFIG.getBenchmarkTransactionSize() == 0) || (count % CONFIG.getBenchmarkTransactionSize() != 0)) {
                connection.commit();
            }

            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQueryInsert(trialNumber, CONFIG.getSqlInsert());
    }

    /**
     * Run benchmark SELECT: multiple connections and threads.
     *
     * @param connections the database connections
     * @param trialNumber the trial number
     * @param result      the result
     */
    private static void runBenchmarkSelect(ArrayList<Connection> connections, int trialNumber, Result result) {
        int count = 0;
        result.startQuery();

        for (int i = 0; i < CONFIG.getBenchmarkNumberCoresNum(); i++) {
            count += runBenchmarkSelectThread(connections.get(i), trialNumber, i, result);
        }

        if (count != CONFIG.getFileBulkSize()) {
            LOG.error("Number rows: expected=" + Integer.toString(CONFIG.getFileBulkSize()) + " - found=" + Integer.toString(count));
        }

        result.endQuerySelect(trialNumber, CONFIG.getSqlSelect());
    }

    /**
     * Run benchmark SELECT: single connection and thread.
     *
     * @param connection  the database connection
     * @param trialNumber the trial number
     * @param result      the result
     */
    private static void runBenchmarkSelect(Connection connection, int trialNumber, Result result) {
        int count = 0;
        result.startQuery();

        try {
            Statement statement = connection.createStatement();

            if (CONFIG.getConnectionFetchSize() > 0) {
                statement.setFetchSize(CONFIG.getConnectionFetchSize());
            }

            ResultSet resultSet = statement.executeQuery(CONFIG.getSqlSelect());

            while (resultSet.next()) {
                count += 1;
            }

            if (count != CONFIG.getFileBulkSize()) {
                LOG.error("Number rows: expected=" + Integer.toString(CONFIG.getFileBulkSize()) + " - found=" + Integer.toString(count));
            }

            resultSet.close();
            statement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQuerySelect(trialNumber, CONFIG.getSqlSelect());
    }

    /**
     * Run benchmark SELECT: single connection and thread.
     *
     * @param connection   the database connection
     * @param trialNumber  the trial number
     * @param threadNumber the thread number
     * @param result       the result
     * @return the number of result rows
     */
    private static int runBenchmarkSelectThread(Connection connection, int trialNumber, int threadNumber, Result result) {
        int count = 0;

        try {
            Statement statement = connection.createStatement();

            if (CONFIG.getConnectionFetchSize() > 0) {
                statement.setFetchSize(CONFIG.getConnectionFetchSize());
            }

            ResultSet resultSet = statement.executeQuery(CONFIG.getSqlSelect() + " WHERE partition_key = " + Integer.toString(threadNumber));

            while (resultSet.next()) {
                count += 1;
            }

            if (count != CONFIG.getFileBulkSize()) {
                LOG.error("Number rows: expected=" + Integer.toString(CONFIG.getFileBulkSize()) + " - found=" + Integer.toString(count));
            }

            resultSet.close();
            statement.close();

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return count;
    }

    /**
     * Run benchmark trial.
     *
     * @param connections the database connections
     * @param trialNumber the trial number
     * @param bulkData    the bulk data
     * @param result      the result
     */
    private static void runBenchmarkTrial(ArrayList<Connection> connections, int trialNumber, ArrayList<String[]> bulkData, Result result) {
        result.startTrial();

        LOG.info("Start trial no. " + Integer.toString(trialNumber));

        Statement statement = null;

        try {
            statement = connections.get(0).createStatement();
            statement.executeUpdate(CONFIG.getSqlCreate());
            LOG.debug("last DDL statement=" + CONFIG.getSqlCreate());
        } catch (SQLException es1) {
            try {
                statement.executeUpdate(CONFIG.getSqlDrop());
                statement.executeUpdate(CONFIG.getSqlCreate());
                LOG.debug("last DDL statement after DROP=" + CONFIG.getSqlCreate());
            } catch (SQLException es2) {
                es2.printStackTrace();
            }
        }

        if (CONFIG.getBenchmarkCoreMultiplier() == 0) {
            runBenchmarkInsert(connections.get(0), trialNumber, bulkData, result);
            runBenchmarkSelect(connections.get(0), trialNumber, result);
        } else {
            runBenchmarkInsert(connections, trialNumber, bulkData, result);
            runBenchmarkSelect(connections, trialNumber, result);
        }

        try {
            statement.executeUpdate(CONFIG.getSqlDrop());
            LOG.debug("last DDL statement=" + CONFIG.getSqlDrop());
            statement.close();
        } catch (SQLException es) {
            es.printStackTrace();
        }

        result.endTrial(trialNumber);
    }

}
