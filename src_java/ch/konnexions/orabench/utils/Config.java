/*
 *
 */

package ch.konnexions.orabench.utils;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

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
 * <li>benchmark.environment
 * <li>benchmark.module
 * <li>benchmark.program.name.oranif.c
 * <li>benchmark.transaction.size
 * <li>benchmark.trials
 * <li>connection.host
 * <li>connection.password
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
 * <li>file.result.detailed.delimiter
 * <li>file.result.detailed.header
 * <li>file.result.detailed.name
 * <li>file.result.statistical.delimiter
 * <li>file.result.statistical.header
 * <li>file.result.statistical.name
 * <li>sql.create
 * <li>sql.drop
 * <li>sql.insert.jamdb
 * <li>sql.insert.oracle
 * <li>sql.select
 * </ul>
 * The parameter name and parameter value must be separated by an equal sign
 * (=).
 */
public class Config {

    private int benchmarkBatchSize;
    private String benchmarkComment;
    private String benchmarkDatabase;
    private String benchmarkDriver;
    private String benchmarkEnvironment;
    private String benchmarkModule;
    private String benchmarkProgramNameOranifC;
    private int benchmarkTransactionSize;
    private int benchmarkTrials;

    private final File configFile = new File(System.getenv("ORA_BENCH_FILE_CONFIGURATION_NAME"));
    private String connectionHost;
    private String connectionPassword;
    private int connectionPort;
    private String connectionService;
    private String connectionString;
    private String connectionUser;

    private List<String> delimiterProperties = Arrays.asList("file.bulk.delimiter", "file.result.detailed.delimiter", "file.result.statisical.delimiter");

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
    private String fileResultDetailedDelimiter;
    private String fileResultDetailedHeader;
    private String fileResultDetailedName;
    private String fileResultStatisticalDelimiter;
    private String fileResultStatisticalHeader;
    private String fileResultStatisticalName;

    private ArrayList<String> keysSorted = new ArrayList<String>();

    // private static Logger log = new Logger(Config.class);

    private List<String> numericProperties = getNumericProperties();

    private PropertiesConfiguration propertiesConfiguration;

    private String sqlCreateTable;
    private String sqlDropTable;
    private String sqlInsertJamdb;
    private String sqlInsertOracle;
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
            updatePropertiesFromEnvironment();
            keysSorted = getKeysSorted(propertiesConfiguration);
        } catch (ConfigurationException e) {
            e.printStackTrace();
        }

        storeConfiguration();
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

                final String quote = (delimiterProperties.contains(key.toLowerCase())) ? "" : "'";

                bufferedWriter.write(key + " = " + quote + propertiesConfiguration.getString(key) + quote);
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
     * @return the operating system description
     */
    public final String getBenchmarkEnvironment() {
        return System.getProperty("os.arch") + " / " + System.getProperty("os.name") + " / " + System.getProperty("os.version");
    }

    /**
     * @return the applied module name its programming language with name and
     *         version
     */
    public final String getBenchmarkModule() {
        return benchmarkModule;
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
     * @return the delimiter character of the detailed result file
     */
    public final String getFileResultDetailedDelimiter() {
        return fileResultDetailedDelimiter;
    }

    /**
     * @return the header line of the detailed result file
     */
    public final String getFileResultDetailedHeader() {
        return fileResultDetailedHeader;
    }

    /**
     * @return the name of the detailed result file containing the benchmark
     *         results. The file name may contain the absolute or relative file
     *         path.
     */
    public final String getFileResultDetailedName() {
        return fileResultDetailedName;
    }

    /**
     * @return the delimiter character of the statistical result file
     */
    public final String getFileResultStatisticalDelimiter() {
        return fileResultStatisticalDelimiter;
    }

    /**
     * @return the header line of the statistical result file
     */
    public final String getFileResultStatisticalHeader() {
        return fileResultStatisticalHeader;
    }

    /**
     * @return the name of the statistical result file containing the benchmark
     *         results. The file name may contain the absolute or relative file
     *         path.
     */
    public final String getFileResultStatisticalName() {
        return fileResultStatisticalName;
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
        list.add("benchmark.environment");
        list.add("benchmark.module");
        list.add("connection.service");

        return list;
    }

    private final List<String> getNumericProperties() {
        List<String> list = new ArrayList<String>();

        list.add("benchmark.batch.size");
        list.add("benchmark.transaction.size");
        list.add("benchmark.trials");
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
     * @return the INSERT statement for JamDB
     */
    public final String getSqlInsertJamdb() {
        return sqlInsertJamdb;
    }

    /**
     * @return the INSERT statement for Oracle
     */
    public final String getSqlInsertOracle() {
        return sqlInsertOracle;
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
        benchmarkEnvironment = propertiesConfiguration.getString("benchmark.environment");
        benchmarkModule = "OraBench (Java " + System.getProperty("java.version") + ")";
        benchmarkProgramNameOranifC = propertiesConfiguration.getString("benchmark.program.name.oranif.c");
        benchmarkTransactionSize = propertiesConfiguration.getInt("benchmark.transaction.size");
        benchmarkTrials = propertiesConfiguration.getInt("benchmark.trials");

        connectionHost = propertiesConfiguration.getString("connection.host");
        connectionPassword = propertiesConfiguration.getString("connection.password");
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
        fileResultDetailedDelimiter = propertiesConfiguration.getString("file.result.detailed.delimiter");
        fileResultDetailedHeader = propertiesConfiguration.getString("file.result.detailed.header").replace(";", fileResultDetailedDelimiter);
        fileResultDetailedName = propertiesConfiguration.getString("file.result.detailed.name");
        fileResultStatisticalDelimiter = propertiesConfiguration.getString("file.result.statistical.delimiter");
        fileResultStatisticalHeader = propertiesConfiguration.getString("file.result.statistical.header").replace(";", fileResultStatisticalDelimiter);
        fileResultStatisticalName = propertiesConfiguration.getString("file.result.statistical.name");

        sqlCreateTable = propertiesConfiguration.getString("sql.create");
        sqlDropTable = propertiesConfiguration.getString("sql.drop");
        sqlInsertJamdb = propertiesConfiguration.getString("sql.insert.jamdb");
        sqlInsertOracle = propertiesConfiguration.getString("sql.insert.oracle");
        sqlSelect = propertiesConfiguration.getString("sql.select");
    }

    private final void updatePropertiesFromEnvironment() {

        Map<String, String> environmentVariables = System.getenv();

        boolean isChanged = false;

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

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_ENVIRONMENT")) {
            benchmarkEnvironment = environmentVariables.get("ORA_BENCH_BENCHMARK_ENVIRONMENT");
            propertiesConfiguration.setProperty("benchmark.environment", benchmarkEnvironment);
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

        if (environmentVariables.containsKey("ORA_BENCH_FILE_RESULT_DETAILED_NAME")) {
            fileResultDetailedName = environmentVariables.get("ORA_BENCH_FILE_RESULT_DETAILED_NAME");
            propertiesConfiguration.setProperty("file.result.detailed.name", fileResultDetailedName);
            isChanged = true;
        }

        if (environmentVariables.containsKey("ORA_BENCH_FILE_RESULT_STATISTICAL_NAME")) {
            fileResultStatisticalName = environmentVariables.get("ORA_BENCH_FILE_RESULT_STATISTICAL_NAME");
            propertiesConfiguration.setProperty("file.result.statistical.name", fileResultStatisticalName);
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
