package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Failure
import com.brixel.kameti.domain.AuditEntry
import com.brixel.kameti.domain.AuditRepository
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.ContactsRepository
import com.brixel.kameti.domain.Invite
import com.brixel.kameti.domain.InviteLink
import com.brixel.kameti.domain.InvitePreview
import com.brixel.kameti.domain.InvitesRepository
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiChanges
import com.brixel.kameti.domain.KametiRepository
import com.brixel.kameti.domain.LedgerRepository
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberChanges
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MyInvitation
import com.brixel.kameti.domain.NewKameti
import com.brixel.kameti.domain.NewMember
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.PaymentsRepository
import com.brixel.kameti.domain.Payout
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.ShareInput
import com.brixel.kameti.domain.Slot

private fun notStubbed(): Nothing = throw Failure.Unknown("not stubbed in this test")

/**
 * Satisfies every repository interface except the ones a test cares about:
 * each call fails with an "unused" failure, so a test that touches one by
 * accident fails loudly.
 */
class UnusedRepositories : LedgerRepository, PaymentsRepository, InvitesRepository, AuditRepository, ContactsRepository {
    // LedgerRepository
    override suspend fun memberBalances(kametiId: String): List<MemberBalanceRow> = notStubbed()
    override suspend fun memberMonths(kametiId: String, memberId: String?): List<MemberMonthRow> = notStubbed()
    override suspend fun monthCollections(kametiId: String): List<MonthCollectionRow> = notStubbed()

    // PaymentsRepository
    override suspend fun payments(kametiId: String): List<Payment> = notStubbed()
    override suspend fun payouts(kametiId: String): List<Payout> = notStubbed()
    override suspend fun recordPayment(new: NewPayment): Payment = notStubbed()
    override suspend fun recordPayments(
        kametiId: String, receivedOn: Day, items: List<BatchPaymentItem>, method: PaymentMethod,
    ): List<Payment> = notStubbed()
    override suspend fun voidPayment(id: String, reason: String): Payment = notStubbed()
    override suspend fun recordPayout(new: NewPayout): Payout = notStubbed()
    override suspend fun voidPayout(id: String, reason: String): Payout = notStubbed()

    // InvitesRepository
    override suspend fun createInvite(memberId: String): InviteLink = notStubbed()
    override suspend fun resendInvite(memberId: String): InviteLink = notStubbed()
    override suspend fun revokeInvite(memberId: String): Member = notStubbed()
    override suspend fun approveJoin(memberId: String): Member = notStubbed()
    override suspend fun declineJoin(memberId: String): Member = notStubbed()
    override suspend fun unlinkMember(memberId: String): Member = notStubbed()
    override suspend fun sendInviteEmail(link: InviteLink): Boolean = notStubbed()
    override suspend fun invites(kametiId: String): List<Invite> = notStubbed()
    override suspend fun previewInvite(token: String?, inviteId: String?): InvitePreview = notStubbed()
    override suspend fun acceptInvite(token: String?, inviteId: String?): Member = notStubbed()
    override suspend fun declineInvite(token: String?, inviteId: String?): Member = notStubbed()
    override suspend fun myInvitations(): List<MyInvitation> = notStubbed()

    // AuditRepository
    override suspend fun audit(kametiId: String, limit: Int): List<AuditEntry> = notStubbed()

    // ContactsRepository
    override suspend fun contacts(): List<Contact> = notStubbed()
}

/**
 * A `KametiRepository` that only knows its list of kametis; every other
 * call fails as "not stubbed".
 */
class StubKametiRepository(
    private val kametis: List<Kameti> = emptyList(),
    private val members: List<Member> = emptyList(),
    private val slots: List<Slot> = emptyList(),
    private val shares: List<Share> = emptyList(),
) : KametiRepository {
    override suspend fun listKametis(): List<Kameti> = kametis
    override suspend fun kameti(id: String): Kameti = kametis.firstOrNull { it.id == id } ?: throw notFound()
    override suspend fun members(kametiId: String): List<Member> = members
    override suspend fun slots(kametiId: String): List<Slot> = slots
    override suspend fun shares(kametiId: String): List<Share> = shares
    override suspend fun createKameti(new: NewKameti): Kameti = notStubbed()
    override suspend fun updateKameti(id: String, changes: KametiChanges): Kameti = notStubbed()
    override suspend fun startKameti(id: String): Kameti = notStubbed()
    override suspend fun archiveKameti(id: String): Kameti = notStubbed()
    override suspend fun reopenKameti(id: String): Kameti = notStubbed()
    override suspend fun restoreKameti(id: String): Kameti = notStubbed()
    override suspend fun duplicateKameti(id: String, name: String, startMonth: Day): Kameti = notStubbed()
    override suspend fun addMember(kametiId: String, new: NewMember): Member = notStubbed()
    override suspend fun updateMember(id: String, changes: MemberChanges): Member = notStubbed()
    override suspend fun removeMember(id: String): Unit = notStubbed()
    override suspend fun setSlotShares(slotId: String, shares: List<ShareInput>): List<Share> = notStubbed()
    override suspend fun transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?): Share = notStubbed()
    override suspend fun reorderSlots(kametiId: String, slotIdsInOrder: List<String>): List<Slot> = notStubbed()
}

/** A ledger repository that returns fixed rows, or always fails. */
class StubLedgerRepository(
    private val balances: List<MemberBalanceRow> = emptyList(),
    private val months: List<MemberMonthRow> = emptyList(),
    private val collections: List<MonthCollectionRow> = emptyList(),
    private val failure: Failure? = null,
) : LedgerRepository {
    override suspend fun memberBalances(kametiId: String): List<MemberBalanceRow> = failure?.let { throw it } ?: balances
    override suspend fun memberMonths(kametiId: String, memberId: String?): List<MemberMonthRow> {
        failure?.let { throw it }
        return if (memberId == null) months else months.filter { it.memberId == memberId }
    }
    override suspend fun monthCollections(kametiId: String): List<MonthCollectionRow> = failure?.let { throw it } ?: collections
}

class StubPaymentsRepository(private val rows: List<Payment> = emptyList()) : PaymentsRepository {
    override suspend fun payments(kametiId: String): List<Payment> = rows
    override suspend fun payouts(kametiId: String): List<Payout> = emptyList()
    override suspend fun recordPayment(new: NewPayment): Payment = notStubbed()
    override suspend fun recordPayments(
        kametiId: String, receivedOn: Day, items: List<BatchPaymentItem>, method: PaymentMethod,
    ): List<Payment> = notStubbed()
    override suspend fun voidPayment(id: String, reason: String): Payment = notStubbed()
    override suspend fun recordPayout(new: NewPayout): Payout = notStubbed()
    override suspend fun voidPayout(id: String, reason: String): Payout = notStubbed()
}
