plugins {
    application
//  id("org.jetbrains.dokka") version "0.11.0-dev-59"
    kotlin("jvm") version "1.4.30"
}

application {
    mainClass.set("ch.konnexions.OraBenchKt")
}

repositories {
    jcenter()
}

dependencies {
//  dokkaHtmlPlugin("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.10.2")
    implementation("com.oracle.database.jdbc:ojdbc11:21.1.0.0")
    implementation("commons-logging:commons-logging:1.2")
    implementation("org.apache.commons:commons-csv:1.8")
    implementation("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.10.2")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.4.30")
    implementation("org.slf4j:slf4j-log4j12:1.7.30")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:1.4.30"))
}

val jar by tasks.getting(Jar::class) {
    duplicatesStrategy = DuplicatesStrategy.INCLUDE
    zip64 = true

    manifest {
        attributes["Main-Class"] = "ch.konnexions.OraBenchKt"
    }

    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.DSA")
        exclude("META-INF/*.RSA")
        exclude("META-INF/*.SF")
    }
}
