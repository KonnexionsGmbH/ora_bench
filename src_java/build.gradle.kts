application {
    mainClassName = "ch.konnexions.orabench.OraBench"
}

dependencies {
    implementation(group = "commons-logging", name = "commons-logging", version = "1.2")
    implementation(group = "commons-beanutils", name = "commons-beanutils", version = "1.9.4")
    implementation(group = "commons-codec", name = "commons-codec", version = "1.14")
    implementation(group = "org.apache.commons", name = "commons-configuration2", version = "2.6")
    implementation(group = "org.apache.commons", name = "commons-csv", version = "1.7")
    implementation(group = "org.apache.commons", name = "commons-lang3", version = "3.9")
    implementation(group = "org.apache.commons", name = "commons-text", version = "1.8")
    implementation("com.google.guava:guava:28.1-jre")
}

java {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

plugins {
    application
    java
}

repositories {
    jcenter()
}

sourceSets {
    main {
        java {
            srcDirs("src_java/src/main/java")
        }
    }
}
