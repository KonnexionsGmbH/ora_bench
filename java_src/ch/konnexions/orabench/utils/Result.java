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
import java.io.File;
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

    private int fileBulkLength;
    private int fileBulkSize;

    private final String interfaceName = "Oracle JDBC";

    private LocalDateTime lastBenchmark;
    private LocalDateTime lastQuery;
    private LocalDateTime lastTrial;
    private Logger log = new Logger(Result.class);

    private String moduleName = "OraBench.java";

    private String resultDelimiter;
    private CSVPrinter resultFile;
    private String resultHeader;
    private String resultName;

    /**
     * Constructs a Result object using the given {@link Config} object.
     *
     * @param config the {@link Config} object
     */
    public Result(Config config) {
        fileBulkLength = config.getFileBulkLength();
        fileBulkSize = config.getFileBulkSize();
        resultDelimiter = config.getFileResultDelimiter();
        resultHeader = config.getFileResultHeader();
        resultName = config.getFileResultName().replace("/", File.separator).replace("\\", File.separator);

        openResultFile();

        startBenchmark(LocalDateTime.now());
    }

    private void createMeasuringPoint(String action, int trialNo, LocalDateTime startDateTime, LocalDateTime endDateTime) {
        createMeasuringPoint(action, trialNo, null, startDateTime, endDateTime);

    }

    private void createMeasuringPoint(String action, int trialNo, String sqlStatement, LocalDateTime startDateTime, LocalDateTime endDateTime) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss.nnnnnnnnn");
        String startDateTimeStr = startDateTime.format(formatter);
        String endDateTimeStr = endDateTime.format(formatter);
        String duration = Integer.toString(Duration.between(startDateTime, endDateTime).getNano());

        try {
            resultFile.printRecord(moduleName, interfaceName, trialNo, sqlStatement, fileBulkLength, fileBulkSize, action, startDateTimeStr, endDateTimeStr,
                    duration);
        } catch (IOException e) {
            log.error("file result delimiter=: " + resultDelimiter);
            log.error("file result header   =: " + resultHeader);
            log.error("file result name     =: " + resultName);
            log.error("-----------------------");
            log.error("moduleName      =: " + moduleName);
            log.error("interfaceName   =: " + interfaceName);
            log.error("trialNo         =: " + Integer.toString(trialNo));
            log.error("sqlStatement    =: " + sqlStatement);
            log.error("fileBulkLength  =: " + Integer.toString(fileBulkLength));
            log.error("fileBulkSize    =: " + Integer.toString(fileBulkSize));
            log.error("action          =: " + action);
            log.error("startDateTimeStr=: " + startDateTimeStr);
            log.error("endDateTimeStr  =: " + endDateTimeStr);
            log.error("duration        =: " + duration);
            log.error("-----------------------");
            e.printStackTrace();
        }
    }

    private void createMeasuringPoint(String action, LocalDateTime startDateTime, LocalDateTime endDateTime) {
        createMeasuringPoint(action, 0, null, startDateTime, endDateTime);

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
            log.error("file result delimiter=: " + resultDelimiter);
            log.error("file result header   =: " + resultHeader);
            log.error("file result name     =: " + resultName);
            e.printStackTrace();
        }
    }

    /**
     * End the current query.
     *
     * @param endDateTime  the end time
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public void endQuery(LocalDateTime endDateTime, int trialNo, String sqlStatement) {
        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime);
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
                        CSVFormat.EXCEL.withDelimiter(resultDelimiter.charAt(0)).withHeader(resultHeader.split(resultDelimiter)));
            }
        } catch (IOException e) {
            log.error("file result delimiter=: " + resultDelimiter);
            log.error("file result header   =: " + resultHeader);
            log.error("file result name     =: " + resultName);
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
