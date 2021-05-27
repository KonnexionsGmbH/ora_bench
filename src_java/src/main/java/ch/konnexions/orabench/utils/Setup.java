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

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVPrinter;
import org.apache.commons.lang3.RandomStringUtils;
import org.apache.log4j.Logger;

/**
 * This class provides setup support for the Oracle JDBC benchmark runs.
 */
public class Setup {

  /**
   * The Constant LENGTH_DIGEST.
   */
  private static final int     LENGTH_DIGEST   = 32;

  /**
   * The Constant BULK_LENGTH_MAX defines the maximum length of a text line in the
   * bulk file.
   */
  private static final int     BULK_LENGTH_MAX = 4000;

  /**
   * The Constant BULK_LENGTH_MIN defines the minimum length of a text line in the
   * bulk file.
   */
  private static final int     BULK_LENGTH_MIN = LENGTH_DIGEST + 1;

  /**
   * The Constant BULK_SIZE_MIN defines the minimum number of text lines in the
   * bulk file.
   */
  private static final int     BULK_SIZE_MIN   = 1;

  private static final Logger  logger          = Logger.getLogger(Setup.class);

  private final static boolean isDebug         = logger.isDebugEnabled();

  private final Config         config;

  /**
   * Constructs a Setup object using the given {@link Config} object.
   *
   * @param config the {@link Config} object
   */
  public Setup(Config config) {
    if (isDebug) {
      logger.debug("Start");
    }

    this.config = config;

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates a new bulk file based on the parameters in the specified
   * configuration object. The bulk file contains all data that is to be written
   * to the database and then read again.
   */
  public final void createBulkFile() {
    if (isDebug) {
      logger.debug("Start");
    }

    int fileBulkLength = config.getFileBulkLength();

    if (fileBulkLength < BULK_LENGTH_MIN) {
      fileBulkLength = BULK_LENGTH_MIN;
    } else if (fileBulkLength > BULK_LENGTH_MAX) {
      fileBulkLength = BULK_LENGTH_MAX;
    }

    int fileBulkSize = config.getFileBulkSize();

    if (fileBulkSize < BULK_SIZE_MIN) {
      fileBulkSize = BULK_SIZE_MIN;
    }

    final String baseRandomString = RandomStringUtils.randomAlphanumeric(fileBulkLength - LENGTH_DIGEST * 2);
    String       lastDigest       = ("not yet available " + baseRandomString).substring(0,
                                                                                        LENGTH_DIGEST);

    try {
      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(config.getFileBulkName(), false));
      CSVPrinter     bulkFile       = new CSVPrinter(bufferedWriter, CSVFormat.EXCEL.withDelimiter(config.getFileBulkDelimiter().charAt(0)).withHeader(config
          .getFileBulkHeader().split(config.getFileBulkDelimiter())));

      for (int i = 0; i < fileBulkSize; i++) {
        String currDigest = DigestUtils.md5Hex(lastDigest + baseRandomString);
        bulkFile.printRecord(currDigest,
                             lastDigest + baseRandomString + lastDigest);
        lastDigest = currDigest;
      }

      bulkFile.close();

      logger.info("bulk file written: file name=" + config.getFileBulkName() + " size=" + fileBulkSize + " length=" + fileBulkLength);

      createResultFile();

    } catch (IOException e) {
      logger.error("bulk file name  =: " + config.getFileBulkName());
      logger.error("bulk file length=: " + fileBulkLength);
      logger.error("bulk file size  =: " + fileBulkSize);
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates a new result file if none exists yet.
   */
  @SuppressWarnings("resource")
  private final void createResultFile() {
    if (isDebug) {
      logger.debug("Start");
    }

    String resultDelimiter = config.getFileResultDelimiter();
    String resultName      = config.getFileResultName();

    try {
      Path    resultPath     = Paths.get(resultName);

      boolean isFileExisting = Files.exists(Paths.get(resultName));

      if (!(isFileExisting)) {
        Files.createFile(resultPath);

        BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(resultName, false));

        new CSVPrinter(bufferedWriter, CSVFormat.EXCEL.withDelimiter(resultDelimiter.charAt(0)).withHeader(config.getFileResultHeader().split(
                                                                                                                                              resultDelimiter)));

        bufferedWriter.close();

        logger.info("missing result file created: file name=" + config.getFileResultName());
      }
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
}
