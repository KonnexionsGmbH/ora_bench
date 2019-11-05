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
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.util.ArrayList;

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

    private static final File FILE_ORA_BENCH_CONFIG = new File("priv/ora_bench.properties");

    private static Logger log = new Logger(OraBench.class);

    private static Result result;

    private static ArrayList<String> getBulkdata() {
        ArrayList<String> bulkData = new ArrayList<String>(config.getFileBulkSize());

        try {
            BufferedReader bufferedReader = new BufferedReader(new FileReader(config.getFileBulkName()));

            String currLine;

            while ((currLine = bufferedReader.readLine()) != null) {
                bulkData.add(currLine);
            }

            bufferedReader.close();

        } catch (IOException e) {
            e.printStackTrace();
        }

        return bulkData;
    }

    /**
     * This is the main method which Depending on the command line argument
     * provided, creates either a bulk file or performs a benchmark run.
     *
     * @param args createBulkfile / runBenchmark
     */
    public static void main(String[] args) {

        log.info("Start Oracle JDBC Benchmark");

        String args0 = null;
        if (args.length > 0) {
            args0 = args[0].toString();
        }
        log.info("args[0]=" + args0);

        config = new Config(FILE_ORA_BENCH_CONFIG);

        if (args0.equals("createBulkFile")) {
            log.info("Start Creating BulkFile");
            new Setup(new Config(FILE_ORA_BENCH_CONFIG)).createBulkFile();
            log.info("End   Creating BulkFile");
        } else if (args0.equals("runBenchmark")) {
            log.info("Start Running Benchmark");
            OraBench.runBenchmark();
            log.info("End   Running Benchmark");
        } else if (args0.contentEquals("")) {
            log.error("Command line argument missing");
        } else {
            log.error("Unknown command line argument");
        }

        log.info("End   Oracle JDBC Benchmark");
    }

    private static void runBenchmark() {
        int benchmarkTrials = config.getBenchmarkTrials();

        result = new Result(config);

        ArrayList<String> bulkData = getBulkdata();

        Database database = new Database(config);

        Connection connection = database.connect();

        for (int i = 1; i <= benchmarkTrials; i++) {
            runBenchmarkTrial(connection, i, bulkData);
        }

        database.disconnect();

        result.endBenchmark(LocalDateTime.now());
    }

    private static void runBenchmarkInsert(Connection connection, int trialNumber, ArrayList<String> bulkData, String sqlStatement) {
        result.startQuery(LocalDateTime.now());

        try {
            PreparedStatement preparedStatement = connection.prepareStatement(sqlStatement.replace(":item", "?"));

            for (String value : bulkData) {
                preparedStatement.setString(1, value);
                preparedStatement.addBatch();
            }

            preparedStatement.executeBatch();
            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQuery(LocalDateTime.now(), trialNumber, sqlStatement);
    }

    private static void runBenchmarkSelect(Connection connection, int trialNumber, ArrayList<String> bulkData, String sqlStatement) {
        result.startQuery(LocalDateTime.now());

        try {
            PreparedStatement preparedStatement = connection.prepareStatement(sqlStatement.replace(":item", "?"));
            ResultSet resultSet = null;

            for (String value : bulkData) {
                preparedStatement.setString(1, value);
                resultSet = preparedStatement.executeQuery();

                String foundValue = null;

                while (resultSet.next()) {
                    foundValue = resultSet.getString(1);
                }

                if (!(value.equals(foundValue))) {
                    log.error("expected=" + value);
                    log.error("found   =" + foundValue);
                }
            }

            resultSet.close();
            preparedStatement.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }

        result.endQuery(LocalDateTime.now(), trialNumber, sqlStatement);
    }

    private static void runBenchmarkTrial(Connection connection, int trialNumber, ArrayList<String> bulkData) {
        result.startTrial(LocalDateTime.now());

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

        runBenchmarkInsert(connection, trialNumber, bulkData, config.getSqlInsertOracle());

        runBenchmarkSelect(connection, trialNumber, bulkData, config.getSqlSelect());

        try {
            statement.executeUpdate(config.getSqlDropTable());
            statement.close();
        } catch (SQLException es) {
            es.printStackTrace();
        }

        result.endTrial(LocalDateTime.now(), trialNumber);
    }

}
