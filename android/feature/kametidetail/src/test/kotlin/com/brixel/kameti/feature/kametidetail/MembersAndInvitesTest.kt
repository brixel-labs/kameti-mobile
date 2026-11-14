package com.brixel.kameti.feature.kametidetail

import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiJson
import com.brixel.kameti.domain.EmailDelivery
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.testsupport.SampleData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

private suspend fun loaded(kametiId: String = "family"): KametiDetailViewModel =
    KametiDetailViewModel(kametiId, SampleData.USER_ID, SampleData.dependencies()).also { it.load() }

private val KametiDetailViewModel.data: KametiDetailData
    get() = assertIs<KametiDetailViewModel.State.Loaded>(state.value).data

private fun KametiDetailData.member(id: String) = members.first { it.id == id }
private fun KametiDetailData.named(name: String) = members.first { it.name == name }

/**
 * Twin of MemberManagementTests.swift: add, edit and remove against the demo
 * store, which mirrors the backend's `add_member`, `update_member` and
 * `remove_member` rules.
 */
class MemberManagementTest {
    @Test
    fun addingANewPersonSavesThemToMyPeople() = runTest {
        val model = loaded()
        val before = model.data.members.size
        assertNull(model.addMember(NewMember(name = "  Zara Ahmed ", email = "Zara.Ahmed@gmail.com")))
        val after = model.data
        assertEquals(before + 1, after.members.size)
        val zara = after.named("Zara Ahmed")
        assertEquals(JoinStatus.NotInvited, zara.joinStatus)
        assertEquals("zara.ahmed@gmail.com", MemberLogic.contact(zara, after)?.email)
        // Nothing ties a new member to the ledger yet.
        assertNull(MemberLogic.removalBlock(zara, after))
    }

    @Test
    fun theSamePersonCantBeAddedTwice() = runTest {
        val model = loaded()
        val contact = MemberLogic.availableContacts(model.data).first()
        assertNull(model.addMember(NewMember(contactId = contact.id)))
        assertFalse(contact in MemberLogic.availableContacts(model.data))
        assertEquals(Failure.Server("contact_already_member"), model.addMember(NewMember(contactId = contact.id)))
    }

    @Test
    fun aBlankNameIsRejected() = runTest {
        assertEquals(Failure.Server("invalid_name"), loaded().addMember(NewMember(name = "   ")))
    }

    @Test
    fun editingChangesNameAndContact() = runTest {
        val model = loaded()
        val ali = model.data.member("f1")
        val changes = assertNotNull(MemberLogic.changes("Ali Raza Khan", "ali@x.com", "", ali, contact = null))
        assertNull(changes.phone)
        assertNull(model.updateMember(ali.id, changes))
        val after = model.data
        val updated = after.member("f1")
        assertEquals("Ali Raza Khan", updated.name)
        assertEquals("ali@x.com", MemberLogic.contact(updated, after)?.email)
        // Clearing the email with an empty string.
        assertNull(model.updateMember(ali.id, MemberChanges(email = "")))
        val cleared = model.data
        assertNull(MemberLogic.contact(cleared.member("f1"), cleared)?.email)
    }

    @Test
    fun aMemberWithSharesOrPaymentsCantBeRemoved() = runTest {
        val model = loaded()
        val ali = model.data.member("f1")
        val block = assertNotNull(MemberLogic.removalBlock(ali, model.data))
        assertEquals(2, block.slots) // month 1 and half of month 2
        assertEquals(Failure.Server("member_has_history"), model.removeMember(ali.id))
        assertTrue(model.data.members.any { it.id == "f1" })
    }

    @Test
    fun aMemberWithNothingOnTheLedgerIsRemoved() = runTest {
        val model = loaded()
        assertNull(model.addMember(NewMember(name = "Temp Person")))
        val temp = model.data.named("Temp Person")
        assertNull(model.removeMember(temp.id))
        assertFalse(model.data.members.any { it.id == temp.id })
    }

    @Test
    fun fieldChecks() {
        assertTrue(MemberLogic.isValidName("A"))
        assertFalse(MemberLogic.isValidName("  "))
        assertFalse(MemberLogic.isValidName("a".repeat(81)))
        assertTrue(MemberLogic.isValidEmail(""))
        assertTrue(MemberLogic.isValidEmail("a@b.co"))
        assertFalse(MemberLogic.isValidEmail("a@b"))
        assertFalse(MemberLogic.isValidEmail("a b@c.com"))
        assertTrue(MemberLogic.isValidPhone(""))
        assertTrue(MemberLogic.isValidPhone("+92 300-1234567"))
        assertFalse(MemberLogic.isValidPhone("12"))
        assertFalse(MemberLogic.isValidPhone("0300+123456"))
    }
}

/**
 * Twin of InviteAccessTests.swift: the owner's side of invites against the
 * demo store: the App access state of each member, sending, resending,
 * revoking and "Invite all".
 */
class InviteAccessTest {
    private fun state(id: String, data: KametiDetailData) = AccessState.of(data.member(id), data)

    @Test
    fun eachMemberGetsTheRightState() = runTest {
        val current = loaded().data
        assertEquals(AccessState.Joined, state("f1", current))
        assertEquals(
            AccessState.NeedsApproval("hira.malik@gmail.com", "x7d2k9q4mb@privaterelay.appleid.com"),
            state("f5", current),
        )
        val faisal = assertIs<AccessState.Invited>(state("f6", current))
        assertEquals("faisal.iqbal@gmail.com", faisal.invite.email)
        assertEquals(AccessState.Joined, state("f3", current))
        // Nobody left to invite: the rest have joined or have no email.
        assertTrue(AccessState.invitable(current).isEmpty())
    }

    @Test
    fun sendingShowsTheCodeAndRevokingTakesItBack() = runTest {
        val model = loaded()
        assertNull(model.addMember(NewMember(name = "Zara Ahmed", email = "zara@x.com")))
        val zara = model.data.named("Zara Ahmed")
        assertEquals(listOf(zara.id), AccessState.invitable(model.data).map { it.id })

        assertNull(model.invite(zara.id))
        val sent = assertNotNull(model.sentInvites.value[zara.id])
        assertEquals(6, sent.link.code.length)
        assertTrue(sent.link.link.endsWith(sent.link.token))
        assertFalse(sent.emailed) // email isn't set up in the demo
        assertIs<AccessState.Invited>(state(zara.id, model.data))

        // Sending again while one is live is refused; resending makes a new code.
        assertEquals(Failure.Server("invite_already_pending"), model.invite(zara.id))
        assertNull(model.invite(zara.id, resend = true))
        assertNotEquals(sent.link.inviteId, model.sentInvites.value[zara.id]?.link?.inviteId)

        assertNull(model.revokeInvite(zara.id))
        assertNull(model.sentInvites.value[zara.id])
        assertEquals(AccessState.NotInvited("zara@x.com", declined = false), state(zara.id, model.data))
    }

    @Test
    fun approvingAJoinFromTheMemberSheet() = runTest {
        val model = loaded()
        assertNull(model.approveJoin("f5"))
        assertEquals(AccessState.Joined, state("f5", model.data))
        assertEquals(Failure.Server("not_pending_approval"), model.approveJoin("f5"))
    }

    @Test
    fun removingAccessUnlinksAJoinedMember() = runTest {
        val model = loaded()
        val before = model.data
        assertEquals(AccessState.Joined, state("f1", before))
        assertNull(model.unlinkMember("f1"))
        val after = model.data
        val ali = after.member("f1")
        assertNull(ali.profileId)
        assertEquals(JoinStatus.NotInvited, ali.joinStatus)
        // Their record stays in the kameti.
        assertEquals(before.members.size, after.members.size)
        assertEquals(Failure.Server("member_not_linked"), model.unlinkMember("f1"))
    }

    @Test
    fun inviteAllInvitesEveryoneWithAnEmail() = runTest {
        val model = loaded()
        assertNull(model.addMember(NewMember(name = "A One", email = "a1@x.com")))
        assertNull(model.addMember(NewMember(name = "B Two", email = "b2@x.com")))
        assertNull(model.addMember(NewMember(name = "C Three")))
        val people = AccessState.invitable(model.data)
        assertEquals(listOf("A One", "B Two"), people.map { it.name })
        val result = model.inviteAll(people.map { it.id })
        assertEquals(2, result.invited)
        assertNull(result.failure)
        assertEquals(people.map { it.id }.toSet(), model.invitedThisRun.value)
        assertTrue(AccessState.invitable(model.data).isEmpty())
    }

    @Test
    fun theOwnersOwnRowHasNoAccessCard() = runTest {
        val data = loaded("office").data
        val me = data.members.first { it.profileId == SampleData.USER_ID }
        assertEquals(AccessState.Owner, AccessState.of(me, data))
    }
}

/** Twin of InviteDeliveryTests in InviteAccessTests.swift. */
class InviteDeliveryTest {
    @Test
    fun aBouncedEmailShowsOnTheInvite() = runTest {
        val data = loaded().data
        val invited = assertIs<AccessState.Invited>(AccessState.of(data.member("f6"), data))
        assertEquals(EmailDelivery.Bounced, invited.invite.deliveryStatus)
        assertEquals(true, invited.invite.deliveryStatus?.didNotArrive)
    }

    @Test
    fun theDeliveryStatusDecodesAndTheQueryNamesColumns() {
        val json = """{"id":"i1","kameti_id":"k","member_id":"m","status":"pending","expires_at":"2026-11-24T08:00:00Z","send_count":1,"email":"a@b.co","delivery_status":"complained"}"""
        val invite = KametiJson.json.decodeFromString<Invite>(json)
        assertEquals(EmailDelivery.Complained, invite.deliveryStatus)
        assertEquals(true, invite.deliveryStatus?.didNotArrive)
        // The table hides the token and code hashes, so the app must name its columns.
        assertFalse("*" in Invite.COLUMNS || "hash" in Invite.COLUMNS)
        assertTrue("delivery_status" in Invite.COLUMNS)
    }
}
