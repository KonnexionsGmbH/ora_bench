/*
 * 
 */
package ch.konnexions.orabench

import java.io.FileReader
import java.util.Properties
import org.apache.log4j.Logger

class OraBench {
    // wwe val benchmarkDriver: String = "Exposed (Version v" + cx_Oracle.version + ")"
    // wwe val benchmarkLanguage: String = "Kotlin " + sys.version

    val config = Properties()

    val fileConfigurationName: String = "priv/properties/ora_bench.properties"

    val ixDurationInsertSum: Int = 3
    val ixDurationSelectSum: Int = 4
    val ixLastBenchmark: Int = 0
    val ixLastQuery: Int = 2
    val ixLastTrial: Int = 1

    val logger: Logger = Logger.getLogger(OraBench::class.java)
    val isDebug: Boolean = logger.isDebugEnabled()

    /**
     * Run a benchmark.
     */
    fun runBenchmark() {
        if (isDebug) {
            logger.debug("Start")
        }

        val reader = FileReader(fileConfigurationName)
        config.load(reader)

        config.forEach { (k, v) -> logger.info("key = $k, value = $v") }

        if (isDebug) {
            logger.debug("End")
        }
    }
}

/**
 * This is the main function for the Oracle benchmark run.
 *
 * @param args n/a
 */
fun main(args: Array<String>) {
    val oraBench = OraBench()

    if (oraBench.isDebug) {
        oraBench.logger.debug("Start")
    }

    oraBench.logger.info("Start OraBench.kt");

    if (args.size != 0) {
        oraBench.logger.error("Unknown command line argument(s): " + args.joinToString(" "));
    }

    oraBench.runBenchmark()

    oraBench.logger.info("End   OraBench.kt");

    if (oraBench.isDebug) {
        oraBench.logger.debug("End")
    }
}

