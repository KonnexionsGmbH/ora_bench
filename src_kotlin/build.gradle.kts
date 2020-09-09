plugins {
    application
    id("org.jetbrains.dokka") version "1.4.0"
    id("org.jetbrains.kotlin.jvm") version "1.4.0"
}

repositories {
    jcenter()
}

dependencies {
    dokkaHtmlPlugin("org.jetbrains.dokka:kotlin-as-java-plugin:1.4.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("org.slf4j:slf4j-log4j12:1.7.30")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom"))
}

application {
    mainClassName = "ch.konnexions.orabench.OraBenchKt"
}

val jar by tasks.getting(Jar::class) {
    manifest {
        attributes["Main-Class"] = "ch.konnexions.orabench.OraBenchKt"
    }
    
    from(configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) }) {
        exclude("META-INF/*.RSA", "META-INF/*.SF", "META-INF/*.DSA")
    }
}
