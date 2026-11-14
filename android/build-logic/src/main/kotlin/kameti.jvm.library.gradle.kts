// A pure Kotlin module (no Android): :core, :domain, :navigation, :testsupport.
// Its tests run on the JVM in seconds.
plugins {
    id("org.jetbrains.kotlin.jvm")
    id("org.jetbrains.kotlin.plugin.serialization")
}

java {
    sourceCompatibility = KametiBuild.JAVA
    targetCompatibility = KametiBuild.JAVA
}

configureKotlinJvmTarget()
addUnitTestDependencies()
