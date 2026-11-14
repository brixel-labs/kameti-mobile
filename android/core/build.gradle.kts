// Money, Failure, KametiClock (Asia/Karachi), date and JSON rules. Depends on nothing.
plugins {
    id("kameti.jvm.library")
}

dependencies {
    api(libs.kotlinx.serialization.json)
    api(libs.kotlinx.coroutines.core)
}
