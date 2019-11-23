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

/**
 * The configuration parameters for the Oracle JDBC benchmark tests. The
 * configuration parameters are made available to the configuration object in a
 * text file. This text file must contain the values of the following
 * configuration parameters:
 * <ul>
 * <li>benchmark.batch.size
 * <li>benchmark.comment
 * <li>benchmark.database
 * <li>benchmark.driver
 * <li>benchmark.host.name
 * <li>benchmark.id
 * <li>benchmark.module
 * <li>benchmark.number.processors
 * <li>benchmark.os
 * <li>benchmark.program.name.oranif.c
 * <li>benchmark.transaction.size
 * <li>benchmark.trials
 * <li>benchmark.user.name
 * <li>connection.fetch.size
 * <li>connection.host
 * <li>connection.password
 * <li>connection.pool.size.max
 * <li>connection.pool.size.min
 * <li>connection.port
 * <li>connection.service
 * <li>connection.string
 * <li>connection.user
 * <li>file.bulk.delimiter
 * <li>file.bulk.header
 * <li>file.bulk.length
 * <li>file.bulk.name
 * <li>file.bulk.size
 * <li>file.configuration.name
 * <li>file.configuration.name.cx_oracle.python
 * <li>file.configuration.name.oranif.c
 * <li>file.configuration.name.oranif.erlang
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

    private static Logger log = new Logger(Config.class);
    private int benchmarkBatchSize;
    private String benchmarkComment;
    private String benchmarkDatabase;
    private String benchmarkDriver;
    private String benchmarkHostName;
    private String benchmarkId;
    private String benchmarkModule;
    private String benchmarkNumberProcessors;
    private String benchmarkOs;
    private String benchmarkProgramNameOranifC;
    private int benchmarkTransactionSize;
    private int benchmarkTrials;
    private String benchmarkUserName;

    private final File configFile = new File(System.getenv("ORA_BENCH_FILE_CONFIGURATION_NAME"));
    private int connectionFetchSize;
    private String connectionHost;
    private String connectionPassword;
    private int connectionPoolSizeMax;
    private int connectionPoolSizeMin;
    private int connectionPort;
    private String connectionService;
    private String connectionString;
    private String connectionUser;

    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn");

    FileBasedConfigurationBuilder<PropertiesConfiguration> fileBasedConfigurationBuilder;
    private String fileBulkDelimiter;
    private String fileBulkHeader;
    private int fileBulkLength;
    private String fileBulkName;
    private int fileBulkSize;
    private String fileConfigurationName;
    private String fileConfigurationNameCxOraclePython;
    private String fileConfigurationNameOranifC;
    private String fileConfigurationNameOranifErlang;
    private String fileResultDelimiter;
    private String fileResultHeader;
    private String fileResultName;

    private ArrayList<String> keysSorted = new ArrayList<String>();

    private List<String> numericProperties = getNumericProperties();

    private PropertiesConfiguration propertiesConfiguration;

    private String sqlCreateTable;
    private String sqlDropTable;
    private String sqlInsert;
    private String sqlSelect;

    /**
     * Constructs a Config object.
     */
    public Config() {
        super();

        fileBasedConfigurationBuilder = new FileBasedConfigurationBuilder<PropertiesConfiguration>(PropertiesConfiguration.class);

        fileBasedConfigurationBuilder.configure(new Parameters().properties().setFile(configFile));

        try {
            propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
            updatePropertiesFromOs();
            keysSorted = getKeysSorted(propertiesConfiguration);
        } catch (ConfigurationException e) {
            e.printStackTrace();
        }

        storeConfiguration();
        validateProperties();
    }

    /**
     * Creates the cx_Oracle &amp; Python version of the configuration file.
     */
    public final void createConfigurationFileCxOraclePython() {
        try {

            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameCxOraclePython(), false));

            bufferedWriter.write("[DEFAULT]");
            bufferedWriter.newLine();

            for (final Iterator<String> iterator = keysSorted.iterator(); iterator.hasNext();) {
                final String key = iterator.next();
                final String value = propertiesConfiguration.getString(key);

                bufferedWriter.write(key + " = " + ((value.contentEquals("\t")) ? "TAB" : value));
                bufferedWriter.newLine();
            }

            bufferedWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Creates the oranif &amp; C version of the configuration file.
     */
    public final void createConfigurationFileOranifC() {
        try {
            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameOranifC(), false));

            bufferedWriter.write("#!/bin/bash");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("# ------------------------------------------------------------------------------");
            bufferedWriter.newLine();
            bufferedWriter.write("#");
            bufferedWriter.newLine();
            bufferedWriter.write("# run_bench_oranif_c.sh: Oracle Benchmark based on oranif & C.");
            bufferedWriter.newLine();
            bufferedWriter.write("#");
            bufferedWriter.newLine();
            bufferedWriter.write("# ------------------------------------------------------------------------------");
            bufferedWriter.newLine();
            bufferedWriter.newLine();

            for (final Iterator<String> iterator = keysSorted.iterator(); iterator.hasNext();) {
                final String key = iterator.next();

                final String quote = (numericProperties.contains(key.toLowerCase())) ? "" : "'";

                if (key.contentEquals("benchmark.driver")) {
                    bufferedWriter.write("ORA_BENCH_BENCHMARK_DRIVER='oranif (Version version)'");
                } else if (key.equals("benchmark.module")) {
                    bufferedWriter.write("ORA_BENCH_BENCHMARK_MODULE='OraBench (C version)'");
                } else {
                    bufferedWriter.write("ORA_BENCH_" + key.replace(".", "_").toUpperCase() + "=" + quote + propertiesConfiguration.getString(key) + quote);
                }

                bufferedWriter.newLine();
            }

            bufferedWriter.newLine();
            bufferedWriter.write("echo \"================================================================================\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"Start $0\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"--------------------------------------------------------------------------------\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"ora_bench - Oracle benchmark - oranif & C.\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"--------------------------------------------------------------------------------\"");
            bufferedWriter.newLine();
            bufferedWriter.write("date +\"DATE TIME : %d.%m.%Y %H:%M:%S\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"================================================================================\"");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("EXITCODE=\"0\"");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("./" + getBenchmarkProgramNameOranifC() + " ");

            for (final Iterator<String> iterator = keysSorted.iterator(); iterator.hasNext();) {
                final String key = iterator.next();

                bufferedWriter.write("$ORA_BENCH_" + key.replace(".", "_").toUpperCase());

                if (iterator.hasNext()) {
                    bufferedWriter.write(" ");
                }
            }

            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("EXITCODE=$?");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"--------------------------------------------------------------------------------\"");
            bufferedWriter.newLine();
            bufferedWriter.write("date +\"DATE TIME : %d.%m.%Y %H:%M:%S\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"--------------------------------------------------------------------------------\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"End $0\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"================================================================================\"");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("exit $EXITCODE");
            bufferedWriter.newLine();

            bufferedWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * Creates the oranif &amp; Erlang version of the configuration file.
     */
    public final void createConfigurationFileOranifErlang() {
        try {
            List<String> list = getNumericProperties();

            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameOranifErlang(), false));

            bufferedWriter.write("#{");
            bufferedWriter.newLine();

            for (final Iterator<String> iterator = keysSorted.iterator(); iterator.hasNext();) {
                final String key = iterator.next();

                final String quote = (list.contains(key.toLowerCase())) ? "" : "\"";

                bufferedWriter.write("    " + key.replace(".", "_") + " => " + quote + propertiesConfiguration.getString(key) + quote);

                if (iterator.hasNext()) {
                    bufferedWriter.write(",");
                }

                bufferedWriter.newLine();
            }

            bufferedWriter.write("}");

            bufferedWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
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
    public final String getBenchmarkComment() {
        return benchmarkComment;
    }

    /**
     * @return the database description
     */
    public final String getBenchmarkDatabase() {
        return benchmarkDatabase;
    }

    /**
     * @return the applied driver name and its version
     */
    public final String getBenchmarkDriver() {
        return benchmarkDriver;
    }

    /**
     * @return the host name
     */
    public final String getBenchmarkHostName() {
        return benchmarkHostName;
    }

    /**
     * @return the benchmark identification
     */
    public final String getBenchmarkId() {
        return benchmarkId;
    }

    /**
     * @return the applied module name its programming language with name and
     *         version
     */
    public final String getBenchmarkModule() {
        return benchmarkModule;
    }

    /**
     * @return the number of processor
     */
    public final String getBenchmarkNumberProcessors() {
        return benchmarkNumberProcessors;
    }

    /**
     * @return the operating system description
     */
    public final String getBenchmarkOs() {
        return benchmarkOs;
    }

    /**
     * @return the oranif &amp; C program name
     */
    public final String getBenchmarkProgramNameOranifC() {
        return benchmarkProgramNameOranifC;
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
    public final String getBenchmarkUserName() {
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
    public final String getConnectionHost() {
        return connectionHost;
    }

    /**
     * @return the password to connect to the database
     */
    public final String getConnectionPassword() {
        return connectionPassword;
    }

    /**
     * @return the number of maximum simultaneous database connections
     */
    public final int getConnectionPoolSizeMax() {
        return connectionPoolSizeMax;
    }

    /**
     * @return the number of minimum simultaneous database connections
     */
    public final int getConnectionPoolSizeMin() {
        return connectionPoolSizeMin;
    }

    /**
     * @return the port number where the database server is listening for requests
     */
    public final int getConnectionPort() {
        return connectionPort;
    }

    /**
     * @return the service name to connect to the database
     */
    public final String getConnectionService() {
        return connectionService;
    }

    /**
     * @return the connection string
     */
    public final String getConnectionString() {
        return connectionString;
    }

    /**
     * @return the user name to connect to the database
     */
    public final String getConnectionUser() {
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
    public final int getFileBulkLength() {
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
     * @return the name of the configuration file. The file name may contain the
     *         absolute or relative file path.
     */
    public final String getFileConfigurationName() {
        return fileConfigurationName;
    }

    /**
     * @return the name of the configuration file for the cx_Oracle &amp; Python
     *         language version. The file name may contain the absolute or relative
     *         file path.
     */
    public final String getFileConfigurationNameCxOraclePython() {
        return fileConfigurationNameCxOraclePython;
    }

    /**
     * @return the name of the configuration file for the oranif &amp; C language
     *         version. The file name may contain the absolute or relative file
     *         path.
     */
    public final String getFileConfigurationNameOranifC() {
        return fileConfigurationNameOranifC;
    }

    /**
     * @return the name of the configuration file for the oranif &amp; Erlang
     *         language version. The file name may contain the absolute or relative
     *         file path.
     */
    public final String getFileConfigurationNameOranifErlang() {
        return fileConfigurationNameOranifErlang;
    }

    /**
     * @return the delimiter character of the result file
     */
    public final String getFileResultDelimiter() {
        return fileResultDelimiter;
    }

    /**
     * @return the header line of the result file
     */
    public final String getFileResultHeader() {
        return fileResultHeader;
    }

    /**
     * @return the name of the result file containing the benchmark results. The
     *         file name may contain the absolute or relative file path.
     */
    public final String getFileResultName() {
        return fileResultName;
    }

    private final ArrayList<String> getKeysSorted(PropertiesConfiguration propertiesConfiguration2) {
        for (final Iterator<String> iterator = propertiesConfiguration.getKeys(); iterator.hasNext();) {
            keysSorted.add(iterator.next());
        }

        Collections.sort(keysSorted);

        return keysSorted;
    }

    private final List<String> getNotAvailables() {
        List<String> list = new ArrayList<String>();

        list.add("benchmark.comment");
        list.add("benchmark.database");
        list.add("benchmark.driver");
        list.add("benchmark.host.name");
        list.add("benchmark.id");
        list.add("benchmark.module");
        list.add("benchmark.number.processors");
        list.add("benchmark.os");
        list.add("benchmark.user.name");
        list.add("connection.service");

        return list;
    }

    private final List<String> getNumericProperties() {
        List<String> list = new ArrayList<String>();

        list.add("benchmark.batch.size");
        list.add("benchmark.number.processors");
        list.add("benchmark.transaction.size");
        list.add("benchmark.trials");
        list.add("connection.fetch.size");
        list.add("connection.pool.size.max");
        list.add("connection.pool.size.min");
        list.add("connection.port");
        list.add("file.bulk.length");
        list.add("file.bulk.size");

        return list;
    }

    /**
     * @return the CREATE TABLE statement
     */
    public final String getSqlCreateTable() {
        return sqlCreateTable;
    }

    /**
     * @return the DROP TABLE statement
     */
    public final String getSqlDropTable() {
        return sqlDropTable;
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
     * Resets the runtime configuration parameters to "n/a".
     */
    public final void resetNotAvailables() {

        List<String> list = getNotAvailables();

        boolean isChanged = false;

        for (final Iterator<String> iterator = list.iterator(); iterator.hasNext();) {
            final String key = iterator.next();

            if (!(propertiesConfiguration.getString(key).equals("n/a"))) {
                propertiesConfiguration.setProperty(key, "n/a");
                isChanged = true;
            }

        }

        if (isChanged) {
            try {
                fileBasedConfigurationBuilder.save();
                propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
            } catch (ConfigurationException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * @param benchmarkDriver the name of the applied driver to set
     */
    public final void setBenchmarkDriver(String benchmarkDriver) {
        this.benchmarkDriver = benchmarkDriver;
    }

    private final void storeConfiguration() {
        propertiesConfiguration.setThrowExceptionOnMissing(true);

        benchmarkBatchSize = propertiesConfiguration.getInt("benchmark.batch.size");
        benchmarkComment = propertiesConfiguration.getString("benchmark.comment");
        benchmarkDatabase = propertiesConfiguration.getString("benchmark.database");
        benchmarkDriver = propertiesConfiguration.getString("benchmark.driver");
        benchmarkHostName = propertiesConfiguration.getString("benchmark.host.name");
        benchmarkId = propertiesConfiguration.getString("benchmark.id");
        benchmarkModule = "OraBench (Java " + System.getProperty("java.version") + ")";
        benchmarkNumberProcessors = Integer.toString(Runtime.getRuntime().availableProcessors());
        benchmarkOs = propertiesConfiguration.getString("benchmark.os");
        benchmarkProgramNameOranifC = propertiesConfiguration.getString("benchmark.program.name.oranif.c");
        benchmarkTransactionSize = propertiesConfiguration.getInt("benchmark.transaction.size");
        benchmarkTrials = propertiesConfiguration.getInt("benchmark.trials");
        benchmarkUserName = propertiesConfiguration.getString("benchmark.user.name");

        connectionFetchSize = propertiesConfiguration.getInt("connection.fetch.size");
        connectionHost = propertiesConfiguration.getString("connection.host");
        connectionPassword = propertiesConfiguration.getString("connection.password");
        connectionPoolSizeMax = propertiesConfiguration.getInt("connection.pool.size.max");
        connectionPoolSizeMin = propertiesConfiguration.getInt("connection.pool.size.min");
        connectionPort = propertiesConfiguration.getInt("connection.port");
        connectionService = propertiesConfiguration.getString("connection.service");
        connectionString = propertiesConfiguration.getString("connection.string");
        connectionUser = propertiesConfiguration.getString("connection.user");

        fileBulkDelimiter = propertiesConfiguration.getString("file.bulk.delimiter");
        fileBulkLength = propertiesConfiguration.getInt("file.bulk.length");
        fileBulkHeader = propertiesConfiguration.getString("file.bulk.header");
        fileBulkName = propertiesConfiguration.getString("file.bulk.name");
        fileBulkSize = propertiesConfiguration.getInt("file.bulk.size");
        fileConfigurationName = propertiesConfiguration.getString("file.configuration.name");
        fileConfigurationNameCxOraclePython = propertiesConfiguration.getString("file.configuration.name.cx_oracle.python");
        fileConfigurationNameOranifC = propertiesConfiguration.getString("file.configuration.name.oranif.c");
        fileConfigurationNameOranifErlang = propertiesConfiguration.getString("file.configuration.name.oranif.erlang");
        fileResultDelimiter = propertiesConfiguration.getString("file.result.delimiter");
        fileResultHeader = propertiesConfiguration.getString("file.result.header").replace(";", fileResultDelimiter);
        fileResultName = propertiesConfiguration.getString("file.result.name");

        sqlCreateTable = propertiesConfiguration.getString("sql.create");
        sqlDropTable = propertiesConfiguration.getString("sql.drop");
        sqlInsert = propertiesConfiguration.getString("sql.insert");
        sqlSelect = propertiesConfiguration.getString("sql.select");
    }

    private final void updatePropertiesFromOs() {

        Map<String, String> environmentVariables = System.getenv();

        boolean isChanged = false;

        if (environmentVariables.containsKey("ORA_BENCH_BATCH_SIZE")) {
            benchmarkBatchSize = Integer.parseInt(environmentVariables.get("ORA_BENCH_BATCH_SIZE"));
            propertiesConfiguration.setProperty("benchmark.batch.size", benchmarkBatchSize);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_COMMENT")) {
            benchmarkComment = environmentVariables.get("ORA_BENCH_BENCHMARK_COMMENT");
            propertiesConfiguration.setProperty("benchmark.comment", benchmarkComment);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DATABASE")) {
            benchmarkDatabase = environmentVariables.get("ORA_BENCH_BENCHMARK_DATABASE");
            propertiesConfiguration.setProperty("benchmark.database", benchmarkDatabase);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DRIVER")) {
            benchmarkDriver = environmentVariables.get("ORA_BENCH_BENCHMARK_DRIVER");
            propertiesConfiguration.setProperty("benchmark.driver", benchmarkDriver);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_NUMBER_PROCESSES")) {
            benchmarkNumberProcessors = environmentVariables.get("ORA_BENCH_BENCHMARK_NUMBER_PROCESSES");
            propertiesConfiguration.setProperty("benchmark.number.processes", benchmarkNumberProcessors);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_TRANSACTION_SIZE")) {
            benchmarkTransactionSize = Integer.parseInt(environmentVariables.get("ORA_BENCH_TRANSACTION_SIZE"));
            propertiesConfiguration.setProperty("benchmark.transaction.size", benchmarkTransactionSize);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_HOST")) {
            connectionHost = environmentVariables.get("ORA_BENCH_CONNECTION_HOST");
            propertiesConfiguration.setProperty("connection.host", connectionHost);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_PORT")) {
            connectionPort = Integer.parseInt(environmentVariables.get("ORA_BENCH_CONNECTION_PORT"));
            propertiesConfiguration.setProperty("connection.port", connectionPort);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_SERVICE")) {
            connectionService = environmentVariables.get("ORA_BENCH_CONNECTION_SERVICE");
            propertiesConfiguration.setProperty("connection.service", connectionService);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_FILE_CONFIGURATION_NAME")) {
            fileConfigurationName = environmentVariables.get("ORA_BENCH_FILE_CONFIGURATION_NAME");
            propertiesConfiguration.setProperty("file.configuration.name", fileConfigurationName);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_FILE_RESULT_NAME")) {
            fileResultName = environmentVariables.get("ORA_BENCH_FILE_RESULT_NAME");
            propertiesConfiguration.setProperty("file.result.name", fileResultName);
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
    }

    private final void validateProperties() {

        boolean isChanged = false;

        if (benchmarkBatchSize < 0) {
            log.error("Attention: The value of the configuration parameter 'benchmark.batch.size' [" + Integer.toString(benchmarkBatchSize)
                    + "] must not be less than 0, the specified value is replaced by 0.");
            benchmarkBatchSize = 0;
            propertiesConfiguration.setProperty("benchmark.batch.size", benchmarkBatchSize);
            isChanged = true;
        }

        if (benchmarkHostName.equals("n/a")) {
            try {
                benchmarkHostName = InetAddress.getLocalHost().getHostName();
            } catch (UnknownHostException e) {
                e.printStackTrace();
            }
            propertiesConfiguration.setProperty("benchmark.host.name", benchmarkHostName);
            isChanged = true;
        }

        if (benchmarkNumberProcessors.equals("n/a")) {
            benchmarkNumberProcessors = Integer.toString(Runtime.getRuntime().availableProcessors());
            propertiesConfiguration.setProperty("benchmark.number.processors", benchmarkNumberProcessors);
            isChanged = true;
        }

        if (benchmarkOs.equals("n/a")) {
            benchmarkOs = System.getProperty("os.arch") + " / " + System.getProperty("os.name") + " / " + System.getProperty("os.version");
            propertiesConfiguration.setProperty("benchmark.os", benchmarkOs);
            isChanged = true;
        }

        if (benchmarkTransactionSize < benchmarkBatchSize) {
            log.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + Integer.toString(benchmarkTransactionSize)
                    + "] must not be less than value of the configuration parameter 'benchmark.batch.size' [" + Integer.toString(benchmarkBatchSize)
                    + "], the specified value of the configuration parameter 'benchmark.transaction.size' is replaced by "
                    + Integer.toString(benchmarkBatchSize) + ".");
            benchmarkTransactionSize = benchmarkBatchSize;
            propertiesConfiguration.setProperty("benchmark.batch.size", benchmarkTransactionSize);
            isChanged = true;
        }

        if (benchmarkTransactionSize < 0) {
            log.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + Integer.toString(benchmarkTransactionSize)
                    + "] must not be less than 0, the specified value is replaced by 0.");
            benchmarkTransactionSize = 0;
            propertiesConfiguration.setProperty("benchmark.batch.size", benchmarkTransactionSize);
            isChanged = true;
        }

        if (benchmarkTrials < 1) {
            log.error("Attention: The value of the configuration parameter 'benchmark.trials' [" + Integer.toString(benchmarkTrials)
                    + "] must not be less than 1, the specified value is replaced by 1.");
            benchmarkTrials = 1;
            propertiesConfiguration.setProperty("benchmark.trials", benchmarkTrials);
            isChanged = true;
        }

        if (benchmarkUserName.equals("n/a")) {
            benchmarkUserName = System.getProperty("user.name");
            propertiesConfiguration.setProperty("benchmark.user.name", benchmarkUserName);
            isChanged = true;
        }

        if (connectionFetchSize < 0) {
            log.error("Attention: The value of the configuration parameter 'connection.fetch.size' [" + Integer.toString(connectionFetchSize)
                    + "] must not be less than 0, the specified value is replaced by 0.");
            connectionFetchSize = 0;
            propertiesConfiguration.setProperty("connection.fetch.size", connectionFetchSize);
            isChanged = true;
        }

        if (connectionPoolSizeMax < 0) {
            log.error("Attention: The value of the configuration parameter 'connection.pool.size.max' [" + Integer.toString(connectionPoolSizeMax)
                    + "] must not be less than 0, the specified value is replaced by 0.");
            connectionPoolSizeMax = 0;
            propertiesConfiguration.setProperty("connection.pool.size.max", connectionPoolSizeMax);
            isChanged = true;
        }

        if (connectionPoolSizeMin < 0) {
            log.error("Attention: The value of the configuration parameter 'connection.pool.size.min' [" + Integer.toString(connectionPoolSizeMin)
                    + "] must not be less than 0, the specified value is replaced by 0.");
            connectionPoolSizeMin = 0;
            propertiesConfiguration.setProperty("connection.pool.size.min", connectionPoolSizeMin);
            isChanged = true;
        }

        if (connectionPoolSizeMin < connectionPoolSizeMax) {
            log.error("Attention: The value of the configuration parameter 'connection.pool.size.min' [" + Integer.toString(connectionPoolSizeMin)
                    + "] must not be greater than value of the configuration parameter 'connection.pool.size.max' [\" + Integer.toString(connectionPoolSizeMax)"
                    + "], the specified value is replaced by Integer.toString(connectionPoolSizeMax).");
            connectionPoolSizeMin = connectionPoolSizeMax;
            propertiesConfiguration.setProperty("connection.pool.size.min", connectionPoolSizeMin);
            isChanged = true;
        }

        if (fileBulkLength < 80) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + Integer.toString(fileBulkLength)
                    + "] must not be less than 80, the specified value is replaced by 80.");
            fileBulkLength = 80;
            propertiesConfiguration.setProperty("file.bulk.length", fileBulkLength);
            isChanged = true;
        } else if (fileBulkLength > 4000) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + Integer.toString(fileBulkLength)
                    + "] must not be greater than 4000, the specified value is replaced by 4000.");
            fileBulkLength = 80;
            propertiesConfiguration.setProperty("file.bulk.length", fileBulkLength);
            isChanged = true;
        }

        if (fileBulkSize < 1) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.size' [" + Integer.toString(fileBulkSize)
                    + "] must not be less than 1, the specified value is replaced by 1.");
            fileBulkSize = 1;
            propertiesConfiguration.setProperty("file.bulk.size", fileBulkSize);
            isChanged = true;
        }

        if (benchmarkId.equals("n/a")) {
            benchmarkId = DigestUtils.md5Hex(LocalDateTime.now().format(formatter) + benchmarkHostName + benchmarkOs + benchmarkUserName);
            propertiesConfiguration.setProperty("benchmark.id", benchmarkId);
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
    }

}
