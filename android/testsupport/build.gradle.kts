// Sample data and stub repositories, for unit tests and the demo flavor.
plugins {
    id("kameti.jvm.library")
}

dependencies {
    api(project(":core"))
    api(project(":domain"))
}
