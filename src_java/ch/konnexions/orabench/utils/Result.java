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
 * The class to record the results of the Oracle JDBC benchmark.
 */
public class Result {
    Config config;

    private final DecimalFormat decimalFormat = new DecimalFormat("##");
    private long durationInsertMaximum = 0;
    private long durationInsertMinimum = 0;
    private long durationInsertSum = 0;
    private long durationSelectMaximum = 0;
    private long durationSelectMinimum = 0;
    private long durationSelectSum = 0;

    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss.nnnnnnnnn");

    private final LocalDateTime lastBenchmark = LocalDateTime.now();
    private final long lastBenchmarkNano = System.nanoTime();
    private LocalDateTime lastQuery;
    private long lastQueryNano;
    private LocalDateTime lastTrial;
    private long lastTrialNano;
    private Logger log = new Logger(Result.class);

    private CSVPrinter resultFile;

    CSVPrinter summaryFile;

    /**
     * Constructs a Result object using the given {@link Config} object.
     *
     * @param config the {@link Config} object
     */
    public Result(Config config) {
        this.config = config;

        openResultFile();
    }

    private final void createMeasuringPoint(String action, LocalDateTime endDateTime, long duration) {
        createMeasuringPoint(action, 0, null, lastBenchmark, endDateTime, duration);

    }

    private final void createMeasuringPoint(String action, int trialNo, LocalDateTime startDateTime, LocalDateTime endDateTime, long duration) {
        createMeasuringPoint(action, trialNo, null, startDateTime, endDateTime, duration);
    }

    private final void createMeasuringPoint(String action, int trialNo, String sqlStatement, LocalDateTime startDateTime, LocalDateTime endDateTime,
            long duration) {
        try {
            resultFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkEnvironment(), config.getBenchmarkDatabase(), config.getBenchmarkModule(),
                    config.getBenchmarkDriver(), trialNo, sqlStatement, config.getConnectionPoolSize(), config.getBenchmarkTransactionSize(),
                    config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(), action, startDateTime.format(formatter),
                    endDateTime.format(formatter), decimalFormat.format(duration / 1000000000.0), Long.toString(duration));
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDetailedDelimiter());
            log.error("file result header   =: " + config.getFileResultDetailedHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    private final void createSummary(LocalDateTime endDateTime) {
        String startDateTimeStr = lastBenchmark.format(formatter);
        String endDateTimeStr = endDateTime.format(formatter);

        try {
            summaryFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkEnvironment(), config.getBenchmarkDatabase(), config.getBenchmarkModule(),
                    config.getBenchmarkDriver(), config.getBenchmarkTrials(), config.getSqlInsert(), config.getConnectionPoolSize(),
                    config.getBenchmarkTransactionSize(), config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(),
                    startDateTimeStr, endDateTimeStr, decimalFormat.format(durationInsertSum / (double) config.getBenchmarkTrials()),
                    decimalFormat.format((durationInsertSum / (double) config.getBenchmarkTrials()) / config.getFileBulkSize()),
                    Long.toString(durationInsertMinimum), Long.toString(durationInsertMaximum));
            summaryFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkEnvironment(), config.getBenchmarkDatabase(), config.getBenchmarkModule(),
                    config.getBenchmarkDriver(), config.getBenchmarkTrials(), config.getSqlSelect(), config.getConnectionPoolSize(),
                    config.getBenchmarkTransactionSize(), config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(),
                    startDateTimeStr, endDateTimeStr, decimalFormat.format(durationSelectSum / (double) config.getBenchmarkTrials()),
                    decimalFormat.format((durationSelectSum / (double) config.getBenchmarkTrials()) / config.getFileBulkSize()),
                    Long.toString(durationSelectMinimum), Long.toString(durationSelectMaximum));
        } catch (IOException e) {
            log.error("file summary delimiter=: " + config.getFileResultStatisticalDelimiter());
            log.error("file summary header   =: " + config.getFileResultStatisticalHeader());
            log.error("file summary name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    /**
     * End the benchmark.
     */
    public final void endBenchmark() {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastBenchmarkNano;

        createMeasuringPoint("benchmark", endDateTime, duration);

        try {
            resultFile.close();
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDetailedDelimiter());
            log.error("file result header   =: " + config.getFileResultDetailedHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

        openSummaryFile();

        createSummary(endDateTime);

        try {
            summaryFile.close();
        } catch (IOException e) {
            log.error("file summary delimiter=: " + config.getFileResultStatisticalDelimiter());
            log.error("file summary header   =: " + config.getFileResultStatisticalHeader());
            log.error("file summary name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

    }

    /**
     * End the current insert statement.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQueryInsert(int trialNo, String sqlStatement) {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        if (durationInsertSum == 0) {
            durationInsertMinimum = duration;
            durationInsertMaximum = duration;
        } else {
            if (duration < durationInsertMinimum) {
                durationInsertMinimum = duration;
            }
            if (duration > durationInsertMaximum) {
                durationInsertMaximum = duration;
            }
        }

        durationInsertSum += duration;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);
    }

    /**
     * End the current select.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQuerySelect(int trialNo, String sqlStatement) {
        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        if (durationSelectSum == 0) {
            durationSelectMinimum = duration;
            durationSelectMaximum = duration;
        } else {
            if (duration < durationSelectMinimum) {
                durationSelectMinimum = duration;
            }
            if (duration > durationSelectMaximum) {
                durationSelectMaximum = duration;
            }
        }

        durationSelectSum += duration;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);
    }

    /**
     * End the current trial.
     *
     * @param trialNo the current trial number
     */
    public final void endTrial(int trialNo) {
        createMeasuringPoint("trial", trialNo, lastTrial, LocalDateTime.now(), System.nanoTime() - lastTrialNano);
    }

    private final void openResultFile() {
        String resultDelimiter = config.getFileResultDetailedDelimiter();
        String resultName = config.getFileResultDetailedName();

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
                        CSVFormat.EXCEL.withDelimiter(resultDelimiter.charAt(0)).withHeader(config.getFileResultDetailedHeader().split(resultDelimiter)));
            }
        } catch (IOException e) {
            log.error("file result delimiter=: " + resultDelimiter);
            log.error("file result header   =: " + config.getFileResultDetailedHeader());
            log.error("file result name     =: " + resultName);
            log.error("-----------------------");
            e.printStackTrace();
        }
    }

    private final void openSummaryFile() {
        String summaryDelimiter = config.getFileResultStatisticalDelimiter();
        String summaryName = config.getFileResultStatisticalName();

        try {
            Path summaryPath = Paths.get(summaryName);

            boolean isFileExisting = Files.exists(Paths.get(summaryName));

            if (!(isFileExisting)) {
                Files.createFile(summaryPath);
            }

            BufferedWriter bufferedWriter;

            if (isFileExisting) {
                bufferedWriter = new BufferedWriter(new FileWriter(summaryName, true));
                summaryFile = new CSVPrinter(bufferedWriter, CSVFormat.EXCEL.withDelimiter(summaryDelimiter.charAt(0)));
            } else {
                bufferedWriter = new BufferedWriter(new FileWriter(summaryName, false));
                summaryFile = new CSVPrinter(bufferedWriter,
                        CSVFormat.EXCEL.withDelimiter(summaryDelimiter.charAt(0)).withHeader(config.getFileResultStatisticalHeader().split(summaryDelimiter)));
            }
        } catch (IOException e) {
            log.error("file summary delimiter=: " + summaryDelimiter);
            log.error("file summary header   =: " + config.getFileResultStatisticalHeader());
            log.error("file summary name     =: " + summaryName);
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
