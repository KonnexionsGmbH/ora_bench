/*
 * 
 */
package ch.konnexions.orabench

import org.apache.log4j.Logger

class OraBench {
    val logger: Logger = Logger.getLogger(OraBench::class.java)
    val isDebug: Boolean = logger.isDebugEnabled()

    fun runBenchmark() {
        if (isDebug) {
            logger.debug("Start")
        }

        if (isDebug) {
            logger.debug("End")
        }
    }

    companion object {
        @JvmStatic
        fun main(args: Array<String>) {
            val oraBench = OraBench()

            if (oraBench.isDebug) {
                oraBench.logger.debug("Start")
            }

            oraBench.runBenchmark()

            if (oraBench.isDebug) {
                oraBench.logger.debug("End")
            }
        }
    }
}

fun main(args: Array<String>) {
    val obj = OraBench()
    
    obj.runBenchmark()
}

