package ch.konnexions.orabench

private val logger = KotlinLogging.logger {}

class OraBench {
    companion object {
        @JvmStatic
        fun main(args: Array<String>) {
            logger.debug("Start")
            println("Hello, World!")
            logger.debug("End")
        }
    }
}
