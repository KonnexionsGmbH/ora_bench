plugins {
    application
    id("org.jetbrains.dokka") version "1.4.32"
    kotlin("jvm") version "1.5.0"
}

application {
    mainClass.set("ch.konnexions.OraBenchKt")
}

repositories {
    mavenCentral()
}

dependencies {
    dokkaHtmlPlugin("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.32")
    implementation("com.oracle.database.jdbc:ojdbc11:21.1.0.0")
    implementation("commons-logging:commons-logging:1.2")
    implementation("org.apache.commons:commons-csv:1.8")
    implementation("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.32")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.5.10")
    implementation("org.slf4j:slf4j-log4j12:1.7.30")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.5.10"))
}

val jar by tasks.getting(Jar::class) {
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
    isZip64 = true

    manifest {
        attributes["Main-Class"] = "ch.konnexions.OraBenchKt"
    }

    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.DSA")
        exclude("META-INF/*.RSA")
        exclude("META-INF/*.SF")
    }
}
