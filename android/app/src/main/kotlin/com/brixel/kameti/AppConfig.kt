package com.brixel.kameti

import android.content.Context
import java.net.URI
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/**
 * Backend settings from `assets/KametiConfig.json`, a copy of
 * `env/<flavor>.json` (`android/scripts/use-env.sh dev|prod|demo`). The file
 * is gitignored; only public values live in it (the Supabase publishable key
 * is public by design).
 */
@Serializable
data class AppConfig(
    @SerialName("FLAVOR") val flavor: String? = null,
    @SerialName("SUPABASE_URL") val supabaseUrl: String,
    @SerialName("SUPABASE_PUBLISHABLE_KEY") val supabasePublishableKey: String,
    @SerialName("GOOGLE_WEB_CLIENT_ID") val googleWebClientId: String? = null,
) {
    /**
     * The demo build runs on sample data and is always signed in. Debug builds
     * only: a release build never runs on sample data.
     */
    fun isDemo(debugBuild: Boolean = BuildConfig.DEBUG): Boolean = debugBuild && flavor == "demo"

    /**
     * The dev build shows the seeded test-account buttons (local Supabase only).
     * Debug builds only, and only when the config says so explicitly.
     */
    fun isDev(debugBuild: Boolean = BuildConfig.DEBUG): Boolean = debugBuild && flavor == "dev"

    /**
     * The backend address as this device reaches it. A dev build points at
     * the Supabase running on the Mac; from the Android emulator the Mac is
     * `10.0.2.2`, not `127.0.0.1`.
     */
    fun backendUrl(debugBuild: Boolean = BuildConfig.DEBUG): String {
        if (!isDev(debugBuild)) return supabaseUrl
        return supabaseUrl.replace("://127.0.0.1", "://$EMULATOR_HOST").replace("://localhost", "://$EMULATOR_HOST")
    }

    companion object {
        private const val EMULATOR_HOST = "10.0.2.2"
        private const val FILE = "KametiConfig.json"
        private val LOCAL_HOSTS = setOf("localhost", "127.0.0.1", "10.0.2.2")
        private val json = Json { ignoreUnknownKeys = true }

        /** `null` when the file is missing or unreadable. */
        fun load(context: Context): AppConfig? {
            val text = try {
                context.assets.open(FILE).bufferedReader().use { it.readText() }
            } catch (_: java.io.IOException) {
                return null
            }
            return parse(text, BuildConfig.DEBUG)
        }

        /**
         * A release build must point at a real backend: a demo or local config
         * (left over from development) shows the "configuration missing"
         * screen instead of a broken app.
         */
        fun parse(text: String, debugBuild: Boolean): AppConfig? {
            val config = try {
                json.decodeFromString<AppConfig>(text)
            } catch (_: Exception) {
                return null
            }
            val host = try {
                URI(config.supabaseUrl).host
            } catch (_: Exception) {
                null
            } ?: return null
            if (!debugBuild && (config.flavor == "demo" || host in LOCAL_HOSTS)) return null
            return config
        }
    }
}
