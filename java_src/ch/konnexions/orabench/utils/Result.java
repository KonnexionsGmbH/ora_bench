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
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;

/**
 * The class to record the results of the Oracle JDBC benchmark.
 */
public class Result {
    Config config;

    private int durationInsertMaximum = 0;
    private int durationInsertMinimum = 0;
    private long durationInsertSum = 0;
    private int durationSelectMaximum = 0;
    private int durationSelectMinimum = 0;
    private long durationSelectSum = 0;

    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss.nnnnnnnnn");

    private final String interfaceName = "Oracle JDBC";

    private LocalDateTime lastBenchmark;
    private LocalDateTime lastQuery;
    private LocalDateTime lastTrial;
    private Logger log = new Logger(Result.class);

    private String moduleName = "OraBench.java";

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

        startBenchmark(LocalDateTime.now());
    }

    private void createMeasuringPoint(String action, int trialNo, LocalDateTime startDateTime, LocalDateTime endDateTime) {
        createMeasuringPoint(action, trialNo, null, startDateTime, endDateTime, Duration.between(lastTrial, endDateTime).getNano());
    }

    private void createMeasuringPoint(String action, int trialNo, String sqlStatement, LocalDateTime startDateTime, LocalDateTime endDateTime, int duration) {
        try {
            resultFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkDatabase(), moduleName, interfaceName, trialNo, sqlStatement,
                    config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(), action, startDateTime.format(formatter),
                    endDateTime.format(formatter), Integer.toString(duration));
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDelimiter());
            log.error("file result header   =: " + config.getFileResultHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    private void createMeasuringPoint(String action, LocalDateTime startDateTime, LocalDateTime endDateTime) {
        createMeasuringPoint(action, 0, null, startDateTime, endDateTime, Duration.between(lastTrial, endDateTime).getNano());

    }

    private void createSummary(LocalDateTime endDateTime) {
        String startDateTimeStr = lastBenchmark.format(formatter);
        String endDateTimeStr = endDateTime.format(formatter);

        try {
            summaryFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkDatabase(), moduleName, interfaceName, config.getSqlInsertOracle(),
                    config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(), config.getBenchmarkTrials(), startDateTimeStr,
                    endDateTimeStr, Integer.toString((int) (durationInsertSum / config.getBenchmarkTrials())),
                    Integer.toString((int) (durationInsertSum / config.getBenchmarkTrials()) / config.getFileBulkSize()),
                    Integer.toString(durationInsertMinimum), Integer.toString(durationInsertMaximum));
            summaryFile.printRecord(config.getBenchmarkComment(), config.getBenchmarkDatabase(), moduleName, interfaceName, config.getSqlSelect(),
                    config.getFileBulkLength(), config.getFileBulkSize(), config.getBenchmarkBatchSize(), config.getBenchmarkTrials(), startDateTimeStr,
                    endDateTimeStr, Integer.toString((int) (durationSelectSum / config.getBenchmarkTrials())),
                    Integer.toString((int) (durationSelectSum / config.getBenchmarkTrials()) / config.getFileBulkSize()),
                    Integer.toString(durationSelectMinimum), Integer.toString(durationSelectMaximum));
        } catch (IOException e) {
            log.error("file summary delimiter=: " + config.getFileSummaryDelimiter());
            log.error("file summary header   =: " + config.getFileSummaryHeader());
            log.error("file summary name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }
    }

    /**
     * End the benchmark.
     *
     * @param endDateTime the end time
     */
    public void endBenchmark(LocalDateTime endDateTime) {
        createMeasuringPoint("benchmark", lastBenchmark, endDateTime);

        try {
            resultFile.close();
        } catch (IOException e) {
            log.error("file result delimiter=: " + config.getFileResultDelimiter());
            log.error("file result header   =: " + config.getFileResultHeader());
            log.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

        openSummaryFile();

        createSummary(endDateTime);

        try {
            summaryFile.close();
        } catch (IOException e) {
            log.error("file summary delimiter=: " + config.getFileSummaryDelimiter());
            log.error("file summary header   =: " + config.getFileSummaryHeader());
            log.error("file summary name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

    }

    /**
     * End the current insert statement.
     *
     * @param endDateTime  the end time
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public void endQueryInsert(LocalDateTime endDateTime, int trialNo, String sqlStatement) {
        int duration = Duration.between(lastQuery, endDateTime).getNano();

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
     * @param endDateTime  the end time
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public void endQuerySelect(LocalDateTime endDateTime, int trialNo, String sqlStatement) {
        int duration = Duration.between(lastQuery, endDateTime).getNano();

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
     * @param endDateTime the end time
     * @param trialNo     the current trial number
     */
    public void endTrial(LocalDateTime endDateTime, int trialNo) {
        createMeasuringPoint("trial", trialNo, lastTrial, endDateTime);
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

    private void openSummaryFile() {
        String summaryDelimiter = config.getFileSummaryDelimiter();
        String summaryName = config.getFileSummaryName();

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
                        CSVFormat.EXCEL.withDelimiter(summaryDelimiter.charAt(0)).withHeader(config.getFileSummaryHeader().split(summaryDelimiter)));
            }
        } catch (IOException e) {
            log.error("file summary delimiter=: " + summaryDelimiter);
            log.error("file summary header   =: " + config.getFileSummaryHeader());
            log.error("file summary name     =: " + summaryName);
            log.error("-----------------------");
            e.printStackTrace();
        }
    }

    private void startBenchmark(LocalDateTime startDateTime) {
        lastBenchmark = startDateTime;
    }

    /**
     * Start a new query.
     *
     * @param startDateTime the start time
     */
    public void startQuery(LocalDateTime startDateTime) {
        lastQuery = startDateTime;
    }

    /**
     * Start a new trial.
     *
     * @param startDateTime the start time
     */
    public void startTrial(LocalDateTime startDateTime) {
        lastTrial = startDateTime;
    }

}
