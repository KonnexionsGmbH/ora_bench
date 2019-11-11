/*
 * 
 */

package ch.konnexions.orabench.utils;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
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
 * <p>
 * <ul>
 * <li>benchmark.batch.size
 * <li>benchmark.comment
 * <li>benchmark.database
 * <li>benchmark.environment
 * <li>benchmark.program.name.c
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
 * <li>file.configuration.name.c
 * <li>file.configuration.name.erlang
 * <li>file.result.delimiter
 * <li>file.result.header
 * <li>file.result.name
 * <li>file.summary.delimiter
 * <li>file.summary.header
 * <li>file.summary.name
 * <li>sql.create
 * <li>sql.drop
 * <li>sql.insert.jamdb
 * <li>sql.insert.oracle
 * <li>sql.select
 * </ul>
 * <p>
 * The parameter name and parameter value must be separated by an equal sign
 * (=).
 */
public class Config {

    private int benchmarkBatchSize;
    private String benchmarkComment;
    private String benchmarkDatabase;
    private String benchmarkEnvironment;
    private String benchmarkProgramNameC;
    private int benchmarkTrials;

    private final File configFile = new File(System.getenv("ORA_BENCH_FILE_CONFIGURATION_NAME"));
    private String connectionHost;
    private String connectionPassword;
    private int connectionPort;
    private String connectionService;
    private String connectionString;
    private String connectionUser;

    FileBasedConfigurationBuilder<PropertiesConfiguration> fileBasedConfigurationBuilder;
    private String fileBulkDelimiter;
    private String fileBulkHeader;
    private int fileBulkLength;
    private String fileBulkName;
    private int fileBulkSize;
    private String fileConfigurationName;
    private String fileConfigurationNameC;
    private String fileConfigurationNameErlang;
    private String fileResultDelimiter;
    private String fileResultHeader;
    private String fileResultName;
    private String fileSummaryDelimiter;
    private String fileSummaryHeader;
    private String fileSummaryName;

    // private static Logger log = new Logger(Config.class);

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
        } catch (ConfigurationException e) {
            e.printStackTrace();
        }

        storeConfiguration();
    }

    /**
     * Creates the C version of the configuration file.
     */
    public void createConfigurationFileC() throws ConfigurationException {
        try {
            List<String> list = getNumericProperties();

            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameC(), false));

            bufferedWriter.write("#!/bin/bash");
            bufferedWriter.newLine();
            bufferedWriter.newLine();
            bufferedWriter.write("# ------------------------------------------------------------------------------");
            bufferedWriter.newLine();
            bufferedWriter.write("#");
            bufferedWriter.newLine();
            bufferedWriter.write("# run_bench_c.sh: Oracle Benchmark based on C.");
            bufferedWriter.newLine();
            bufferedWriter.write("#");
            bufferedWriter.newLine();
            bufferedWriter.write("# ------------------------------------------------------------------------------");
            bufferedWriter.newLine();
            bufferedWriter.newLine();

            try {
                propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
            } catch (ConfigurationException e1) {
                e1.printStackTrace();
            }

            for (final Iterator<String> iterator = propertiesConfiguration.getKeys(); iterator.hasNext();) {
                final String key = iterator.next();

                final String quote = (list.contains(key.toLowerCase())) ? "" : "'";

                bufferedWriter.write("ORA_BENCH_" + key.replace(".", "_").toUpperCase() + "=" + quote + propertiesConfiguration.getString(key) + quote);
                bufferedWriter.newLine();
            }

            bufferedWriter.newLine();
            bufferedWriter.write("echo \"================================================================================\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"Start $0\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"--------------------------------------------------------------------------------\"");
            bufferedWriter.newLine();
            bufferedWriter.write("echo \"ora_bench - Oracle benchmark - C.\"");
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
            bufferedWriter.write("./" + getBenchmarkProgramNameC() + " ");

            for (final Iterator<String> iterator = propertiesConfiguration.getKeys(); iterator.hasNext();) {
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
     * Creates the Erlang version of the configuration file.
     */
    public void createConfigurationFileErlang() {
        try {
            List<String> list = getNumericProperties();

            BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(getFileConfigurationNameErlang(), false));

            bufferedWriter.write("#{");
            bufferedWriter.newLine();

            try {
                propertiesConfiguration = fileBasedConfigurationBuilder.getConfiguration();
            } catch (ConfigurationException e) {
                e.printStackTrace();
            }

            for (final Iterator<String> iterator = propertiesConfiguration.getKeys(); iterator.hasNext();) {
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
     * Gets the batch size of the INSERT operation.
     *
     * @return the batch size
     */
    public final int getBenchmarkBatchSize() {
        return benchmarkBatchSize;
    }

    /**
     * Gets the benchmark specific comment.
     *
     * @return the benchmark specific comment
     */
    public final String getBenchmarkComment() {
        return benchmarkComment;
    }

    /**
     * Gets the database description.
     *
     * @return the database description
     */
    public final String getBenchmarkDatabase() {
        return benchmarkDatabase;
    }

    /**
     * Gets the environment description.
     *
     * @return the environment description
     */
    public final String getBenchmarkEnvironment() {
        return benchmarkEnvironment;
    }

    /**
     * Gets the C program name.
     *
     * @return the C program name
     */
    public final String getBenchmarkProgramNameC() {
        return benchmarkProgramNameC;
    }

    /**
     * Gets the number of benchmark trials to be carried out.
     *
     * @return the number of benchmark trials
     */
    public final int getBenchmarkTrials() {
        return benchmarkTrials;
    }

    /**
     * Gets the host name of the database.
     *
     * @return the host name or the IP address
     */
    public final String getConnectionHost() {
        return connectionHost;
    }

    /**
     * Gets the password to connect to the database.
     *
     * @return the password
     */
    public final String getConnectionPassword() {
        return connectionPassword;
    }

    /**
     * Gets the port number where the database server is listening for requests.
     *
     * @return the port number
     */
    public final int getConnectionPort() {
        return connectionPort;
    }

    /**
     * Gets the service name to connect to the database.
     *
     * @return the service name
     */
    public final String getConnectionService() {
        return connectionService;
    }

    /**
     * Gets the connection string.
     *
     * @return the connection string
     */
    public final String getConnectionString() {
        return connectionString;
    }

    /**
     * Gets the user name to connect to the database.
     *
     * @return the user name
     */
    public final String getConnectionUser() {
        return connectionUser;
    }

    /**
     * Gets the delimiter character of the bulk file.
     *
     * @return the delimiter character of the bulk file
     */
    public final String getFileBulkDelimiter() {
        return fileBulkDelimiter;
    }

    /**
     * Gets the the bulk header.
     *
     * @return the bulk header
     */
    public final String getFileBulkHeader() {
        return fileBulkHeader;
    }

    /**
     * Gets the length of a test column value.
     *
     * @return the length of a test column value
     */
    public final int getFileBulkLength() {
        return fileBulkLength;
    }

    /**
     * Gets the file name of the text file with the example data (bulk data file).
     *
     * @return the name of the bulk data file. The file name may contain the
     *         absolute or relative file path.
     */
    public final String getFileBulkName() {
        return fileBulkName;
    }

    /**
     * Gets the number of different test column values.
     *
     * @return the number of different test column values
     */
    public final int getFileBulkSize() {
        return fileBulkSize;
    }

    /**
     * Gets the file name of the configuration file.
     *
     * @return the name of the configuration file. The file name may contain the
     *         absolute or relative file path.
     */
    public final String getFileConfigurationName() {
        return fileConfigurationName;
    }

    /**
     * Gets the file name of the configuration file for the C programming language.
     *
     * @return the name of the configuration file for the C programming language.
     *         The file name may contain the absolute or relative file path.
     */
    public final String getFileConfigurationNameC() {
        return fileConfigurationNameC;
    }

    /**
     * Gets the file name of the configuration file for the Erlang programming
     * language.
     *
     * @return the name of the configuration file for the Erlang programming
     *         language. The file name may contain the absolute or relative file
     *         path.
     */
    public final String getFileConfigurationNameErlang() {
        return fileConfigurationNameErlang;
    }

    /**
     * Gets the delimiter character of the result file.
     *
     * @return the delimiter character of the result file
     */
    public final String getFileResultDelimiter() {
        return fileResultDelimiter;
    }

    /**
     * Gets the the result header.
     *
     * @return the result header
     */
    public final String getFileResultHeader() {
        return fileResultHeader;
    }

    /**
     * Gets the file name of the result file containing the benchmark results.
     *
     * @return the name of the result file. The file name may contain the absolute
     *         or relative file path.
     */
    public final String getFileResultName() {
        return fileResultName;
    }

    /**
     * Gets the delimiter character of the summary file.
     *
     * @return the delimiter character of the summary file
     */
    public final String getFileSummaryDelimiter() {
        return fileSummaryDelimiter;
    }

    /**
     * Gets the the summary header.
     *
     * @return the summary header
     */
    public final String getFileSummaryHeader() {
        return fileSummaryHeader;
    }

    /**
     * Gets the file name of the summary file containing the benchmark summaries.
     *
     * @return the name of the summary file. The file name may contain the absolute
     *         or relative file path.
     */
    public final String getFileSummaryName() {
        return fileSummaryName;
    }

    private List<String> getNumericProperties() {
        List<String> list = new ArrayList<String>();

        list.add("benchmark.batch.size");
        list.add("benchmark.trials");
        list.add("file.bulk.length");
        list.add("file.bulk.size");
        list.add("connection.port");

        return list;
    }

    /**
     * Gets the CREATE TABLE statement.
     *
     * @return the CREATE TABLE statement
     */
    public final String getSqlCreateTable() {
        return sqlCreateTable;
    }

    /**
     * Gets the DROP TABLE statement.
     *
     * @return the DROP TABLE statement
     */
    public final String getSqlDropTable() {
        return sqlDropTable;
    }

    /**
     * Gets the INSERT statement for JamDB.
     *
     * @return the INSERT statement
     */
    public final String getSqlInsertJamdb() {
        return sqlInsertJamdb;
    }

    /**
     * Gets the INSERT statement for Oracle.
     *
     * @return the INSERT statement
     */
    public final String getSqlInsertOracle() {
        return sqlInsertOracle;
    }

    /**
     * Gets the SELECT statement.
     *
     * @return the SELECT statement
     */
    public final String getSqlSelect() {
        return sqlSelect;
    }

    private void storeConfiguration() {
        propertiesConfiguration.setThrowExceptionOnMissing(true);

        benchmarkBatchSize = propertiesConfiguration.getInt("benchmark.batch.size");
        benchmarkComment = propertiesConfiguration.getString("benchmark.comment");
        benchmarkDatabase = propertiesConfiguration.getString("benchmark.database");
        benchmarkEnvironment = propertiesConfiguration.getString("benchmark.environment");
        benchmarkProgramNameC = propertiesConfiguration.getString("benchmark.program.name.c");
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
        fileConfigurationNameC = propertiesConfiguration.getString("file.configuration.name.c");
        fileConfigurationNameErlang = propertiesConfiguration.getString("file.configuration.name.erlang");
        fileResultDelimiter = propertiesConfiguration.getString("file.result.delimiter");
        fileResultHeader = propertiesConfiguration.getString("file.result.header").replace(";", fileResultDelimiter);
        fileResultName = propertiesConfiguration.getString("file.result.name");
        fileSummaryDelimiter = propertiesConfiguration.getString("file.summary.delimiter");
        fileSummaryHeader = propertiesConfiguration.getString("file.summary.header").replace(";", fileSummaryDelimiter);
        fileSummaryName = propertiesConfiguration.getString("file.summary.name");

        sqlCreateTable = propertiesConfiguration.getString("sql.create");
        sqlDropTable = propertiesConfiguration.getString("sql.drop");
        sqlInsertJamdb = propertiesConfiguration.getString("sql.insert.jamdb");
        sqlInsertOracle = propertiesConfiguration.getString("sql.insert.oracle");
        sqlSelect = propertiesConfiguration.getString("sql.select");
    }

    /**
     * Updates the properties from the environment variables.
     *
     * @throws ConfigurationException the configuration exception
     */
    public void updatePropertiesFromEnvironment() throws ConfigurationException {

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

        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_ENVIRONMENT")) {
            benchmarkEnvironment = environmentVariables.get("ORA_BENCH_BENCHMARK_ENVIRONMENT");
            propertiesConfiguration.setProperty("benchmark.database", benchmarkEnvironment);
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
            fileBasedConfigurationBuilder.save();
        }
    }

}
