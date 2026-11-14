package com.brixel.kameti.feature.invites

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.AppNotification
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.InviteShare
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.feature.invites.InboxLogic.Ago
import com.brixel.kameti.feature.invites.JoinInviteViewModel.Phase
import com.brixel.kameti.testsupport.SampleData
import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

class InviteMathTest {
    @Test
    fun turnsAndMonthlyTotal() {
        val shares = listOf(InviteShare(4, Money(50_000)), InviteShare(2, Money(75_000)))
        assertEquals(Money(125_000), InviteLogic.monthlyTotal(shares))
        assertEquals(listOf(2, 4), InviteLogic.turnMonths(shares))
        assertEquals(listOf(4), InviteLogic.turnMonths(shares.take(1)))
        assertTrue(InviteLogic.turnMonths(emptyList()).isEmpty())
    }

    @Test
    fun payoutAndTheMonthsItRuns() {
        val start = DateOnly.make(2026, 11)
        val two = listOf(InviteShare(3, Money(200_000)), InviteShare(1, Money(50_000)))
        assertEquals(DateOnly.make(2027, 1), InviteLogic.monthStart(start, 3))
        assertEquals(Money(1_000_000), InviteLogic.payout(two, monthsN = 4))
        assertEquals("Nov 2026 → Feb 2027", InviteLogic.runsText(start, monthsN = 4))
    }

    @Test
    fun masking() {
        assertEquals("x7••••••••@privaterelay.appleid.com", InviteLogic.masked("x7d2k9q4mb@privaterelay.appleid.com"))
        assertEquals("ab•••@x.com", InviteLogic.masked("ab@x.com"))
        assertEquals("no-at-sign", InviteLogic.masked("no-at-sign"))
    }
}

/**
 * Accepting, declining and approving against the demo store, which mirrors
 * the backend's invite RPCs.
 */
class JoiningTest {
    @Test
    fun acceptingByIdJoinsAndShowsTheKameti() = runTest {
        val dependencies = SampleData.dependencies()
        assertFalse(dependencies.kametis.listKametis().any { it.id == "cousins" })
        val model = JoinInviteViewModel(null, "inv-cz3", dependencies)
        model.load()
        val preview = assertIs<Phase.Loaded>(model.state.value.phase).preview
        assertEquals("Cousins kameti", preview.kametiName)
        assertEquals("Ayesha Siddiqui", preview.ownerName)
        assertTrue(preview.emailMatches)
        assertEquals(Money(200_000), InviteLogic.monthlyTotal(preview.shares))
        assertEquals("cousins", model.accept())
        assertTrue(dependencies.kametis.listKametis().any { it.id == "cousins" })
        assertTrue(dependencies.invites.myInvitations().isEmpty())
        assertFalse(model.state.value.isBusy)
    }

    @Test
    fun aCodeWorksInAnyCase() = runTest {
        val model = JoinInviteViewModel(" czn7qk ", null, SampleData.dependencies())
        model.load()
        assertTrue(assertIs<Phase.Loaded>(model.state.value.phase).preview.isOpen)
    }

    @Test
    fun aWrongCodeFails() = runTest {
        val model = JoinInviteViewModel("ZZZZZZ", null, SampleData.dependencies())
        model.load()
        assertEquals(Phase.Failed(Failure.Server("invite_not_found")), model.state.value.phase)
    }

    @Test
    fun decliningRemovesTheInvitation() = runTest {
        val dependencies = SampleData.dependencies()
        val model = JoinInviteViewModel(null, "inv-cz3", dependencies)
        model.load()
        model.decline()
        assertEquals(Phase.Declined("Cousins kameti"), model.state.value.phase)
        assertTrue(dependencies.invites.myInvitations().isEmpty())
        // A declined invite can't be accepted any more.
        assertNull(model.accept())
    }

    @Test
    fun inboxListsInvitationsAndJoinRequests() = runTest {
        val dependencies = SampleData.dependencies()
        val inbox = InboxViewModel(SampleData.USER_ID, dependencies)
        inbox.load()
        assertEquals(listOf("inv-cz3"), inbox.state.value.invitations.map { it.inviteId })
        val request = inbox.state.value.requests.first()
        assertEquals("Hira Malik", request.member.name)
        assertEquals("hira.malik@gmail.com", request.invitedEmail)
        assertTrue(request.acceptedEmail!!.endsWith("privaterelay.appleid.com"))
        assertNull(inbox.approve(request))
        assertTrue(inbox.state.value.requests.isEmpty())
        assertEquals(JoinStatus.Joined, dependencies.kametis.members("family").first { it.id == "f5" }.joinStatus)
    }

    @Test
    fun rejectingAJoinRequestDeclinesTheMember() = runTest {
        val dependencies = SampleData.dependencies()
        val inbox = InboxViewModel(SampleData.USER_ID, dependencies)
        inbox.load()
        assertNull(inbox.reject(inbox.state.value.requests.first()))
        val hira = dependencies.kametis.members("family").first { it.id == "f5" }
        assertEquals(JoinStatus.Declined, hira.joinStatus)
        assertNull(hira.profileId)
    }
}

/** E39: an account already in the kameti is told up front and gets no Join button. */
class InvitePreviewBlockerTest {
    private fun preview(alreadyMember: Boolean? = null, name: String? = null, isOwner: Boolean? = null) = InvitePreview(
        inviteId = "i", status = "pending", expired = false, expiresAt = Instant.parse("2099-01-01T00:00:00Z"),
        emailMatches = false, kametiName = "Demo Office Kameti", ownerName = "Demo Owner", memberName = "Muhammad Hassan",
        alreadyMember = alreadyMember, alreadyMemberName = name, isOwner = isOwner,
    )

    @Test
    fun alreadyAMemberCantJoin() {
        val p = preview(alreadyMember = true, name = "Demo Member")
        assertFalse(p.canJoin)
        assertEquals(InviteLogic.Blocked.AlreadyMember("Demo Member", "Demo Owner"), InviteLogic.blocked(p))
    }

    @Test
    fun theOwnerCantJoin() {
        val p = preview(isOwner = true)
        assertFalse(p.canJoin)
        assertEquals(InviteLogic.Blocked.Owner, InviteLogic.blocked(p))
    }

    @Test
    fun anOlderBackendStillAllowsJoining() {
        val p = preview()
        assertTrue(p.canJoin)
        assertNull(InviteLogic.blocked(p))
    }
}

/** The Inbox's Updates feed (FR-86) against the demo store. */
class InboxUpdatesTest {
    @Test
    fun loadsUpdatesAndCountsUnread() = runTest {
        val model = InboxViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        val state = model.state.value
        assertTrue(state.hasLoaded)
        assertEquals(4, state.updates.size)
        assertEquals(2, state.unreadUpdates)
        assertEquals(state.needsYou + 2, state.badgeCount)
    }

    @Test
    fun markingReadClearsTheBadge() = runTest {
        val model = InboxViewModel(SampleData.USER_ID, SampleData.dependencies())
        model.load()
        model.markRead(model.state.value.updates.first { it.isUnread })
        assertEquals(1, model.state.value.unreadUpdates)
        model.markAllRead()
        assertEquals(0, model.state.value.unreadUpdates)
    }

    @Test
    fun agoReadsNaturally() {
        val now = Instant.parse("2026-11-10T08:00:00Z")
        assertEquals(Ago.JustNow, InboxLogic.ago(now.minusSeconds(30), now))
        assertEquals(Ago.Minutes(5), InboxLogic.ago(now.minusSeconds(5 * 60), now))
        assertEquals(Ago.Hours(3), InboxLogic.ago(now.minusSeconds(3 * 3600), now))
        assertEquals(Ago.Yesterday, InboxLogic.ago(now.minusSeconds(30 * 3600), now))
        assertIs<Ago.On>(InboxLogic.ago(now.minusSeconds(72 * 3600), now))
    }

    @Test
    fun onlyKametisYouCanSeeOpen() {
        assertTrue(AppNotification.opensKameti("payment"))
        assertTrue(AppNotification.opensKameti("joined"))
        assertFalse(AppNotification.opensKameti("join_declined"))
        assertFalse(AppNotification.opensKameti("invite"))
        assertFalse(AppNotification.opensKameti("join_request"))
    }
}
