/*
 * 
 */
package ch.konnexions.orabench

import org.apache.log4j.Logger

class OraBench {
    val logger: Logger = Logger.getLogger(OraBench::class.java)
    val isDebug: Boolean = logger.isDebugEnabled()

    /**
     * Run a benchmark.
     */
    fun runBenchmark() {
        if (isDebug) {
            logger.debug("Start")
        }

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
fun main(@Suppress("UNUSED_PARAMETER") args: Array<String>) {
    val oraBench = OraBench()

    if (oraBench.isDebug) {
        oraBench.logger.debug("Start")
    }

    obj.runBenchmark()

    if (oraBench.isDebug) {
        oraBench.logger.debug("End")
    }
}

