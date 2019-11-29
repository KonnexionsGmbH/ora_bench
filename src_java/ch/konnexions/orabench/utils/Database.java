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

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * The database support class for the Oracle JDBC benchmark tests. This creates
 * a database connection. The database parameters must be provided via an
 * {@link Config} object.
 */
public class Database {

    private Config config;
    private Connection connection;
    private String connectionHost;
    private String connectionPassword;
    private int connectionPort;
    private String connectionService;
    private String connectionUser;

    private final Logger log = new Logger(Database.class);

    /**
     * Constructs a Database object using the given {@link Config} object.
     *
     * @param config the {@link Config} object
     */
    public Database(Config config) {
        this.config = config;
        connectionHost = config.getConnectionHost();
        connectionPassword = config.getConnectionPassword();
        connectionPort = config.getConnectionPort();
        connectionService = config.getConnectionService();
        connectionUser = config.getConnectionUser();
    }

    /**
     * Creates a database connection.
     *
     * @return the database connection
     */
    public final Connection connect() {
        final String url = "jdbc:oracle:thin:@//" + connectionHost + ":" + String.valueOf(connectionPort) + "/" + connectionService;

        if (connection == null) {
            try {
                connection = DriverManager.getConnection(url, connectionUser, connectionPassword);
                DatabaseMetaData meta = connection.getMetaData();
                config.setBenchmarkDriver("JDBC (Version " + meta.getDriverVersion() + ")");
            } catch (SQLException ec) {
                log.error("connection parameter url     =: " + url);
                log.error("connection parameter username=: " + connectionUser);
                log.error("connection parameter password=: " + connectionPassword);
                ec.printStackTrace();
            }
        }

        return connection;
    }
}
