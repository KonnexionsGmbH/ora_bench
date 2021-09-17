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
import java.nio.file.Paths;
import java.text.DecimalFormat;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

import org.apache.commons.math3.util.Precision;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * This class is used to record the results of the Oracle JDBC benchmark.
 */
public class Result {
    private static final Logger logger = LogManager.getLogger(Result.class);

    private final static boolean isDebug = logger.isDebugEnabled();

    private final Config config;

    private final DecimalFormat decimalFormat = new DecimalFormat("#########");
    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn");
    private final LocalDateTime lastBenchmark = LocalDateTime.now();
    private final long lastBenchmarkNano = System.nanoTime();
    private LocalDateTime lastQuery;
    private long lastQueryNano;

    private LocalDateTime lastTrial;

    private long lastTrialNano;

    private CSVPrinter resultFile;

    /**
     * Constructs a Result object using the given {@link Config} object.
     *
     * @param config the {@link Config} object
     */
    public Result(Config config) {
        if (isDebug) {
            logger.debug("Start");
        }

        this.config = config;

        openResultFile();

        if (isDebug) {
            logger.debug("End");
        }
    }

    private void createMeasuringPoint(int trialNo, LocalDateTime startDateTime, LocalDateTime endDateTime,
                                      long duration) {
        if (isDebug) {
            logger.debug("Start");
        }

        createMeasuringPoint("trial", trialNo, null, startDateTime, endDateTime, duration);

        if (isDebug) {
            logger.debug("End");
        }
    }

    private void createMeasuringPoint(LocalDateTime endDateTime, long duration) {
        if (isDebug) {
            logger.debug("Start");
        }

        createMeasuringPoint("benchmark", 0, null, lastBenchmark, endDateTime, duration);

        if (isDebug) {
            logger.debug("End");
        }
    }

    private void createMeasuringPoint(String action, int trialNo, String sqlStatement, LocalDateTime startDateTime,
                                      LocalDateTime endDateTime, long duration) {
        if (isDebug) {
            logger.debug("Start");
        }

        try {
            resultFile.printRecord(config.getBenchmarkRelease(), config.getBenchmarkId(), config.getBenchmarkComment(),
                    config.getBenchmarkHostName(), config.getBenchmarkNumberCores(), config.getBenchmarkOs(),
                    config.getBenchmarkUserName(), config.getBenchmarkDatabase(), config.getBenchmarkLanguage(),
                    config.getBenchmarkDriver(), trialNo, sqlStatement, config.getBenchmarkCoreMultiplier(),
                    config.getConnectionFetchSize(), config.getBenchmarkTransactionSize(), config.getFileBulkLength(),
                    config.getFileBulkSize(), config.getBenchmarkBatchSize(), action, startDateTime.format(formatter),
                    endDateTime.format(formatter),
                    decimalFormat.format((long) Precision.round(duration / 1000000000.0, 0)), Long.toString(duration));
        } catch (IOException e) {
            logger.error("file result delimiter=: " + config.getFileResultDelimiter());
            logger.error("file result header   =: " + config.getFileResultHeader());
            logger.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * End of the whole benchmark run.
     *
     * @param benchmarkTrials
     */
    public final void endBenchmark(int benchmarkTrials) {
        if (isDebug) {
            logger.debug("Start");
        }

        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastBenchmarkNano;

        createMeasuringPoint(endDateTime, duration);

        try {
            resultFile.close();
        } catch (IOException e) {
            logger.error("file result delimiter=: " + config.getFileResultDelimiter());
            logger.error("file result header   =: " + config.getFileResultHeader());
            logger.error("file result name     =: " + config.getFileBulkSize());
            e.printStackTrace();
        }

        logger.info(
                "Duration (ms) trial average : " + (long) Precision.round(duration / 1000000.0 / benchmarkTrials, 0));
        logger.info("Duration (ms) benchmark run : " + (long) Precision.round(duration / 1000000.0, 0));

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * End of the current insert statement.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQueryInsert(int trialNo, String sqlStatement) {
        if (isDebug) {
            logger.debug("Start");
        }

        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * End of the current select.
     *
     * @param trialNo      the current trial number
     * @param sqlStatement the SQL statement to be applied
     */
    public final void endQuerySelect(int trialNo, String sqlStatement) {
        if (isDebug) {
            logger.debug("Start");
        }

        LocalDateTime endDateTime = LocalDateTime.now();
        long duration = System.nanoTime() - lastQueryNano;

        createMeasuringPoint("query", trialNo, sqlStatement, lastQuery, endDateTime, duration);

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * End of the current trial.
     *
     * @param trialNo the current trial number
     */
    public final void endTrial(int trialNo) {
        if (isDebug) {
            logger.debug("Start");
        }

        long duration = System.nanoTime() - lastTrialNano;

        createMeasuringPoint(trialNo, lastTrial, LocalDateTime.now(), duration);

        logger.info("Duration (ms) trial         : " + (long) Precision.round(duration / 1000000.0, 0));

        if (isDebug) {
            logger.debug("End");
        }
    }

    private void openResultFile() {
        if (isDebug) {
            logger.debug("Start");
        }

        String resultDelimiter = config.getFileResultDelimiter();
        String resultName = config.getFileResultName();

        try {
            boolean isFileExisting = Files.exists(Paths.get(resultName));

            if (!(isFileExisting)) {
                logger.error("fatal error: program abort =====> result file \"" + resultName + "\" is missing <=====");
                System.exit(1);
            }

            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(resultName, true));
            resultFile = new CSVPrinter(bufferedWriter,
                    CSVFormat.EXCEL.builder().setDelimiter(resultDelimiter.charAt(0)).build());
        } catch (IOException e) {
            logger.error("file result delimiter=: " + resultDelimiter);
            logger.error("file result header   =: " + config.getFileResultHeader());
            logger.error("file result name     =: " + resultName);
            logger.error("-----------------------");
            e.printStackTrace();
        }

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * Start a new query.
     */
    public final void startQuery() {
        if (isDebug) {
            logger.debug("Start");
        }

        lastQuery = LocalDateTime.now();
        lastQueryNano = System.nanoTime();

        if (isDebug) {
            logger.debug("End");
        }
    }

    /**
     * Start a new trial.
     */
    public final void startTrial() {
        if (isDebug) {
            logger.debug("Start");
        }

        lastTrial = LocalDateTime.now();
        lastTrialNano = System.nanoTime();

        if (isDebug) {
            logger.debug("End");
        }
    }

}
