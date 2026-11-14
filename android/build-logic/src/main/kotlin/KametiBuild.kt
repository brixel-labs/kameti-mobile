import org.gradle.api.JavaVersion
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalog
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.getByType
import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

/** Values every module shares. */
object KametiBuild {
    const val COMPILE_SDK = 37
    const val TARGET_SDK = 37
    const val MIN_SDK = 26
    const val BASE_PACKAGE = "com.brixel.kameti"
    val JAVA = JavaVersion.VERSION_17
}

val Project.catalog: VersionCatalog
    get() = extensions.getByType<VersionCatalogsExtension>().named("libs")

/** `:feature:home` -> `com.brixel.kameti.feature.home`. */
val Project.kametiNamespace: String
    get() = KametiBuild.BASE_PACKAGE + path.replace(":", ".")

fun Project.configureKotlinJvmTarget() {
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
    }
}

/** Unit tests: kotlin.test on JUnit 4, plus coroutine test helpers. */
fun Project.addUnitTestDependencies() {
    dependencies {
        add("testImplementation", catalog.findLibrary("kotlin-test-junit").get())
        add("testImplementation", catalog.findLibrary("kotlinx-coroutines-test").get())
    }
}

fun Project.addComposeDependencies() {
    dependencies {
        val bom = platform(catalog.findLibrary("compose-bom").get())
        add("implementation", bom)
        add("implementation", catalog.findLibrary("compose-ui").get())
        add("implementation", catalog.findLibrary("compose-foundation").get())
        add("implementation", catalog.findLibrary("compose-material3").get())
        add("implementation", catalog.findLibrary("compose-ui-tooling-preview").get())
        add("debugImplementation", catalog.findLibrary("compose-ui-tooling").get())
    }
}
