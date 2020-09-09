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

