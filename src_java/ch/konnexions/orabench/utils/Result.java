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

package ch.konnexions.orabench.utils;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

/**
 * This class is used to record the results of the Oracle JDBC benchmark.
 */
public class Result {
    final Config config;

    private final DecimalFormat decimalFormat = new DecimalFormat("#########");

    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn");

    private final LocalDateTime lastBenchmark = LocalDateTime.now();
    private final long lastBenchmarkNano = System.nanoTime();
    private LocalDateTime lastQuery;
    private long lastQueryNano;
    private LocalDateTime lastTrial;
    private long lastTrialNano;
    private final Logger log = new Logger(Result.class);

    private CSVPrinter resultFile;

    /**
     * Constructs a Result object using the given {@link Config} object.
     *
     * @param config the {@link Config} object
     */
    public Result(Config config) {
        this.config = config;

        openResultFile();
    }

    private void createMeasuringPoint(LocalDateTime endDateTime, long duration) {
        createMeasuringPoint("benchmark", 0, null, lastBenchmark, endDateTime, duration);

    }

    private void createMeasuringPoint(int trialNo, LocalDateTime startDateTime, LocalDateTime endDateTime, long duration) {
        createMeasuringPoint("trial", trialNo, null, startDateTime, endDateTime, duration);
    }

    private void createMeasuringPoint(String action, int trialNo, String sqlStatement, LocalDateTime startDateTime, LocalDateTime endDateTime, long duration) {
        try {
            resultFile.printRecord(config.getBenchmarkRelease(), config.getBenchmarkId(), config.getBenchmarkComment(), config.getBenchmarkHostName(),
                    config.getBenchmarkNumberCores(), config.getBenchmarkOs(), config.getBenchmarkUserName(), config.getBenchmarkDatabase(),
                    config.getBenchmarkLanguage(), config.getBenchmarkDriver(), trialNo, sqlStatement, config.getBenchmarkCoreMultiplier(),
                    config.getConnectionFetchSize(), config.getBenchmarkTransactionSize(), config.getFileBulkLength(), config.getFileBulkSize(),
                    config.getBenchmarkBatchSize(), action, startDateTime.format(formatter), endDateTime.format(formatter),
                    decimalFormat.format(Math.round(duration / 1000000000.0)), Long.toString(duration));
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDelimiter());
            log.error("file result header   =: " + config.getFileResultHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    /**
     * End of the whole benchmark run.
     */
    public final void endBenchmark() {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastBenchmarkNano;

        createMeasuringPoint(endDateTime, duration);

        try {
            resultFile.close();
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDelimiter());
            log.error("file result header   =: " + config.getFileResultHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    /**
     * End of the current insert statement.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQueryInsert(int trialNo, String sqlStatement) {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);
    }

    /**
     * End of the current select.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQuerySelect(int trialNo, String sqlStatement) {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);
    }

    /**
     * End of the current trial.
     *
     * @param trialNo the current trial number
     */
    public final void endTrial(int trialNo) {
        createMeasuringPoint(trialNo, lastTrial, LocalDateTime.now(), System.nanoTime() - lastTrialNano);
    }

    private void openResultFile() {
        String resultDelimiter = config.getFileResultDelimiter();
        String resultName = config.getFileResultName();

        try {
            Path resultPath = Paths.get(resultName);

            boolean isFileExisting = Files.exists(Paths.get(resultName));

            if (!(isFileExisting)) {
                Files.createFile(resultPath);
            }

            BufferedWriter bufferedWriter;

            if (isFileExisting) {
                bufferedWriter = new BufferedWriter(new FileWriter(resultName, true));
                resultFile = new CSVPrinter(bufferedWriter, CSVFormat.EXCEL.withDelimiter(resultDelimiter.charAt(0)));
            } else {
                bufferedWriter = new BufferedWriter(new FileWriter(resultName, false));
                resultFile = new CSVPrinter(bufferedWriter,
                        CSVFormat.EXCEL.withDelimiter(resultDelimiter.charAt(0)).withHeader(config.getFileResultHeader().split(resultDelimiter)));
            }
        } catch (IOException e) {
            log.error("file result delimiter=: " + resultDelimiter);
            log.error("file result header   =: " + config.getFileResultHeader());
            log.error("file result name     =: " + resultName);
            log.error("-----------------------");
            e.printStackTrace();
        }
    }

    /**
     * Start a new query.
     */
    public final void startQuery() {
        lastQuery = LocalDateTime.now();
        lastQueryNano = System.nanoTime();
    }

    /**
     * Start a new trial.
     */
    public final void startTrial() {
        lastTrial = LocalDateTime.now();
        lastTrialNano = System.nanoTime();
    }

}
