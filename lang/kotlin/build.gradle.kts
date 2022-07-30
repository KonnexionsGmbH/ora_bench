plugins {
    id("org.jetbrains.dokka") version "1.7.10"
    kotlin("jvm") version "1.7.10"
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
    dokkaHtmlPlugin("org.jetbrains.dokka:kotlin-as-java-plugin:1.7.10")
    implementation("com.oracle.database.jdbc:ojdbc11:21.6.0.0.1")
    implementation("org.apache.commons:commons-csv:1.9.0")
    implementation("org.apache.commons:commons-math3:3.6.1")
    implementation("org.jetbrains.dokka:kotlin-as-java-plugin:1.7.10")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.7.10")
    implementation("org.apache.logging.log4j:log4j-api:2.18.0")
    implementation("org.apache.logging.log4j:log4j-core:2.18.0")
    implementation("org.apache.logging.log4j:log4j-slf4j-impl:2.18.0")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.7.10"))
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
