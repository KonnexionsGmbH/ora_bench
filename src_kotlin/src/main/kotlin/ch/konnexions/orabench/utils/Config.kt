/*
 *
 */
package ch.konnexions.orabench.utils

import org.apache.commons.codec.digest.DigestUtils
import org.apache.commons.configuration2.PropertiesConfiguration
import org.apache.commons.configuration2.builder.FileBasedConfigurationBuilder
import org.apache.commons.configuration2.builder.fluent.Parameters
import org.apache.commons.configuration2.ex.ConfigurationException
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.io.IOException
import java.net.InetAddress
import java.net.UnknownHostException
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * The configuration parameters for the Oracle JDBC benchmark tests. The
 * configuration parameters are made available to the configuration object in a
 * text file. This text file must contain the values of the following
 * configuration parameters:
 *
 *  * benchmark.batch.size
 *  * benchmark.comment
 *  * benchmark.core.multiplier
 *  * benchmark.database
 *  * benchmark.driver
 *  * benchmark.host.name
 *  * benchmark.id
 *  * benchmark.language
 *  * benchmark.number.cores
 *  * benchmark.number.partitions
 *  * benchmark.os
 *  * benchmark.release
 *  * benchmark.transaction.size
 *  * benchmark.trials
 *  * benchmark.user.name
 *  * connection.fetch.size
 *  * connection.host
 *  * connection.password
 *  * connection.port
 *  * connection.service
 *  * connection.user
 *  * file.bulk.delimiter
 *  * file.bulk.header
 *  * file.bulk.length
 *  * file.bulk.name
 *  * file.bulk.size
 *  * file.configuration.name
 *  * file.configuration.name.c
 *  * file.configuration.name.erlang
 *  * file.configuration.name.python
 *  * file.result.delimiter
 *  * file.result.header
 *  * file.result.name
 *  * sql.create
 *  * sql.drop
 *  * sql.insert
 *  * sql.select
 *
 * The parameter name and parameter value must be separated by an equal sign
 * (=).
 */
class Config {
    /**
     * @return the batch size of the INSERT operation
     */
    var benchmarkBatchSize = 0
        private set
    /**
     * @return the benchmark specific comment
     */
    var benchmarkComment: String? = null
        private set
    /**
     * @return the core multiplier for parallel processing
     */
    var benchmarkCoreMultiplier = 0
        private set
    /**
     * @return the database description
     */
    var benchmarkDatabase: String? = null
        private set
    /**
     * @return the applied driver name and its version
     */
    /**
     * @param benchmarkDriver the name of the applied driver to set
     */
    var benchmarkDriver: String? = null
    /**
     * @return the host name
     */
    var benchmarkHostName: String? = null
        private set
    /**
     * @return the benchmark identification
     */
    var benchmarkId: String? = null
        private set
    /**
     * @return the applied programming language with name and version
     */
    var benchmarkLanguage: String? = null
        private set
    /**
     * @return the number of cores
     */
    var benchmarkNumberCores: String? = null
        private set
    /**
     * @return the number of partitions
     */
    var benchmarkNumberPartitions = 0
        private set
    /**
     * @return the operating system description
     */
    var benchmarkOs: String? = null
        private set
    /**
     * @return the ora_bench release no.
     */
    var benchmarkRelease: String? = null
        private set
    /**
     * @return the transaction size of the INSERT operation
     */
    var benchmarkTransactionSize = 0
        private set
    /**
     * @return the number of benchmark trials to be carried out
     */
    var benchmarkTrials = 0
        private set
    /**
     * @return the user name
     */
    var benchmarkUserName: String? = null
        private set
    /**
     * @return how much data is pulled from the database across the network
     */
    var connectionFetchSize = 0
        private set
    /**
     * @return the host name or the IP address of the database
     */
    var connectionHost: String? = null
        private set
    /**
     * @return the password to connect to the database
     */
    var connectionPassword: String? = null
        private set
    /**
     * @return the port number where the database server is listening for requests
     */
    var connectionPort = 0
        private set
    /**
     * @return the service name to connect to the database
     */
    var connectionService: String? = null
        private set
    /**
     * @return the user name to connect to the database
     */
    var connectionUser: String? = null
        private set
    val fileBasedConfigurationBuilder: FileBasedConfigurationBuilder<PropertiesConfiguration> = FileBasedConfigurationBuilder(PropertiesConfiguration::class.java)
    /**
     * @return the delimiter character of the bulk data file
     */
    var fileBulkDelimiter: String? = null
        private set
    /**
     * @return the header line of the bulk data file
     */
    var fileBulkHeader: String? = null
        private set
    /**
     * @return the length of a test column value
     */
    var fileBulkLength = 0
        private set
    /**
     * @return the file name of the text file with the example data (bulk data
     * file). The file name may contain the absolute or relative file path.
     */
    var fileBulkName: String? = null
        private set
    /**
     * @return the number of different test column values
     */
    var fileBulkSize = 0
        private set
    private var fileConfigurationName: String? = null
    /**
     * @return the name of the configuration file for the C language version. The
     * file name may contain the absolute or relative file path.
     */
    var fileConfigurationNameC: String? = null
        private set
    /**
     * @return the name of the configuration file for the Erlang language version.
     * The file name may contain the absolute or relative file path.
     */
    var fileConfigurationNameErlang: String? = null
        private set
    /**
     * @return the name of the configuration file for the Python language version.
     * The file name may contain the absolute or relative file path.
     */
    var fileConfigurationNamePython: String? = null
        private set
    /**
     * @return the delimiter character of the result file
     */
    var fileResultDelimiter: String? = null
        private set
    /**
     * @return the header line of the result file
     */
    var fileResultHeader: String? = null
        private set
    /**
     * @return the name of the result file containing the benchmark results. The
     * file name may contain the absolute or relative file path.
     */
    var fileResultName: String? = null
        private set
    private val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.nnnnnnnnn")
    private var keysSorted = ArrayList<String>()
    private val log: Logger = Logger(Config::class.java)
    private var propertiesConfiguration: PropertiesConfiguration? = null
    /**
     * @return the CREATE TABLE statement
     */
    var sqlCreate: String? = null
        private set
    /**
     * @return the DROP TABLE statement
     */
    var sqlDrop: String? = null
        private set
    /**
     * @return the INSERT statement
     */
    var sqlInsert: String? = null
        private set
    /**
     * @return the SELECT statement
     */
    var sqlSelect: String? = null
        private set

    /**
     * Creates the C version of the configuration file.
     */
    fun createConfigurationFileC() {
        try {
            val bufferedWriter = BufferedWriter(FileWriter(fileConfigurationNameC, false))
            var value: String
            for (key in keysSorted) {
                if ("file.result.header".contentEquals(key)) {
                    value = propertiesConfiguration!!.getString(key).replace(";", fileResultDelimiter)
                } else {
                    value = propertiesConfiguration!!.getString(key)
                }
                val camelKey = StringBuilder()
                var i = 0
                while (i < key.length) {
                    if (key[i] == '.') {
                        camelKey.append(Character.toUpperCase(key[i + 1]))
                        ++i
                    } else {
                        camelKey.append(key[i])
                    }
                    ++i
                }
                bufferedWriter.write("$camelKey=$value")
                bufferedWriter.newLine()
            }
            bufferedWriter.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    /**
     * Creates the Erlang version of the configuration file.
     */
    fun createConfigurationFileErlang() {
        try {
            val list = numericProperties
            val bufferedWriter = BufferedWriter(FileWriter(fileConfigurationNameErlang, false))
            bufferedWriter.write("#{")
            bufferedWriter.newLine()
            var value: String
            val iterator: Iterator<String> = keysSorted.iterator()
            while (iterator.hasNext()) {
                val key = iterator.next()
                if ("file.result.header".contentEquals(key)) {
                    value = propertiesConfiguration!!.getString(key).replace(";", fileResultDelimiter)
                } else {
                    value = propertiesConfiguration!!.getString(key)
                }
                val quote = if (list.contains(key.toLowerCase())) "" else "\""
                bufferedWriter.write("    " + key.replace("", "_") + " => " + quote + value + quote)
                if (iterator.hasNext()) {
                    bufferedWriter.write(",")
                }
                bufferedWriter.newLine()
            }
            bufferedWriter.write("}.")
            bufferedWriter.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    /**
     * Creates the Python version of the configuration file.
     */
    fun createConfigurationFilePython() {
        try {
            val bufferedWriter = BufferedWriter(FileWriter(fileConfigurationNamePython, false))
            bufferedWriter.write("[DEFAULT]")
            bufferedWriter.newLine()
            var value: String
            for (key in keysSorted) {
                if ("file.result.header".contentEquals(key)) {
                    value = propertiesConfiguration!!.getString(key).replace(";", fileResultDelimiter)
                } else {
                    value = propertiesConfiguration!!.getString(key)
                }
                bufferedWriter.write(key + " = " + if (value.contentEquals("\t")) "TAB" else value)
                bufferedWriter.newLine()
            }
            bufferedWriter.close()
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    private fun getKeysSorted(): ArrayList<String> {
        val iterator = propertiesConfiguration!!.keys
        while (iterator.hasNext()) {
            keysSorted.add(iterator.next())
        }
        keysSorted.sort()
        return keysSorted
    }

    private val notAvailables: List<String>
        private get() {
            val list: MutableList<String> = ArrayList()
            list.add("benchmark.comment")
            list.add("benchmark.database")
            list.add("benchmark.driver")
            list.add("benchmark.host.name")
            list.add("benchmark.id")
            list.add("benchmark.language")
            list.add("benchmark.number.cores")
            list.add("benchmark.os")
            list.add("benchmark.user.name")
            list.add("connection.service")
            list.add("sql.create")
            return list
        }

    private val numericProperties: List<String>
        private get() {
            val list: MutableList<String> = ArrayList()
            list.add("benchmark.batch.size")
            list.add("benchmark.number.cores")
            list.add("benchmark.number.partitions")
            list.add("benchmark.transaction.size")
            list.add("benchmark.trials")
            list.add("connection.fetch.size")
            list.add("benchmark.core.multiplier")
            list.add("connection.pool.size.min")
            list.add("connection.port")
            list.add("file.bulk.length")
            list.add("file.bulk.size")
            return list
        }

    private val partitionString: CharSequence
        private get() {
            val stringBuffer = StringBuilder()
            for (i in 2..benchmarkNumberPartitions) {
                stringBuffer.append(", PARTITION p").append(String.format("%05d", i - 1)).append(" VALUES LESS THAN (").append(i).append(")")
            }
            return stringBuffer.toString()
        }

    /**
     * Resets selected runtime configuration parameters to the original default
     * value.
     */
    fun resetNotAvailables() {
        val list = notAvailables
        var isChanged = false
        for (key in list) {
            if (propertiesConfiguration!!.getString(key) != "n/a") {
                propertiesConfiguration!!.setProperty(key, "n/a")
                isChanged = true
            }
        }
        if (propertiesConfiguration!!.getInt("benchmark.core.multiplier") != 0) {
            propertiesConfiguration!!.setProperty("benchmark.core.multiplier", 0)
            isChanged = true
        }
        if (propertiesConfiguration!!.getInt("benchmark.number.partitions") != 0) {
            propertiesConfiguration!!.setProperty("benchmark.number.partitions", 0)
            isChanged = true
        }
        if (propertiesConfiguration!!.getString("connection.host") != "0.0.0.0") {
            propertiesConfiguration!!.setProperty("connection.host", "0.0.0.0")
            isChanged = true
        }
        if (isChanged) {
            try {
                fileBasedConfigurationBuilder.save()
                propertiesConfiguration = fileBasedConfigurationBuilder.configuration
            } catch (e: ConfigurationException) {
                e.printStackTrace()
            }
        }
    }

    private fun storeConfiguration() {
        propertiesConfiguration!!.isThrowExceptionOnMissing = true
        benchmarkBatchSize = propertiesConfiguration!!.getInt("benchmark.batch.size")
        benchmarkComment = propertiesConfiguration!!.getString("benchmark.comment")
        benchmarkCoreMultiplier = propertiesConfiguration!!.getInt("benchmark.core.multiplier")
        benchmarkDatabase = propertiesConfiguration!!.getString("benchmark.database")
        benchmarkDriver = propertiesConfiguration!!.getString("benchmark.driver")
        benchmarkHostName = propertiesConfiguration!!.getString("benchmark.host.name")
        benchmarkId = propertiesConfiguration!!.getString("benchmark.id")
        benchmarkNumberCores = propertiesConfiguration!!.getString("benchmark.number.cores")
        benchmarkNumberPartitions = propertiesConfiguration!!.getInt("benchmark.number.partitions")
        benchmarkOs = propertiesConfiguration!!.getString("benchmark.os")
        benchmarkRelease = propertiesConfiguration!!.getString("benchmark.release")
        benchmarkTransactionSize = propertiesConfiguration!!.getInt("benchmark.transaction.size")
        benchmarkTrials = propertiesConfiguration!!.getInt("benchmark.trials")
        benchmarkUserName = propertiesConfiguration!!.getString("benchmark.user.name")
        connectionFetchSize = propertiesConfiguration!!.getInt("connection.fetch.size")
        connectionHost = propertiesConfiguration!!.getString("connection.host")
        connectionPassword = propertiesConfiguration!!.getString("connection.password")
        connectionPort = propertiesConfiguration!!.getInt("connection.port")
        connectionService = propertiesConfiguration!!.getString("connection.service")
        connectionUser = propertiesConfiguration!!.getString("connection.user")
        fileBulkDelimiter = propertiesConfiguration!!.getString("file.bulk.delimiter")
        fileBulkLength = propertiesConfiguration!!.getInt("file.bulk.length")
        fileBulkHeader = propertiesConfiguration!!.getString("file.bulk.header")
        fileBulkName = propertiesConfiguration!!.getString("file.bulk.name")
        fileBulkSize = propertiesConfiguration!!.getInt("file.bulk.size")
        fileConfigurationName = propertiesConfiguration!!.getString("file.configuration.name")
        fileConfigurationNameC = propertiesConfiguration!!.getString("file.configuration.name.c")
        fileConfigurationNameErlang = propertiesConfiguration!!.getString("file.configuration.name.erlang")
        fileConfigurationNamePython = propertiesConfiguration!!.getString("file.configuration.name.python")
        fileResultDelimiter = propertiesConfiguration!!.getString("file.result.delimiter")
        fileResultHeader = propertiesConfiguration!!.getString("file.result.header").replace(";", fileResultDelimiter)
        fileResultName = propertiesConfiguration!!.getString("file.result.name")
        sqlCreate = propertiesConfiguration!!.getString("sql.create")
        sqlDrop = propertiesConfiguration!!.getString("sql.drop")
        sqlInsert = propertiesConfiguration!!.getString("sql.insert")
        sqlSelect = propertiesConfiguration!!.getString("sql.select")
        benchmarkLanguage = "Java " + System.getProperty("java.version")
    }

    private fun updatePropertiesFromOs() {
        val environmentVariables = System.getenv()
        var isChanged = false
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_BATCH_SIZE")) {
            benchmarkBatchSize = environmentVariables["ORA_BENCH_BENCHMARK_BATCH_SIZE"]!!.toInt()
            propertiesConfiguration!!.setProperty("benchmark.batch.size", benchmarkBatchSize)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_COMMENT")) {
            benchmarkComment = environmentVariables["ORA_BENCH_BENCHMARK_COMMENT"]
            if ("\"" == benchmarkComment!!.substring(0, 1)) {
                benchmarkComment = benchmarkComment!!.substring(1)
            }
            if ("\"" == benchmarkComment!!.substring(benchmarkComment!!.length - 1)) {
                benchmarkComment = benchmarkComment!!.substring(0, benchmarkComment!!.length - 1)
            }
            propertiesConfiguration!!.setProperty("benchmark.comment", benchmarkComment)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_CORE_MULTIPLIER")) {
            benchmarkCoreMultiplier = environmentVariables["ORA_BENCH_BENCHMARK_CORE_MULTIPLIER"]!!.toInt()
            propertiesConfiguration!!.setProperty("benchmark.core.multiplier", benchmarkCoreMultiplier)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DATABASE")) {
            benchmarkDatabase = environmentVariables["ORA_BENCH_BENCHMARK_DATABASE"]
            propertiesConfiguration!!.setProperty("benchmark.database", benchmarkDatabase)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_DRIVER")) {
            benchmarkDriver = environmentVariables["ORA_BENCH_BENCHMARK_DRIVER"]
            propertiesConfiguration!!.setProperty("benchmark.driver", benchmarkDriver)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_BENCHMARK_TRANSACTION_SIZE")) {
            benchmarkTransactionSize = environmentVariables["ORA_BENCH_BENCHMARK_TRANSACTION_SIZE"]!!.toInt()
            propertiesConfiguration!!.setProperty("benchmark.transaction.size", benchmarkTransactionSize)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_HOST")) {
            connectionHost = environmentVariables["ORA_BENCH_CONNECTION_HOST"]
            propertiesConfiguration!!.setProperty("connection.host", connectionHost)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_PORT")) {
            connectionPort = environmentVariables["ORA_BENCH_CONNECTION_PORT"]!!.toInt()
            propertiesConfiguration!!.setProperty("connection.port", connectionPort)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_CONNECTION_SERVICE")) {
            connectionService = environmentVariables["ORA_BENCH_CONNECTION_SERVICE"]
            propertiesConfiguration!!.setProperty("connection.service", connectionService)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_FILE_CONFIGURATION_NAME")) {
            fileConfigurationName = environmentVariables["ORA_BENCH_FILE_CONFIGURATION_NAME"]
            propertiesConfiguration!!.setProperty("file.configuration.name", fileConfigurationName)
            isChanged = true
        }
        if (environmentVariables.containsKey("ORA_BENCH_FILE_RESULT_NAME")) {
            fileResultName = environmentVariables["ORA_BENCH_FILE_RESULT_NAME"]
            propertiesConfiguration!!.setProperty("file.result.name", fileResultName)
            isChanged = true
        }
        if (isChanged) {
            try {
                fileBasedConfigurationBuilder.save()
                propertiesConfiguration = fileBasedConfigurationBuilder.configuration
            } catch (e: ConfigurationException) {
                e.printStackTrace()
            }
        }
    }

    private fun validateProperties() {
        var isChanged = false
        if (benchmarkBatchSize < 0) {
            log.error("Attention: The value of the configuration parameter 'benchmark.batch.size' [" + benchmarkBatchSize
                    + "] must not be less than 0, the specified value is replaced by 0.")
            benchmarkBatchSize = 0
            propertiesConfiguration!!.setProperty("benchmark.batch.size", benchmarkBatchSize)
            isChanged = true
        }
        if (benchmarkCoreMultiplier < 0) {
            log.error("Attention: The value of the core multiplier parameter 'benchmark.core.multiplier' [" + benchmarkCoreMultiplier
                    + "] must not be less than 0, the specified value is replaced by 0.")
            benchmarkCoreMultiplier = 0
            propertiesConfiguration!!.setProperty("benchmark.core.multiplier", benchmarkCoreMultiplier)
            isChanged = true
        }
        if (benchmarkHostName == "n/a") {
            try {
                benchmarkHostName = InetAddress.getLocalHost().hostName
            } catch (e: UnknownHostException) {
                e.printStackTrace()
            }
            propertiesConfiguration!!.setProperty("benchmark.host.name", benchmarkHostName)
            isChanged = true
        }
        if (benchmarkNumberCores == "n/a") {
            benchmarkNumberCores = Runtime.getRuntime().availableProcessors().toString()
            propertiesConfiguration!!.setProperty("benchmark.number.cores", benchmarkNumberCores)
            benchmarkNumberPartitions = if (benchmarkCoreMultiplier == 0) benchmarkNumberCores.toInt() else benchmarkNumberCores.toInt() * benchmarkCoreMultiplier
            propertiesConfiguration!!.setProperty("benchmark.number.partitions", benchmarkNumberPartitions)
            isChanged = true
        }
        if (benchmarkOs == "n/a") {
            benchmarkOs = System.getProperty("os.arch") + " / " + System.getProperty("os.name") + " / " + System.getProperty("os.version")
            propertiesConfiguration!!.setProperty("benchmark.os", benchmarkOs)
            isChanged = true
        }
        if (benchmarkRelease == "n/a") {
            benchmarkRelease = System.getProperty("benchmark.release")
            propertiesConfiguration!!.setProperty("benchmark.release", benchmarkRelease)
            isChanged = true
        }
        if (benchmarkTransactionSize < benchmarkBatchSize) {
            log.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + benchmarkTransactionSize
                    + "] must not be less than value of the configuration parameter 'benchmark.batch.size' [" + benchmarkBatchSize
                    + "], the specified value of the configuration parameter 'benchmark.transaction.size' is replaced by " + benchmarkBatchSize + "")
            benchmarkTransactionSize = benchmarkBatchSize
            propertiesConfiguration!!.setProperty("benchmark.batch.size", benchmarkTransactionSize)
            isChanged = true
        }
        if (benchmarkTransactionSize < 0) {
            log.error("Attention: The value of the configuration parameter 'benchmark.transaction.size' [" + benchmarkTransactionSize
                    + "] must not be less than 0, the specified value is replaced by 0.")
            benchmarkTransactionSize = 0
            propertiesConfiguration!!.setProperty("benchmark.batch.size", benchmarkTransactionSize)
            isChanged = true
        }
        if (benchmarkTrials < 1) {
            log.error("Attention: The value of the configuration parameter 'benchmark.trials' [" + benchmarkTrials
                    + "] must not be less than 1, the specified value is replaced by 1.")
            benchmarkTrials = 1
            propertiesConfiguration!!.setProperty("benchmark.trials", benchmarkTrials)
            isChanged = true
        }
        if (benchmarkUserName == "n/a") {
            benchmarkUserName = System.getProperty("user.name")
            propertiesConfiguration!!.setProperty("benchmark.user.name", benchmarkUserName)
            isChanged = true
        }
        if (benchmarkId == "n/a") {
            benchmarkId = DigestUtils.md5Hex(LocalDateTime.now().format(formatter) + benchmarkHostName + benchmarkOs + benchmarkUserName)
            propertiesConfiguration!!.setProperty("benchmark.id", benchmarkId)
            isChanged = true
        }
        if (connectionFetchSize < 0) {
            log.error("Attention: The value of the configuration parameter 'connection.fetch.size' [" + connectionFetchSize
                    + "] must not be less than 0, the specified value is replaced by 0.")
            connectionFetchSize = 0
            propertiesConfiguration!!.setProperty("connection.fetch.size", connectionFetchSize)
            isChanged = true
        }
        if (fileBulkLength < 80) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + fileBulkLength
                    + "] must not be less than 80, the specified value is replaced by 80.")
            fileBulkLength = 80
            propertiesConfiguration!!.setProperty("file.bulk.length", fileBulkLength)
            isChanged = true
        } else if (fileBulkLength > 4000) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.length' [" + fileBulkLength
                    + "] must not be greater than 4000, the specified value is replaced by 4000.")
            fileBulkLength = 80
            propertiesConfiguration!!.setProperty("file.bulk.length", fileBulkLength)
            isChanged = true
        }
        if (fileBulkSize < 1) {
            log.error("Attention: The value of the configuration parameter 'file.bulk.size' [" + fileBulkSize
                    + "] must not be less than 1, the specified value is replaced by 1.")
            fileBulkSize = 1
            propertiesConfiguration!!.setProperty("file.bulk.size", fileBulkSize)
            isChanged = true
        }
        if (sqlCreate == "n/a") {
            val sqlCreateDefault = ("BEGIN EXECUTE IMMEDIATE 'CREATE TABLE ora_bench_table (key VARCHAR2(32) PRIMARY KEY, data VARCHAR2(4000), "
                    + "no_partitions NUMBER DEFAULT C...C, partition_key NUMBER(5)) PARTITION BY RANGE (partition_key) (PARTITION p00000 VALUES LESS THAN (1)P...P)'; "
                    + "EXECUTE IMMEDIATE 'CREATE TRIGGER ora_bench_table_before_insert BEFORE INSERT ON ora_bench_table FOR EACH ROW "
                    + "BEGIN :new.partition_key := MOD (ASCII (SUBSTR (:new.key, 1, 1)) * 256 + ASCII (SUBSTR (:new.key, 2, 1)), :new.no_partitions); "
                    + "END ora_bench_table_before_insert;'; END;")
            sqlCreate = sqlCreateDefault.replace("C...C", benchmarkNumberPartitions.toString()).replace("P...P", partitionString)
            propertiesConfiguration!!.setProperty("sql.create", sqlCreate)
            isChanged = true
        }
        if (isChanged) {
            try {
                fileBasedConfigurationBuilder.save()
                propertiesConfiguration = fileBasedConfigurationBuilder.configuration
            } catch (e: ConfigurationException) {
                e.printStackTrace()
            }
        }
    }

    /**
     * Constructs a Config object.
     */
    init {
        val configFile = File(System.getenv("ORA_BENCH_FILE_CONFIGURATION_NAME"))
        fileBasedConfigurationBuilder.configure(Parameters().properties().setFile(configFile))
        try {
            propertiesConfiguration = fileBasedConfigurationBuilder.configuration
            updatePropertiesFromOs()
            keysSorted = getKeysSorted()
        } catch (e: ConfigurationException) {
            e.printStackTrace()
        }
        storeConfiguration()
        validateProperties()
    }
}
