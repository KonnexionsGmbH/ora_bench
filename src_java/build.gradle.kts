import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar

application {
    mainClassName = "ch.konnexions.orabench.OraBench"
}

dependencies {
    implementation(group = "com.google.guava", name = "guava", version = "29.0-jre")
    implementation(group = "com.googlecode.json-simple", name = "json-simple", version = "1.1.1")
    implementation(group = "commons-beanutils", name = "commons-beanutils", version = "1.9.4")
    implementation(group = "commons-codec", name = "commons-codec", version = "1.15")
    implementation(group = "commons-logging", name = "commons-logging", version = "1.2")
    implementation(group = "org.apache.commons", name = "commons-configuration2", version = "2.7")
    implementation(group = "org.apache.commons", name = "commons-csv", version = "1.8")
    implementation(group = "org.apache.commons", name = "commons-lang3", version = "3.11")
    implementation(group = "org.apache.commons", name = "commons-text", version = "1.9")
    implementation(group = "org.slf4j", name = "slf4j-log4j12", version = "1.7.30")
    testImplementation(group = "org.junit.jupiter", name = "junit-jupiter-api", version = "5.6.2")
    testRuntimeOnly(group = "org.junit.jupiter", name = "junit-jupiter-engine", version = "5.6.2")
}

java {
    sourceCompatibility = JavaVersion.VERSION_14
    targetCompatibility = JavaVersion.VERSION_14
}

plugins {
    application
    java
    id("com.github.johnrengelman.shadow") version "6.0.0"
}

repositories {
    jcenter()
}

tasks.compileJava {
    options.compilerArgs = listOf("-Xlint:deprecation", "-Xlint:unchecked")
}

tasks.withType<Jar>() {
    configurations["compileClasspath"].forEach { file: File ->
        from(zipTree(file.absoluteFile))
    }
}

tasks.withType<ShadowJar>() {
    manifest {
        attributes["Main-Class"] = "ch.konnexions.orabench.OraBench"
    }
}

tasks.named<Test>("test") {
    useJUnitPlatform()
}
