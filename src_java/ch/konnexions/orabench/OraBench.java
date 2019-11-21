/*
 * Licensed to the Konnexions GmbH under one or more contributor license
 * agreements.  The Konnexions GmbH licenses this file to You under the
 * Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain a copy of the
 * License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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

    private static Config config;

    private static Logger log = new Logger(OraBench.class);

    private static Result result;

    private static ArrayList<String[]> getBulkData() {
        ArrayList<String[]> bulkData = new ArrayList<String[]>(config.getFileBulkSize());

        try {
            BufferedReader bufferedReader = new BufferedReader(new FileReader(config.getFileBulkName()));
            Iterable<CSVRecord> records = CSVFormat.EXCEL.withDelimiter(config.getFileBulkDelimiter().charAt(0))
                    .withHeader(config.getFileBulkHeader().split(config.getFileBulkDelimiter())).parse(bufferedReader);

            for (CSVRecord record : records) {
                bulkData.add(new String[] { record.get("key"), record.get("data") });
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

        log.info("Start OraBench.java");

        String args0 = null;
        if (args.length > 0) {
            args0 = args[0].toString();
        }

        log.info("args[0]=" + args0);

        if (args0.equals("setup")) {
            log.info("Start Setup Benchmark Run");
            config = new Config();
            config.createConfigurationFileCxOraclePython();
            config.createConfigurationFileOranifC();
            config.createConfigurationFileOranifErlang();
            new Setup(config).createBulkFile();
            log.info("End   Setup Benchmark Run");
        } else if (args0.equals("runBenchmark")) {
            log.info("Start Running Benchmark");
            config = new Config();
            runBenchmark();
            log.info("End   Running Benchmark");
        } else if (args0.equals("finalise")) {
            log.info("Start Finalise Benchmark Run");
            new Config().resetNotAvailables();
            log.info("End   Finalise Benchmark Run");
        } else if (args0.contentEquals("")) {
            log.error("Command line argument missing");
        } else {
            log.error("Unknown command line argument");
        }

        log.info("End   OraBench.java");
    }

    private static void runBenchmark() {
        int benchmarkTrials = config.getBenchmarkTrials();

        result = new Result(config);

        ArrayList<String[]> bulkData = getBulkData();

        Database database = new Database(config);

        Connection connection = database.connect();

        try {
            connection.setAutoCommit(false);
        } catch (SQLException e) {
            e.printStackTrace();
        }

        for (int i = 1; i <= benchmarkTrials; i++) {
            runBenchmarkTrial(connection, i, bulkData);
        }

        database.disconnect();

        result.endBenchmark();
    }

    private static void runBenchmarkInsert(Connection connection, int trialNumber, ArrayList<String[]> bulkData, String sqlStatement, int batchSize,
            int transactionSize) {
        int count = 0;
        result.startQuery();

        try {
            PreparedStatement preparedStatement = connection.prepareStatement(sqlStatement.replace(":key", "?").replace(":data", "?"));

            for (String[] value : bulkData) {
                preparedStatement.setString(1, value[0]);
                preparedStatement.setString(2, value[1]);

                count += 1;

                if (batchSize == 0) {
                    preparedStatement.execute();
                } else {
                    preparedStatement.addBatch();
                    if (count % batchSize == 0) {
                        preparedStatement.executeBatch();
                    }
                }

                if ((transactionSize > 0) && (count % transactionSize == 0)) {
                    connection.commit();
                }
            }

            if ((batchSize > 0) && (count % batchSize != 0)) {
                preparedStatement.executeBatch();
            }

            if ((transactionSize > 0) && (count % transactionSize != 0)) {
                connection.commit();
            }

            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQueryInsert(trialNumber, sqlStatement);
    }

    private static void runBenchmarkSelect(Connection connection, int trialNumber, ArrayList<String[]> bulkData, String sqlStatement, int connectionFetchSize) {
        result.startQuery();

        try {
            PreparedStatement preparedStatement = connection.prepareStatement(sqlStatement.replace(":key", "?"));

            if (connectionFetchSize > 0) {
                preparedStatement.setFetchSize(connectionFetchSize);
            }

            ResultSet resultSet = null;

            for (String[] value : bulkData) {
                preparedStatement.setString(1, value[0]);

                resultSet = preparedStatement.executeQuery();

                String foundValue = null;

                while (resultSet.next()) {
                    foundValue = resultSet.getString(1);
                }

                if (!(value[1].equals(foundValue))) {
                    log.error("expected=" + value[1]);
                    log.error("found   =" + foundValue);
                }
            }

            resultSet.close();
            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQuerySelect(trialNumber, sqlStatement);
    }

    private static void runBenchmarkTrial(Connection connection, int trialNumber, ArrayList<String[]> bulkData) {
        result.startTrial();

        log.info("Start trial no. " + Integer.toString(trialNumber));

        Statement statement = null;

        try {
            statement = connection.createStatement();
            statement.executeUpdate(config.getSqlCreateTable());
        } catch (SQLException es1) {
            try {
                statement.executeUpdate(config.getSqlDropTable());
                statement.executeUpdate(config.getSqlCreateTable());
            } catch (SQLException es2) {
                es2.printStackTrace();
            }
        }

        runBenchmarkInsert(connection, trialNumber, bulkData, config.getSqlInsert(), config.getBenchmarkBatchSize(), config.getBenchmarkTransactionSize());

        runBenchmarkSelect(connection, trialNumber, bulkData, config.getSqlSelect(), config.getConnectionFetchSize());

        try {
            statement.executeUpdate(config.getSqlDropTable());
            statement.close();
        } catch (SQLException es) {
            es.printStackTrace();
        }

        result.endTrial(trialNumber);
    }

}
