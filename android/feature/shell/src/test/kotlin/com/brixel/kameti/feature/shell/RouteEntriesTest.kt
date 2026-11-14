package com.brixel.kameti.feature.shell

import com.brixel.kameti.navigation.AppRouter
import com.brixel.kameti.navigation.AppTab
import com.brixel.kameti.navigation.Route
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RouteEntriesTest {
    @Test
    fun theScreenShownIsTheTopOfTheSelectedTabsStack() {
        val router = AppRouter()
        assertNull(router.state.value.currentEntry().route)
        assertEquals(AppTab.Home, router.state.value.currentEntry().tab)

        router.push(Route.KametiDetail("k1"))
        router.push(Route.Activity("k1"))
        assertEquals(Route.Activity("k1"), router.state.value.currentEntry().route)

        router.tab = AppTab.Profile
        assertNull(router.state.value.currentEntry().route)
    }

    @Test
    fun everyScreenOnAStackHasItsOwnKey() {
        val router = AppRouter()
        router.push(Route.KametiDetail("k1"))
        router.push(Route.Activity("k1"))
        router.push(Route.KametiDetail("k1")) // the same kameti again, further up
        val keys = router.state.value.entries().map { it.key }
        assertEquals(keys.size, keys.toSet().size)
        // Three first screens plus the three pushed ones.
        assertEquals(6, keys.size)
    }

    @Test
    fun aPoppedScreensKeyIsGoneAndTheOthersStay() {
        val router = AppRouter()
        router.push(Route.KametiDetail("k1"))
        val before = router.state.value.entries().map { it.key }.toSet()
        val detail = router.state.value.currentEntry().key
        router.tab = AppTab.Inbox
        // Another tab: nothing was popped, so every screen keeps its state.
        assertEquals(before, router.state.value.entries().map { it.key }.toSet())
        router.tab = AppTab.Home
        router.pop()
        val after = router.state.value.entries().map { it.key }.toSet()
        assertTrue(detail !in after)
        assertNotEquals(before, after)
    }
}
