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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * The database support class for the Oracle JDBC benchmark tests. This creates
 * a database connection. The database parameters must be provided via an
 * {@link Config} object.
 */
public class Database {

  private static final Logger  logger  = LogManager.getLogger(Database.class);
  private final static boolean isDebug = logger.isDebugEnabled();
  private final Config         config;
  private final String         connectionHost;
  private final String         connectionPassword;
  private final int            connectionPort;
  private final String         connectionService;
  private final String         connectionUser;
  private Connection           connection;

  /**
   * Constructs a Database object using the given {@link Config} object.
   *
   * @param config the {@link Config} object
   */
  public Database(Config config) {
    if (isDebug) {
      logger.debug("Start");
    }

    this.config        = config;
    connectionHost     = config.getConnectionHost();
    connectionPassword = config.getConnectionPassword();
    connectionPort     = config.getConnectionPort();
    connectionService  = config.getConnectionService();
    connectionUser     = config.getConnectionUser();

    if (isDebug) {
      logger.debug("End");
    }
  }

  /**
   * Creates a database connection.
   *
   * @return the database connection
   */
  public final Connection connect() {
    if (isDebug) {
      logger.debug("Start");
    }

    final String url = "jdbc:oracle:thin:@//" + connectionHost + ":" + connectionPort + "/" + connectionService + "?oracle.net.disableOob=true";

    if (connection == null) {
      try {
        connection = DriverManager.getConnection(url,
                                                 connectionUser,
                                                 connectionPassword);
        DatabaseMetaData meta = connection.getMetaData();
        config.setBenchmarkDriver("Oracle JDBC (Version " + meta.getDriverVersion() + ")");
      } catch (SQLException ec) {
        logger.error("connection parameter url     =: " + url);
        logger.error("connection parameter username=: " + connectionUser);
        logger.error("connection parameter password=: " + connectionPassword);
        ec.printStackTrace();
      }
    }

    if (isDebug) {
      logger.debug("End");
    }

    return connection;
  }
}
