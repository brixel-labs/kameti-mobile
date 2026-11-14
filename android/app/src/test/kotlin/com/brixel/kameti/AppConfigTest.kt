package com.brixel.kameti

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class AppConfigTest {
    private val prod = """{"FLAVOR":"prod","SUPABASE_URL":"https://x.supabase.co","SUPABASE_PUBLISHABLE_KEY":"k","GOOGLE_WEB_CLIENT_ID":"w","GOOGLE_IOS_CLIENT_ID":"i"}"""
    private val demo = """{"FLAVOR":"demo","SUPABASE_URL":"http://localhost","SUPABASE_PUBLISHABLE_KEY":"demo"}"""
    private val local = """{"FLAVOR":"dev","SUPABASE_URL":"http://127.0.0.1:55421","SUPABASE_PUBLISHABLE_KEY":"k"}"""

    @Test
    fun readsTheSharedEnvFile() {
        val config = assertNotNull(AppConfig.parse(prod, debugBuild = false))
        assertEquals("https://x.supabase.co", config.supabaseUrl)
        assertEquals("w", config.googleWebClientId)
        assertFalse(config.isDemo(debugBuild = true))
    }

    @Test
    fun demoAndDevOnlyInDebugBuilds() {
        assertTrue(assertNotNull(AppConfig.parse(demo, debugBuild = true)).isDemo(debugBuild = true))
        assertTrue(assertNotNull(AppConfig.parse(local, debugBuild = true)).isDev(debugBuild = true))
    }

    @Test
    fun releaseBuildRefusesDemoAndLocalBackends() {
        assertNull(AppConfig.parse(demo, debugBuild = false))
        assertNull(AppConfig.parse(local, debugBuild = false))
    }

    @Test
    fun unreadableTextIsMissingConfig() {
        assertNull(AppConfig.parse("not json", debugBuild = true))
        assertNull(AppConfig.parse("""{"FLAVOR":"prod"}""", debugBuild = true))
    }

    @Test
    fun aDevBuildReachesTheMacFromTheEmulator() {
        val dev = assertNotNull(AppConfig.parse(local, debugBuild = true))
        assertEquals("http://10.0.2.2:55421", dev.backendUrl(debugBuild = true))
        // Any other backend is used as written.
        val real = assertNotNull(AppConfig.parse(prod, debugBuild = true))
        assertEquals("https://x.supabase.co", real.backendUrl(debugBuild = true))
    }
}
