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

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * A simple logging class abstracting underlying logging APIs. The six logging
 * levels used by Log are (in order):
 * <ul>
 * <li>trace (the least serious)
 * <li>debug
 * <li>info
 * <li>warn
 * <li>error
 * <li>fatal (the most serious).
 * </ul>
 */
public class Logger {

    private final Log log;

    /**
     * Constructs a Logger object using the given class.
     *
     * @param classToBelogged Class for which a suitable Log name will be derived
     */
    public Logger(Class<?> classToBelogged) {
        System.setProperty("org.apache.commons.logging.Log", "org.apache.commons.logging.impl.SimpleLog");
        System.setProperty("org.apache.commons.logging.simplelog.dateTimeFormat", "yyyy-MM-dd HH:mm:ss:SSS");
        System.setProperty("org.apache.commons.logging.simplelog.defaultlog", "info");
        System.setProperty("org.apache.commons.logging.simplelog.showdatetime", "true");
        System.setProperty("org.apache.commons.logging.simplelog.showlogname", "true");
        System.setProperty("org.apache.commons.logging.simplelog.showShortLogname", "true");

        log = LogFactory.getLog(classToBelogged);
    }

    /**
     * Logs a message with debug log level.
     *
     * @param message log this message
     */
    public final void debug(Object message) {
        log.debug(message);
    }

    /**
     * Logs a message with error log level..
     *
     * @param message log this message
     */
    public final void error(Object message) {
        log.error(message);
    }

    /**
     * Logs a message with info log level..
     *
     * @param message log this message
     */
    public final void info(Object message) {
        log.info(message);
    }

}
