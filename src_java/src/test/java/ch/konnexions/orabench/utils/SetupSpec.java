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

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import java.sql.Connection;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

public class SetupSpec {
  @Test
  @DisplayName("creation of the bulk file")
  public void connect() throws Exception {
    Config config       = new Config();

    Setup  setup        = new Setup(config);

    String fileBulkName = config.getFileBulkName();
    assertNotNull(fileBulkName,
                  () -> "Property .");

    fileBulkName = config.getFileBulkName();
    assertNotNull(fileBulkName,
                  () -> "The same database connection should be used.");

    setup.createBulkFile();

    Database   database     = new Database(config);

    Connection connection_1 = database.connect();
    Connection connection_2 = database.connect();

    assertEquals(connection_1,
                 connection_2,
                 () -> "The same database connection should be used.");
  }
}
