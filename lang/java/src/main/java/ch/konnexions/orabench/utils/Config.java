/*
 *
 */

package ch.konnexions.orabench.utils;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.configuration2.PropertiesConfiguration;
import org.apache.commons.configuration2.builder.FileBasedConfigurationBuilder;
import org.apache.commons.configuration2.builder.fluent.Parameters;
import org.apache.commons.configuration2.ex.ConfigurationException;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.simple.JSONObject;

/**
 * The configuration parameters for the Oracle JDBC benchmark tests. The
 * configuration parameters are made available to the configuration object in a
 * text file. This text file must contain the values of the following
 * configuration parameters:
 * <ul>
 * <li>benchmark.batch.size
 * <li>benchmark.comment
 * <li>benchmark.core.multiplier
 * <li>benchmark.database
 * <li>benchmark.driver
 * <li>benchmark.host.name
 * <li>benchmark.id
 * <li>benchmark.language
 * <li>benchmark.number.cores
 * <li>benchmark.number.partitions
 * <li>benchmark.os
 * <li>benchmark.release
 * <li>benchmark.transaction.size
 * <li>benchmark.trials
 * <li>benchmark.user.name
 * <li>connection.fetch.size
 * <li>connection.host
 * <li>connection.password
 * <li>connection.port
 * <li>connection.service
 * <li>connection.user
 * <li>file.bulk.delimiter
 * <li>file.bulk.header
 * <li>file.bulk.length
 * <li>file.bulk.name
 * <li>file.bulk.size
 * <li>file.configuration.name
 * <li>file.configuration.name.c
 * <li>file.configuration.name.erlang
 * <li>file.configuration.name.json
 * <li>file.configuration.name.python
 * <li>file.result.delimiter
 * <li>file.result.header
 * <li>file.result.name
 * <li>sql.create
 * <li>sql.drop
 * <li>sql.insert
 * <li>sql.select
 * </ul>
 * The parameter name and parameter value must be separated by an equal sign
 * (=).
 */
public class Config {

  private static final Logger                                    logger     = LogManager.getLogger(Config.class);
  private final static boolean                                   isDebug    = logger.isDebugEnabled();
  private int                                                    benchmarkBatchSize;
  private String                                                 benchmarkComment;
  private int                                                    benchmarkCoreMultiplier;
  private String                                                 benchmarkDatabase;
  private String                                                 benchmarkDriver;
  private String                                                 benchmarkHostName;
  private String                                                 benchmarkId;
  private String                                                 benchmarkLanguage;
  private String                                                 benchmarkNumberCores;
  private int                                                    benchmarkNumberPartitions;
  private String                                                 benchmarkOs;
  private String                                                 benchmarkRelease;
  private int                                                    benchmarkTransactionSize;

  private int                                                    benchmarkTrials;
  private String                                                 benchmarkUserName;
  private int                                                    connectionFetchSize;
  private String                                                 connectionHost;
  private String                                                 connectionPassword;
  private int                                                    connectionPort;

  private String                                                 connectionService;
  private String                                                 connectionUser;
  private FileBasedConfigurationBuilder<PropertiesConfiguration> fileBasedConfigurationBuilder;
  private String                                                 fileBulkDelimiter;
  private String                                                 fileBulkHeader;
  private int                                                    fileBulkLength;
  private String                                                 fileBulkName;
  private int                                                    fileBulkSize;
  private String                                                 fileConfigurationName;
  private String                                                 fileConfigurationNameC;
  private String                                                 fileConfigurationNameErlang;
  private String                                                 fileConfigurationNameJson;
  private String                                                 fileConfigurationNamePython;
  private String                                                 fileConfigurationNameToml;
  private String                                                 fileResultDelimiter;
  private String                                                 fileResultHeader;

  private String                                                 fileResultName;

  private final DateTimeFormatter                                formatter  = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn");

  private ArrayList<String>                                      keysSorted = new ArrayList<>();

  private PropertiesConfiguration                                propertiesConfiguration;

  private String                                                 sqlCreate;
  private String                                                 sqlDrop;
  private String                                                 sqlInsert;
  private String                                                 sqlSelect;

  /**
   * Constructs a Config object.
   */
  public Config() {
    super();

    if (isDebug) {
      logger.debug("Start");
    }

    createConfiguration();

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the default version of the configuration file.
   */
  private void createConfiguration() {
    if (isDebug) {
      logger.debug("Start");
    }

    fileBasedConfigurationBuilder = new FileBasedConfigurationBuilder<>(PropertiesConfiguration.class);

    File configFile = new File(System.getenv("ORA_BENCH_FILE_CONFIGURATION_NAME"));
    fileBasedConfigurationBuilder.configure(new Parameters().properties().setFile(configFile));

    try {
      propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
      updatePropertiesFromOs();
      keysSorted = getKeysSorted();
    } catch (ConfigurationException e) {
      e.printStackTrace();
    }

    storeConfiguration();
    validateProperties();

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the C++ (gcc) version of the configuration file.
   */
  public final void createConfigurationFileC() {
    if (isDebug) {
      logger.debug("Start");
    }

    try {
      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameC(), false));

      String         value;

      for (final String key : keysSorted) {
        if ("file.result.header".contentEquals(key)) {
          value = propertiesConfiguration.getString(key).replace(";",
                                                                 fileResultDelimiter);
        } else {
          value = propertiesConfiguration.getString(key);
        }

        StringBuilder camelKey = new StringBuilder();
        for (int i = 0; i < key.length(); ++i) {
          if (key.charAt(i) == '.') {
            camelKey.append(Character.toUpperCase(key.charAt(i + 1)));
            ++i;
          } else {
            camelKey.append(key.charAt(i));
          }
        }

        bufferedWriter.write(camelKey + "=" + value);

        bufferedWriter.newLine();
      }

      bufferedWriter.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the Erlang version of the configuration file.
   */
  public final void createConfigurationFileErlang() {
    if (isDebug) {
      logger.debug("Start");
    }

    try {
      List<String>   list           = getNumericProperties();

      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameErlang(), false));

      bufferedWriter.write("#{");
      bufferedWriter.newLine();

      String value;

      for (final Iterator<String> iterator = keysSorted.iterator(); iterator.hasNext();) {
        final String key = iterator.next();

        if ("file.result.header".contentEquals(key)) {
          value = propertiesConfiguration.getString(key).replace(";",
                                                                 fileResultDelimiter);
        } else {
          value = propertiesConfiguration.getString(key);
        }

        final String quote = (list.contains(key.toLowerCase()))
            ? ""
            : "\"";

        bufferedWriter.write("    " + key.replace(".",
                                                  "_") + " => " + quote + value + quote);

        if (iterator.hasNext()) {
          bufferedWriter.write(",");
        }

        bufferedWriter.newLine();
      }

      bufferedWriter.write("}.");

      bufferedWriter.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the Erlang version of the configuration file.
   */
  @SuppressWarnings("unchecked")
  public final void createConfigurationFileJson() {
    if (isDebug) {
      logger.debug("Start");
    }

    try {

      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameJson(), false));

      String         value;

      JSONObject     obj            = new JSONObject();
      for (final String key : keysSorted) {
        if ("file.result.header".contentEquals(key)) {
          value = propertiesConfiguration.getString(key).replace(";",
                                                                 fileResultDelimiter);
        } else {
          value = propertiesConfiguration.getString(key);
        }
        try {
          obj.put(key,
                  Integer.parseInt(value));
        } catch (Exception e) {
          obj.put(key,
                  value);
        }
      }

      bufferedWriter.write(obj.toString());
      bufferedWriter.close();

    } catch (Exception e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the Python 3 version of the configuration file.
   */
  public final void createConfigurationFilePython() {
    if (isDebug) {
      logger.debug("Start");
    }

    try {

      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNamePython(), false));

      bufferedWriter.write("[DEFAULT]");
      bufferedWriter.newLine();

      String value;

      for (final String key : keysSorted) {
        if ("file.result.header".contentEquals(key)) {
          value = propertiesConfiguration.getString(key).replace(";",
                                                                 fileResultDelimiter);
        } else {
          value = propertiesConfiguration.getString(key);
        }

        bufferedWriter.write(key + " = " + ((value.contentEquals("\t"))
            ? "TAB"
            : value));
        bufferedWriter.newLine();
      }

      bufferedWriter.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates the TOML version of the configuration file.
   */
  public final void createConfigurationFileToml() {
    if (isDebug) {
      logger.debug("Start");
    }

    try {

      BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameToml(), false));

      bufferedWriter.write("[DEFAULT]");
      bufferedWriter.newLine();

      String value;

      for (final String key : keysSorted) {
        if ("file.result.header".contentEquals(key)) {
          value = propertiesConfiguration.getString(key).replace(";",
                                                                 fileResultDelimiter);
        } else {
          value = propertiesConfiguration.getString(key);
        }

        bufferedWriter.write(key.replace(".",
                                         "_") + " = \"" + ((value.contentEquals("\t"))
                                             ? "TAB"
                                             : value) + "\"");
        bufferedWriter.newLine();
      }

      bufferedWriter.close();
    } catch (IOException e) {
      e.printStackTrace();
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * @return the batch size of the INSERT operation
   */
  public final int getBenchmarkBatchSize() {
    return benchmarkBatchSize;
  }

  /**
   * @return the benchmark specific comment
   */
  final String getBenchmarkComment() {

    return benchmarkComment;
  }

  /**
   * @return the core multiplier for parallel processing
   */
  public final int getBenchmarkCoreMultiplier() {
    return benchmarkCoreMultiplier;
  }

  /**
   * @return the database description
   */
  final String getBenchmarkDatabase() {
    return benchmarkDatabase;
  }

  /**
   * @return the applied driver name and its version
   */
  final String getBenchmarkDriver() {
    return benchmarkDriver;
  }

  /**
   * @return the host name
   */
  final String getBenchmarkHostName() {
    return benchmarkHostName;
  }

  /**
   * @return the benchmark identification
   */
  final String getBenchmarkId() {
    return benchmarkId;
  }

  /**
   * @return the applied programming language with name and version
   */
  final String getBenchmarkLanguage() {
    return benchmarkLanguage;
  }

  /**
   * @return the number of cores
   */
  final String getBenchmarkNumberCores() {
    return benchmarkNumberCores;
  }

  /**
   * @return the number of partitions
   */
  public final int getBenchmarkNumberPartitions() {
    return benchmarkNumberPartitions;
  }

  /**
   * @return the operating system description
   */
  final String getBenchmarkOs() {
    return benchmarkOs;
  }

  /**
   * @return the ora_bench release no.
   */
  final String getBenchmarkRelease() {
    return benchmarkRelease;
  }

  /**
   * @return the transaction size of the INSERT operation
   */
  public final int getBenchmarkTransactionSize() {
    return benchmarkTransactionSize;
  }

  /**
   * @return the number of benchmark trials to be carried out
   */
  public final int getBenchmarkTrials() {
    return benchmarkTrials;
  }

  /**
   * @return the user name
   */
  final String getBenchmarkUserName() {
    return benchmarkUserName;
  }

  /**
   * @return how much data is pulled from the database across the network
   */
  public final int getConnectionFetchSize() {
    return connectionFetchSize;
  }

  /**
   * @return the host name or the IP address of the database
   */
  final String getConnectionHost() {
    return connectionHost;
  }

  /**
   * @return the password to connect to the database
   */
  final String getConnectionPassword() {
    return connectionPassword;
  }

  /**
   * @return the port number where the database server is listening for requests
   */
  final int getConnectionPort() {
    return connectionPort;
  }

  /**
   * @return the service name to connect to the database
   */
  final String getConnectionService() {
    return connectionService;
  }

  /**
   * @return the user name to connect to the database
   */
  final String getConnectionUser() {
    return connectionUser;
  }

  /**
   * @return the delimiter character of the bulk data file
   */
  public final String getFileBulkDelimiter() {
    return fileBulkDelimiter;
  }

  /**
   * @return the header line of the bulk data file
   */
  public final String getFileBulkHeader() {
    return fileBulkHeader;
  }

  /**
   * @return the length of a test column value
   */
  final int getFileBulkLength() {
    return fileBulkLength;
  }

  /**
   * @return the file name of the text file with the example data (bulk data
   *         file). The file name may contain the absolute or relative file path.
   */
  public final String getFileBulkName() {
    return fileBulkName;
  }

  /**
   * @return the number of different test column values
   */
  public final int getFileBulkSize() {
    return fileBulkSize;
  }

  /**
   * @return the name of the configuration file for the C++ (gcc) language version. The
   *         file name may contain the absolute or relative file path.
   */
  private final String getFileConfigurationNameC() {
    return fileConfigurationNameC;
  }

  /**
   * @return the name of the configuration file for the Erlang language version.
   *         The file name may contain the absolute or relative file path.
   */
  private final String getFileConfigurationNameErlang() {
    return fileConfigurationNameErlang;
  }

  /**
   * @return the name of the configuration file in JSON format. The file name may
   *         contain the absolute or relative file path.
   */
  private final String getFileConfigurationNameJson() {
    return fileConfigurationNameJson;
  }

  /**
   * @return the name of the configuration file for the Python 3 language version.
   *         The file name may contain the absolute or relative file path.
   */
  private final String getFileConfigurationNamePython() {
    return fileConfigurationNamePython;
  }

  /**
   * @return the name of the configuration file for the TOML version.
   *         The file name may contain the absolute or relative file path.
   */
  private final String getFileConfigurationNameToml() {
    return fileConfigurationNameToml;
  }

  /**
   * @return the delimiter character of the result file
   */
  final String getFileResultDelimiter() {
    return fileResultDelimiter;
  }

  /**
   * @return the header line of the result file
   */
  final String getFileResultHeader() {
    return fileResultHeader;
  }

  /**
   * @return the name of the result file containing the benchmark results. The
   *         file name may contain the absolute or relative file path.
   */
  final String getFileResultName() {
    return fileResultName;
  }

  private ArrayList<String> getKeysSorted() {
    if (isDebug) {
      logger.debug("Start");
    }

    for (final Iterator<String> iterator = propertiesConfiguration.getKeys(); iterator.hasNext();) {
      keysSorted.add(iterator.next());
    }

    Collections.sort(keysSorted);

    if (isDebug) {
      logger.debug("End");
    }

    return keysSorted;
  }

  private List<String> getNotAvailables() {
    if (isDebug) {
      logger.debug("Start");
    }

    List<String> list = new ArrayList<>();

    list.add("benchmark.comment");
    list.add("benchmark.database");
    list.add("benchmark.driver");
    list.add("benchmark.host.name");
    list.add("benchmark.id");
    list.add("benchmark.language");
    list.add("benchmark.number.cores");
    list.add("benchmark.os");
    list.add("benchmark.user.name");
    list.add("connection.service");
    list.add("sql.create");

    if (isDebug) {
      logger.debug("End");
    }

    return list;
  }

  private List<String> getNumericProperties() {
    if (isDebug) {
      logger.debug("Start");
    }

    List<String> list = new ArrayList<>();

    list.add("benchmark.batch.size");
    list.add("benchmark.number.cores");
    list.add("benchmark.number.partitions");
    list.add("benchmark.transaction.size");
    list.add("benchmark.trials");
    list.add("connection.fetch.size");
    list.add("benchmark.core.multiplier");
    list.add("connection.pool.size.min");
    list.add("connection.port");
    list.add("file.bulk.length");
    list.add("file.bulk.size");

    if (isDebug) {
      logger.debug("End");
    }

    return list;
  }

  private CharSequence getPartitionString() {
    if (isDebug) {
      logger.debug("Start");
    }

    StringBuilder stringBuffer = new StringBuilder();

    for (int i = 2; i <= benchmarkNumberPartitions; i++) {
      stringBuffer.append(", PARTITION p").append(String.format("%05d",
                                                                i - 1)).append(" VALUES LESS THAN (").append(i).append(")");
    }

    if (isDebug) {
      logger.debug("End");
    }

    return stringBuffer.toString();
  }

  /**
   * @return the CREATE TABLE statement
   */
  public final String getSqlCreate() {
    return sqlCreate;
  }

  /**
   * @return the DROP TABLE statement
   */
  public final String getSqlDrop() {
    return sqlDrop;
  }

  /**
   * @return the INSERT statement
   */
  public final String getSqlInsert() {
    return sqlInsert;
  }

  /**
   * @return the SELECT statement
   */
  public final String getSqlSelect() {
    return sqlSelect;
  }

  /**
   * Resets selected runtime configuration parameters to the original default
   * value.
   */
  public final void resetNotAvailables() {
    if (isDebug) {
      logger.debug("Start");
    }

    List<String> list      = getNotAvailables();

    boolean      isChanged = false;

    for (final String key : list) {
      if (!(propertiesConfiguration.getString(key).equals("n/a"))) {
        propertiesConfiguration.setProperty(key,
                                            "n/a");
        isChanged = true;
      }

    }

    if (propertiesConfiguration.getInt("benchmark.core.multiplier") != 0) {
      propertiesConfiguration.setProperty("benchmark.core.multiplier",
                                          0);
      isChanged = true;
    }

    if (propertiesConfiguration.getInt("benchmark.number.partitions") != 0) {
      propertiesConfiguration.setProperty("benchmark.number.partitions",
                                          0);
      isChanged = true;
    }

    if (!(propertiesConfiguration.getString("connection.host").equals("localhost"))) {
      propertiesConfiguration.setProperty("connection.host",
                                          "localhost");
      isChanged = true;
    }

    if (isChanged) {
      try {
        fileBasedConfigurationBuilder.save();
        propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
      } catch (ConfigurationException e) {
        e.printStackTrace();
      }
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * @param benchmarkDriver the name of the applied driver to set
   */
  final void setBenchmarkDriver(String benchmarkDriver) {
    this.benchmarkDriver = benchmarkDriver;
  }

  private void storeConfiguration() {
    if (isDebug) {
      logger.debug("Start");
    }

    propertiesConfiguration.setThrowExceptionOnMissing(true);

    benchmarkBatchSize          = propertiesConfiguration.getInt("benchmark.batch.size");
    benchmarkComment            = propertiesConfiguration.getString("benchmark.comment");
    benchmarkCoreMultiplier     = propertiesConfiguration.getInt("benchmark.core.multiplier");
    benchmarkDatabase           = propertiesConfiguration.getString("benchmark.database");
    benchmarkDriver             = propertiesConfiguration.getString("benchmark.driver");
    benchmarkHostName           = propertiesConfiguration.getString("benchmark.host.name");
    benchmarkId                 = propertiesConfiguration.getString("benchmark.id");
    benchmarkNumberCores        = propertiesConfiguration.getString("benchmark.number.cores");
    benchmarkNumberPartitions   = propertiesConfiguration.getInt("benchmark.number.partitions");
    benchmarkOs                 = propertiesConfiguration.getString("benchmark.os");
    benchmarkRelease            = propertiesConfiguration.getString("benchmark.release");
    benchmarkTransactionSize    = propertiesConfiguration.getInt("benchmark.transaction.size");
    benchmarkTrials             = propertiesConfiguration.getInt("benchmark.trials");
    benchmarkUserName           = propertiesConfiguration.getString("benchmark.user.name");

    connectionFetchSize         = propertiesConfiguration.getInt("connection.fetch.size");
    connectionHost              = propertiesConfiguration.getString("connection.host");
    connectionPassword          = propertiesConfiguration.getString("connection.password");
    connectionPort              = propertiesConfiguration.getInt("connection.port");
    connectionService           = propertiesConfiguration.getString("connection.service");
    connectionUser              = propertiesConfiguration.getString("connection.user");

    fileBulkDelimiter           = propertiesConfiguration.getString("file.bulk.delimiter");
    fileBulkLength              = propertiesConfiguration.getInt("file.bulk.length");
    fileBulkHeader              = propertiesConfiguration.getString("file.bulk.header");
    fileBulkName                = propertiesConfiguration.getString("file.bulk.name");
    fileBulkSize                = propertiesConfiguration.getInt("file.bulk.size");
    fileConfigurationName       = propertiesConfiguration.getString("file.configuration.name");
    fileConfigurationNameC      = propertiesConfiguration.getString("file.configuration.name.c");
    fileConfigurationNameErlang = propertiesConfiguration.getString("file.configuration.name.erlang");
    fileConfigurationNameJson   = propertiesConfiguration.getString("file.configuration.name.json");

    fileConfigurationNamePython = propertiesConfiguration.getString("file.configuration.name.python");
    fileConfigurationNameToml   = propertiesConfiguration.getString("file.configuration.name.toml");
    fileResultDelimiter         = propertiesConfiguration.getString("file.result.delimiter");
    fileResultHeader            = propertiesConfiguration.getString("file.result.header").replace(";",
                                                                                                  fileResultDelimiter);
    fileResultName              = propertiesConfiguration.getString("file.result.name");

    sqlCreate                   = propertiesConfiguration.getString("sql.create");
    sqlDrop                     = propertiesConfiguration.getString("sql.drop");
    sqlInsert                   = propertiesConfiguration.getString("sql.insert");
    sqlSelect                   = propertiesConfiguration.getString("sql.select");

    benchmarkLanguage           = "Java " + System.getProperty("java.version");

    if (isDebug) {
      logger.debug("End");
    }
  }

  private void updatePropertiesFromOs() {
    if (isDebug) {
      logger.debug("Start");
    }

    Map<String, String> environmentVariables = System.getenv();

    boolean             isChanged            = false;

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_BATCH_SIZE")) {
      benchmarkBatchSize = Integer.parseInt(environmentVariables.get("ORA_BENCH_BENCHMARK_BATCH_SIZE"));
      propertiesConfiguration.setProperty("benchmark.batch.size",
                                          benchmarkBatchSize);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_COMMENT")) {
      benchmarkComment = environmentVariables.get("ORA_BENCH_BENCHMARK_COMMENT");
      if ("\"".equals(benchmarkComment.substring(0,
                                                 1))) {
        benchmarkComment = benchmarkComment.substring(1);
      }
      if ("\"".equals(benchmarkComment.substring(benchmarkComment.length() - 1))) {
        benchmarkComment = benchmarkComment.substring(0,
                                                      benchmarkComment.length() - 1);
      }
      propertiesConfiguration.setProperty("benchmark.comment",
                                          benchmarkComment);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_CORE_MULTIPLIER")) {
      benchmarkCoreMultiplier = Integer.parseInt(environmentVariables.get("ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"));
      propertiesConfiguration.setProperty("benchmark.core.multiplier",
                                          benchmarkCoreMultiplier);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DATABASE")) {
      benchmarkDatabase = environmentVariables.get("ORA_BENCH_BENCHMARK_DATABASE");
      propertiesConfiguration.setProperty("benchmark.database",
                                          benchmarkDatabase);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DRIVER")) {
      benchmarkDriver = environmentVariables.get("ORA_BENCH_BENCHMARK_DRIVER");
      propertiesConfiguration.setProperty("benchmark.driver",
                                          benchmarkDriver);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_TRANSACTION_SIZE")) {
      benchmarkTransactionSize = Integer.parseInt(environmentVariables.get("ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"));
      propertiesConfiguration.setProperty("benchmark.transaction.size",
                                          benchmarkTransactionSize);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_HOST")) {
      connectionHost = environmentVariables.get("ORA_BENCH_CONNECTION_HOST");
      propertiesConfiguration.setProperty("connection.host",
                                          connectionHost);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_PORT")) {
      connectionPort = Integer.parseInt(environmentVariables.get("ORA_BENCH_CONNECTION_PORT"));
      propertiesConfiguration.setProperty("connection.port",
                                          connectionPort);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_SERVICE")) {
      connectionService = environmentVariables.get("ORA_BENCH_CONNECTION_SERVICE");
      propertiesConfiguration.setProperty("connection.service",
                                          connectionService);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_FILE_CONFIGURATION_NAME")) {
      fileConfigurationName = environmentVariables.get("ORA_BENCH_FILE_CONFIGURATION_NAME");
      propertiesConfiguration.setProperty("file.configuration.name",
                                          fileConfigurationName);
      isChanged = true;
    }

    if (environmentVariables.containsKey("ORA_BENCH_FILE_RESULT_NAME")) {
      fileResultName = environmentVariables.get("ORA_BENCH_FILE_RESULT_NAME");
      propertiesConfiguration.setProperty("file.result.name",
                                          fileResultName);
      isChanged = true;
    }

    if (isChanged) {
      try {
        fileBasedConfigurationBuilder.save();
        propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
      } catch (ConfigurationException e) {
        e.printStackTrace();
      }
    }

    if (isDebug) {
      logger.debug("End");
    }
  }

  private void validateProperties() {
    if (isDebug) {
      logger.debug("Start");
    }

    boolean isChanged = false;

    if (benchmarkBatchSize < 0) {
      logger.error("Attention: The value of the configuration parameter 'benchmark.batch.size' [" + benchmarkBatchSize
          + "] must not be less than 0, the specified value is replaced by 0.");
      benchmarkBatchSize = 0;
      propertiesConfiguration.setProperty("benchmark.batch.size",
                                          benchmarkBatchSize);
      isChanged = true;
    }

    if (benchmarkCoreMultiplier < 0) {
      logger.error("Attention: The value of the core multiplier parameter 'benchmark.core.multiplier' [" + benchmarkCoreMultiplier
          + "] must not be less than 0, the specified value is replaced by 0.");
      benchmarkCoreMultiplier = 0;
      propertiesConfiguration.setProperty("benchmark.core.multiplier",
                                          benchmarkCoreMultiplier);
      isChanged = true;
    }

    if (benchmarkHostName.equals("n/a")) {
      try {
        benchmarkHostName = InetAddress.getLocalHost().getHostName();
      } catch (UnknownHostException e) {
        e.printStackTrace();
      }
      propertiesConfiguration.setProperty("benchmark.host.name",
                                          benchmarkHostName);
      isChanged = true;
    }

    if (benchmarkNumberCores.equals("n/a")) {
      benchmarkNumberCores = Integer.toString(Runtime.getRuntime().availableProcessors());
      propertiesConfiguration.setProperty("benchmark.number.cores",
                                          benchmarkNumberCores);

      benchmarkNumberPartitions = (benchmarkCoreMultiplier == 0)
          ? Integer.parseInt(benchmarkNumberCores)
          : Integer.parseInt(benchmarkNumberCores) * benchmarkCoreMultiplier;
      propertiesConfiguration.setProperty("benchmark.number.partitions",
                                          benchmarkNumberPartitions);

      isChanged = true;
    }

    if (benchmarkOs.equals("n/a")) {
      benchmarkOs = System.getProperty("os.arch") + " / " + System.getProperty("os.name") + " / " + System.getProperty("os.version");
      propertiesConfiguration.setProperty("benchmark.os",
                                          benchmarkOs);
      isChanged = true;
    }

    if (benchmarkRelease.equals("n/a")) {
      benchmarkRelease = System.getProperty("benchmark.release");
      propertiesConfiguration.setProperty("benchmark.release",
                                          benchmarkRelease);
      isChanged = true;
    }

    if (benchmarkTransactionSize < benchmarkBatchSize) {
      logger.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + benchmarkTransactionSize
          + "] must not be less than value of the configuration parameter 'benchmark.batch.size' [" + benchmarkBatchSize
          + "], the specified value of the configuration parameter 'benchmark.transaction.size' is replaced by " + benchmarkBatchSize + "");
      benchmarkTransactionSize = benchmarkBatchSize;
      propertiesConfiguration.setProperty("benchmark.batch.size",
                                          benchmarkTransactionSize);

      isChanged = true;
    }

    if (benchmarkTransactionSize < 0) {
      logger.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + benchmarkTransactionSize
          + "] must not be less than 0, the specified value is replaced by 0.");

      benchmarkTransactionSize = 0;

      propertiesConfiguration.setProperty("benchmark.batch.size",
                                          benchmarkTransactionSize);
      isChanged = true;
    }

    if (benchmarkTrials < 1) {
      logger.error("Attention: The value of the configuration parameter 'benchmark.trials' [" + benchmarkTrials
          + "] must not be less than 1, the specified value is replaced by 1.");
      benchmarkTrials = 1;
      propertiesConfiguration.setProperty("benchmark.trials",
                                          benchmarkTrials);

      isChanged = true;
    }

    if (benchmarkUserName.equals("n/a")) {
      benchmarkUserName = System.getProperty("user.name");
      propertiesConfiguration.setProperty("benchmark.user.name",
                                          benchmarkUserName);
      isChanged = true;
    }

    if (benchmarkId.equals("n/a")) {
      benchmarkId = DigestUtils.md5Hex(LocalDateTime.now().format(formatter) + benchmarkHostName + benchmarkOs + benchmarkUserName);
      propertiesConfiguration.setProperty("benchmark.id",
                                          benchmarkId);
      isChanged = true;
    }

    if (connectionFetchSize < 0) {
      logger.error("Attention: The value of the configuration parameter 'connection.fetch.size' [" + connectionFetchSize
          + "] must not be less than 0, the specified value is replaced by 0.");
      connectionFetchSize = 0;
      propertiesConfiguration.setProperty("connection.fetch.size",
                                          connectionFetchSize);
      isChanged = true;
    }

    if (fileBulkLength < 80) {
      logger.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + fileBulkLength
          + "] must not be less than 80, the specified value is replaced by 80.");
      fileBulkLength = 80;
      propertiesConfiguration.setProperty("file.bulk.length",
                                          fileBulkLength);

      isChanged = true;
    } else if (fileBulkLength > 4000) {
      logger.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + fileBulkLength
          + "] must not be greater than 4000, the specified value is replaced by 4000.");
      fileBulkLength = 80;
      propertiesConfiguration.setProperty("file.bulk.length",
                                          fileBulkLength);
      isChanged = true;
    }

    if (fileBulkSize < 1) {
      logger.error("Attention: The value of the configuration parameter 'file.bulk.size' [" + fileBulkSize
          + "] must not be less than 1, the specified value is replaced by 1.");
      fileBulkSize = 1;
      propertiesConfiguration.setProperty("file.bulk.size",
                                          fileBulkSize);

      isChanged = true;
    }

    if (sqlCreate.equals("n/a")) {
      String sqlCreateDefault = "BEGIN EXECUTE IMMEDIATE 'CREATE TABLE ora_bench_table (key VARCHAR2(32) PRIMARY KEY, data VARCHAR2(4000), "
          + "no_partitions NUMBER DEFAULT C...C, partition_key NUMBER(5)) PARTITION BY RANGE (partition_key) (PARTITION p00000 VALUES LESS THAN (1)P...P)'; "
          + "EXECUTE IMMEDIATE 'CREATE TRIGGER ora_bench_table_before_insert BEFORE INSERT ON ora_bench_table FOR EACH ROW "
          + "BEGIN :new.partition_key := MOD (ASCII (SUBSTR (:new.key, 1, 1)) * 251 + ASCII (SUBSTR (:new.key, 2, 1)), :new.no_partitions); "
          + "END ora_bench_table_before_insert;'; END;";
      sqlCreate = sqlCreateDefault.replace("C...C",
                                           Integer.toString(benchmarkNumberPartitions)).replace("P...P",
                                                                                                getPartitionString());
      propertiesConfiguration.setProperty("sql.create",
                                          sqlCreate);
      isChanged = true;
    }

    if (isChanged) {
      try {
        fileBasedConfigurationBuilder.save();
        propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
      } catch (ConfigurationException e) {
        e.printStackTrace();
      }

    }

    if (isDebug) {
      logger.debug("End");
    }
  }

}
