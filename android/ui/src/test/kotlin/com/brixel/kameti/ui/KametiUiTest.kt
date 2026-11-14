package com.brixel.kameti.ui

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.core.SignInProblem
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest

class KametiUiTest {
    @Test
    fun amountGroupsInLakhAndCrore() {
        assertEquals("2,50,000", KAmount.grouped("250000"))
        assertEquals("1,000", KAmount.grouped("1000"))
        assertEquals("1,23,45,678", KAmount.grouped("12345678"))
        assertEquals("", KAmount.grouped(""))
        assertEquals("", KAmount.grouped("abc"))
    }

    @Test
    fun typedAmountKeepsOnlyDigits() {
        assertEquals("250000", KAmount.digits("2,50,000"))
        assertEquals("5", KAmount.digits("005"))
        assertEquals("", KAmount.digits("0"))
        assertEquals("1234567890", KAmount.digits("12345678901234"))
    }

    @Test
    fun potPercent() {
        assertEquals(47, KPot.percent(Money(2_350_000), Money(5_000_000)))
        assertEquals(102, KPot.percent(Money(5_100_000), Money(5_000_000)))
        assertEquals(0, KPot.percent(Money(100), Money.ZERO))
    }

    @Test
    fun barSegmentsAddUpAndClamp() {
        assertEquals(KPotSegments(500, 200, 300), KPot.segments(Money(2_500_000), Money(1_000_000), Money(5_000_000)))
        val over = KPot.segments(Money(6_000_000), Money.ZERO, Money(5_000_000))
        assertEquals(1000, over.collected)
        assertEquals(0, over.rest)
    }

    @Test
    fun balanceMeaning() {
        assertEquals(KBalanceState.Owes(Money(450_000)), KBalanceState.of(Money(450_000)))
        assertEquals(KBalanceState.Settled, KBalanceState.of(Money.ZERO))
        assertEquals(KBalanceState.Credit(Money(125_000)), KBalanceState.of(Money(-125_000)))
    }

    @Test
    fun initials() {
        assertEquals("AR", initialsOf("Ali Raza"))
        assertEquals("H", initialsOf("Hassan"))
        assertEquals("MK", initialsOf("  muhammad  hassan  khan "))
        assertEquals("", initialsOf(""))
    }

    @Test
    fun tokensAreComplete() {
        assertEquals(8, KLightColors.avatars.size)
        assertEquals(8, KDarkColors.avatars.size)
        assertEquals(20f, KSpace.gutter.value)
        assertEquals(44f, KSize.minTouch.value)
    }

    @Test
    fun offlineGetsConnectionAdviceOthersTheirMessage() {
        assertEquals(R.string.ui_check_your_connection_and_try_again, Failure.Network.helpMessageRes)
        val owner = Failure.Server("not_kameti_owner")
        assertEquals(owner.messageRes, owner.helpMessageRes)
        assertEquals(R.string.ui_only_the_person_running_this_kameti_can_do, owner.messageRes)
    }

    @Test
    fun everyFailureHasAMessageAndUnknownCodesFallBack() {
        val fallback = R.string.ui_something_went_wrong_please_try_again
        assertEquals(fallback, Failure.Server("some_new_code").messageRes)
        assertEquals(fallback, Failure.Unknown("x").messageRes)
        assertNotEquals(fallback, Failure.Server("kameti_not_ready").messageRes)
        assertEquals(Failure.Server("invite_not_found").messageRes, Failure.Server("invalid_invite").messageRes)
        assertEquals(SignInProblem.entries.size, SignInProblem.entries.map { Failure.SignIn(it).messageRes }.toSet().size)
    }

    @Test
    fun appearanceChoice() {
        assertEquals(KAppearance.System, KAppearance.of(null))
        assertEquals(KAppearance.Dark, KAppearance.of("dark"))
        assertTrue(KAppearance.System.isDark(systemIsDark = true))
        assertFalse(KAppearance.Light.isDark(systemIsDark = true))
    }
}

/** Live changes fold into one reload, and say which kametis moved. */
@OptIn(ExperimentalCoroutinesApi::class)
class LiveUpdatesTest {
    @Test
    fun aBurstBecomesOneReload() = runTest {
        val live = KLiveUpdates(backgroundScope)
        live.record("a")
        live.record("b")
        assertEquals(0, live.revision)
        advanceTimeBy(600)
        assertEquals(1, live.revision)
        assertTrue(live.affects("a") && live.affects("b"))
        assertFalse(live.affects("c"))
    }

    @Test
    fun anUnknownKametiRefreshesEverything() = runTest {
        val live = KLiveUpdates(backgroundScope)
        live.record("a")
        live.record(null)
        advanceTimeBy(600)
        assertTrue(live.affects("anything"))
    }

    @Test
    fun comingBackRefreshesAtOnce() = runTest {
        val live = KLiveUpdates(backgroundScope)
        live.refreshAll()
        assertEquals(1, live.revision)
        assertTrue(live.affects("x"))
    }
}
