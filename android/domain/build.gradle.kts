// Backend row models and repository interfaces. Features depend on these,
// never on the Supabase implementations.
plugins {
    id("kameti.jvm.library")
}

dependencies {
    api(project(":core"))
}
