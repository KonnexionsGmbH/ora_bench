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

import java.io.File;
import java.util.Map;

import org.apache.commons.configuration2.PropertiesConfiguration;
import org.apache.commons.configuration2.builder.FileBasedConfigurationBuilder;
import org.apache.commons.configuration2.builder.fluent.Parameters;
import org.apache.commons.configuration2.builder.fluent.PropertiesBuilderParameters;
import org.apache.commons.configuration2.ex.ConfigurationException;

/**
 * The configuration parameters for the Oracle JDBC benchmark tests. The
 * configuration parameters are made available to the configuration object in a
 * text file. This text file must contain the values of the following
 * configuration parameters:
 * <p>
 * <ul>
 * <li>connection.host
 * <li>connection.password
 * <li>connection.port
 * <li>connection.service
 * <li>connection.string
 * <li>connection.user
 * <li>file.bulk.length
 * <li>file.bulk.name
 * <li>file.bulk.size
 * <li>file.result.delimiter
 * <li>file.result.name
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

    private int benchmarkTrials;

    private String connectionHost;
    private String connectionPassword;
    private int connectionPort;
    private String connectionService;
    private String connectionString;
    private String connectionUser;

    private int fileBulkLength;
    private String fileBulkName;
    private int fileBulkSize;
    private String fileResultDelimiter;
    private String fileResultHeader;
    private String fileResultName;

    // private static Logger log = new Logger(Config.class);

    private String sqlCreateTable;
    private String sqlDropTable;
    private String sqlInsertJamdb;
    private String sqlInsertOracle;
    private String sqlSelect;

    /**
     * Constructs a Config object using the given parameter file name.
     *
     * @param configFile the configuration parameter file
     */
    public Config(File configFile) {
        super();

        PropertiesBuilderParameters propertyParameters = new Parameters().properties();

        propertyParameters.setFile(configFile);

        FileBasedConfigurationBuilder<PropertiesConfiguration> builder = new FileBasedConfigurationBuilder<PropertiesConfiguration>(
                PropertiesConfiguration.class);

        builder.configure(propertyParameters);

        Map<String, String> environmentVariables = System.getenv();

        try {
            PropertiesConfiguration config = builder.getConfiguration();

            config.setThrowExceptionOnMissing(true);

            boolean isChanged = false;

            if (environmentVariables.containsKey("ORABENCH_CONNECTION_HOST")) {
                config.setProperty("connection.host", environmentVariables.get("ORABENCH_CONNECTION_HOST"));
                isChanged = true;
            }

            if (environmentVariables.containsKey("ORABENCH_CONNECTION_PORT")) {
                config.setProperty("connection.port", environmentVariables.get("ORABENCH_CONNECTION_PORT"));
                isChanged = true;
            }

            if (environmentVariables.containsKey("ORABENCH_CONNECTION_SERVICE")) {
                config.setProperty("connection.service", environmentVariables.get("ORABENCH_CONNECTION_SERVICE"));
                isChanged = true;
            }

            if (environmentVariables.containsKey("ORABENCH_FILE_RESULT_NAME")) {
                config.setProperty("file.result.name", environmentVariables.get("ORABENCH_FILE_RESULT_NAME"));
                isChanged = true;
            }

            if (isChanged) {
                builder.save();
            }

            benchmarkTrials = config.getInt("benchmark.trials");

            connectionHost = config.getString("connection.host");
            connectionPassword = config.getString("connection.password");
            connectionPort = config.getInt("connection.port");
            connectionService = config.getString("connection.service");
            connectionString = config.getString("connection.string");
            connectionUser = config.getString("connection.user");

            fileBulkLength = config.getInt("file.bulk.length");
            fileBulkName = config.getString("file.bulk.name");
            fileBulkSize = config.getInt("file.bulk.size");
            fileResultDelimiter = config.getString("file.result.delimiter");
            fileResultHeader = config.getString("file.result.header");
            fileResultName = config.getString("file.result.name");

            sqlCreateTable = config.getString("sql.create");
            sqlDropTable = config.getString("sql.drop");
            sqlInsertJamdb = config.getString("sql.insert.jamdb");
            sqlInsertOracle = config.getString("sql.insert.oracle");
            sqlSelect = config.getString("sql.select");

        } catch (ConfigurationException e) {
            e.printStackTrace();
        }
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

}
