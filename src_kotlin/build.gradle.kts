plugins {
    id("org.jetbrains.dokka") version "1.4.32"
    kotlin("jvm") version "1.5.20"
    application
}

group = "ch.konnexions"

application {
    mainClass.set("OraBenchKt")
}

repositories {
    mavenCentral()
}

dependencies {
    dokkaHtmlPlugin("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.32")
    implementation("com.oracle.database.jdbc:ojdbc11:21.1.0.0")
    implementation("org.apache.commons:commons-csv:1.8")
    implementation("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.32")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.5.20")
    implementation("org.apache.logging.log4j:log4j-api:2.14.1")
    implementation("org.apache.logging.log4j:log4j-core:2.14.1")
    implementation("org.apache.logging.log4j:log4j-slf4j-impl:2.14.1")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.5.20"))
}

val jar by tasks.getting(Jar::class) {
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
    isZip64 = true

    manifest {
        attributes["Main-Class"] = "main.kotlin.ch.konnexions.OraBenchKt"
        attributes["Multi-Release"] = "true"
    }

    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.DSA")
        exclude("META-INF/*.RSA")
        exclude("META-INF/*.SF")
    }
}
