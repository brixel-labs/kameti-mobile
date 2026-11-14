package com.brixel.kameti.navigation

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DeepLinkTest {
    @Test
    fun inviteLinkBecomesAJoinRoute() {
        assertEquals(Route.Join("abc123"), DeepLink.route("https://kameti.fhbtechservices.com/join/abc123"))
    }

    @Test
    fun theFirstLinksSentOnTheCompanySiteStillWork() {
        assertEquals(Route.Join("abc123"), DeepLink.route("https://www.fhbtechservices.com/kameti/join/abc123"))
    }

    @Test
    fun bareDomainAndMixedCaseHostWork() {
        assertEquals(Route.Join("x"), DeepLink.route("https://fhbtechservices.com/kameti/join/x"))
        assertEquals(Route.Join("x"), DeepLink.route("https://WWW.FhbTechServices.com/kameti/join/x"))
    }

    @Test
    fun ignoresOtherLinks() {
        val others = listOf(
            "http://www.fhbtechservices.com/kameti/join/abc", // not https
            "https://example.com/kameti/join/abc", // another site
            "https://www.fhbtechservices.com/kameti/join", // no token
            "https://www.fhbtechservices.com/kameti/join/", // empty token
            "https://www.fhbtechservices.com/kameti/other/abc", // another path
            "https://www.fhbtechservices.com/kameti/join/a/b", // extra segment
            "https://kameti.fhbtechservices.com/join", // no token
            "https://kameti.fhbtechservices.com/privacy", // another page
            "https://kameti.fhbtechservices.com/kameti/join/x", // old path on the new site
            "https://other.fhbtechservices.com/join/x", // another subdomain
            "not a link at all",
        )
        for (text in others) assertNull(DeepLink.route(text), text)
    }
}

class AppRouterTest {
    @Test
    fun pushesOntoTheSelectedTabsStackOnly() {
        val router = AppRouter()
        router.push(Route.KametiDetail("k1"))
        router.tab = AppTab.Inbox
        router.push(Route.Activity("k1"))
        assertEquals(listOf<Route>(Route.KametiDetail("k1")), router.homePath)
        assertEquals(listOf<Route>(Route.Activity("k1")), router.inboxPath)
        assertTrue(router.profilePath.isEmpty())
    }

    @Test
    fun popToRootClearsOnlyTheCurrentTab() {
        val router = AppRouter()
        router.push(Route.KametiDetail("k1"))
        router.tab = AppTab.Profile
        router.push(Route.Activity("k1"))
        router.popToRoot()
        assertTrue(router.profilePath.isEmpty())
        assertEquals(listOf<Route>(Route.KametiDetail("k1")), router.homePath)
    }

    /** Android only: the system Back button goes back one screen at a time. */
    @Test
    fun popGoesBackOneScreenAndSaysWhenThereIsNothingLeft() {
        val router = AppRouter()
        router.push(Route.KametiDetail("k1"))
        router.push(Route.Activity("k1"))
        assertTrue(router.pop())
        assertEquals(listOf<Route>(Route.KametiDetail("k1")), router.homePath)
        assertTrue(router.pop())
        assertFalse(router.pop())
        assertTrue(router.homePath.isEmpty())
    }

    @Test
    fun openingAnInviteLinkShowsItOnHome() {
        val router = AppRouter()
        router.tab = AppTab.Profile
        val handled = router.open("https://www.fhbtechservices.com/kameti/join/K7Q2MX")
        assertTrue(handled)
        assertEquals(AppTab.Home, router.tab)
        assertEquals(listOf<Route>(Route.Join("K7Q2MX")), router.homePath)
        assertEquals(router.state.value.homePath, router.homePath)
    }

    @Test
    fun otherLinksAreLeftAlone() {
        val router = AppRouter()
        assertFalse(router.open("https://example.com"))
        assertTrue(router.homePath.isEmpty())
    }
}
