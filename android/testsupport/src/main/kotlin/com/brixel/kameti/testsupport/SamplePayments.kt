package com.brixel.kameti.testsupport

import com.brixel.kameti.core.Day
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.BatchPaymentItem
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.LedgerRepository
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.NewPayment
import com.brixel.kameti.domain.NewPayout
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.PaymentsRepository
import com.brixel.kameti.domain.Payout
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import java.time.Instant
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.UUID

/**
 * The recorded payments of the sample kametis, shared by the ledger and the
 * payments repositories so a payment recorded in the demo shows up in the
 * balances, statuses and collections too.
 */
class SamplePaymentStore {
    private val lock = Any()
    private val payments = mutableMapOf(
        "family" to SampleData.familyPayments, "friends" to SampleData.friendsPayments,
        "office" to SampleData.officePayments, "past-2025" to SampleData.pastPayments,
    )
    private val payouts = mutableMapOf<String, List<Payout>>()

    fun all(kametiId: String): List<Payment> = synchronized(lock) { payments[kametiId].orEmpty() }

    fun payouts(kametiId: String): List<Payout> = synchronized(lock) { payouts[kametiId].orEmpty() }

    fun add(payment: Payment): Unit = synchronized(lock) {
        payments[payment.kametiId] = payments[payment.kametiId].orEmpty() + payment
    }

    fun add(payout: Payout): Unit = synchronized(lock) {
        payouts[payout.kametiId] = payouts[payout.kametiId].orEmpty() + payout
    }

    fun void(id: String, reason: String): Payment? = synchronized(lock) {
        for ((key, rows) in payments) {
            val old = rows.firstOrNull { it.id == id } ?: continue
            val voided = old.copy(voidedAt = Instant.now(), voidReason = reason)
            payments[key] = rows.map { if (it.id == id) voided else it }
            return voided
        }
        null
    }

    fun voidPayout(id: String, reason: String): Payout? = synchronized(lock) {
        for ((key, rows) in payouts) {
            val old = rows.firstOrNull { it.id == id } ?: continue
            val voided = old.copy(voidedAt = Instant.now(), voidReason = reason)
            payouts[key] = rows.map { if (it.id == id) voided else it }
            return voided
        }
        null
    }
}

/**
 * A small stand-in for the backend's ledger views: oldest due first, so the
 * demo's balances and statuses follow the payments.
 */
object SampleLedger {
    class Result(
        val balances: List<MemberBalanceRow> = emptyList(),
        val months: List<MemberMonthRow> = emptyList(),
        val collections: List<MonthCollectionRow> = emptyList(),
    )

    fun compute(
        kameti: Kameti, members: List<Member>, shares: List<Share>, slots: List<Slot>,
        payments: List<Payment>, payouts: List<Payout>, current: Int, finished: Boolean = false,
    ): Result {
        val balances = mutableListOf<MemberBalanceRow>()
        val months = mutableListOf<MemberMonthRow>()
        val collections = mutableListOf<MonthCollectionRow>()
        // A finished kameti has no current month: every month is in the past.
        fun isBefore(month: Int) = if (finished) month <= current else month < current
        fun isNow(month: Int) = !finished && month == current
        val valid = payments.filter { it.voidedAt == null }
        fun monthIndex(date: LocalDate) = ChronoUnit.MONTHS.between(kameti.startMonth, date).toInt() + 1
        fun start(index: Int) = kameti.startMonth.plusMonths((index - 1).toLong())
        val allocatedByMonth = mutableMapOf<Int, Long>()
        val paidCountByMonth = mutableMapOf<Int, Int>()
        for (member in members) {
            val due = shares.filter { it.memberId == member.id && it.effectiveToMonth == null }.sumOf { it.monthlyAmount.rupees }
            if (due <= 0) continue
            val paid = valid.filter { it.memberId == member.id }.sumOf { it.amount.rupees }
            var left = paid
            for (month in 1..maxOf(current, 1)) {
                val allocated = minOf(due, left)
                left -= allocated
                allocatedByMonth[month] = (allocatedByMonth[month] ?: 0) + allocated
                if (allocated >= due) paidCountByMonth[month] = (paidCountByMonth[month] ?: 0) + 1
                val status = when {
                    allocated >= due -> if (left > 0 && month == current) MonthStatusCode.Advance else MonthStatusCode.Paid
                    allocated == 0L -> if (month < current) MonthStatusCode.Overdue else MonthStatusCode.Unpaid
                    else -> MonthStatusCode.Partial
                }
                months += MemberMonthRow(
                    kametiId = kameti.id, memberId = member.id, monthIndex = month, monthStart = start(month),
                    isCurrent = isNow(month), due = Money(due), allocated = Money(allocated),
                    remaining = Money(due - allocated), status = status,
                )
            }
            val dueToDate = due * current
            balances += MemberBalanceRow(
                kametiId = kameti.id, memberId = member.id, currentMonthIndex = current, monthlyDue = Money(due),
                dueToDate = Money(dueToDate), totalPaid = Money(paid), balance = Money(dueToDate - paid),
                owes = Money(maxOf(dueToDate - paid, 0)), credit = Money(maxOf(paid - dueToDate, 0)),
            )
        }
        val payers = members.count { member -> shares.any { it.memberId == member.id && it.effectiveToMonth == null } }
        val target = kameti.pot.rupees
        for (month in 1..kameti.monthsN) {
            val received = valid.filter { monthIndex(it.receivedOn) == month }.sumOf { it.amount.rupees }
            val slotIds = slots.filter { it.payoutMonthIndex == month }.map { it.id }.toSet()
            val paidOut = payouts.filter { it.voidedAt == null && it.slotId in slotIds }.sumOf { it.amount.rupees }
            val state = when {
                paidOut > 0 -> if (paidOut >= target) MonthCollectionState.PaidOut else MonthCollectionState.PaidOutShort
                isBefore(month) -> MonthCollectionState.PaidOut
                isNow(month) -> if (received >= target) MonthCollectionState.FullyCollected else MonthCollectionState.Collecting
                else -> MonthCollectionState.Upcoming
            }
            collections += MonthCollectionRow(
                kametiId = kameti.id, monthIndex = month, monthStart = start(month), isCurrent = isNow(month),
                target = Money(target), received = Money(received), covered = Money(allocatedByMonth[month] ?: 0),
                paidCount = paidCountByMonth[month] ?: 0, memberCount = payers,
                payoutShortfall = Money(if (month <= current) maxOf(target - received, 0) else 0),
                paidOut = Money(if (paidOut > 0) paidOut else if (isBefore(month)) target else 0),
                recipients = 1, recipientsPaid = if (isBefore(month)) 1 else 0,
                paidOutShortBy = Money(if (paidOut > 0) maxOf(target - paidOut, 0) else 0), state = state,
            )
        }
        return Result(balances, months, collections)
    }
}

class SampleLedgerRepository(private val store: SamplePaymentStore) : LedgerRepository {
    private fun ledger(kametiId: String): SampleLedger.Result {
        fun compute(k: Kameti, m: List<Member>, sh: List<Share>, sl: List<Slot>, current: Int, finished: Boolean = false) =
            SampleLedger.compute(k, m, sh, sl, store.all(kametiId), store.payouts(kametiId), current, finished)
        return when (kametiId) {
            "family" -> compute(SampleData.family, SampleData.familyMembers, SampleData.familyShares, SampleData.familySlots, 2)
            "friends" -> compute(SampleData.friends, SampleData.friendsMembers, SampleData.friendsShares, SampleData.friendsSlots, 2)
            "office" -> compute(SampleData.office, SampleData.officeMembers, SampleData.officeShares, SampleData.officeSlots, 2)
            "cousins" -> compute(SampleData.cousins, SampleData.cousinsMembers, SampleData.cousinsShares, SampleData.cousinsSlots, 1)
            "past-2025" -> compute(SampleData.past, SampleData.pastMembers, SampleData.pastShares, SampleData.pastSlots, 2, finished = true)
            else -> SampleLedger.Result()
        }
    }

    override suspend fun memberBalances(kametiId: String) = ledger(kametiId).balances
    override suspend fun memberMonths(kametiId: String, memberId: String?) =
        ledger(kametiId).months.filter { memberId == null || it.memberId == memberId }
    override suspend fun monthCollections(kametiId: String) = ledger(kametiId).collections
}

class SamplePaymentsRepository(
    private val store: SamplePaymentStore,
    private val log: SampleAuditLog = SampleAuditLog(),
) : PaymentsRepository {
    private fun newId() = UUID.randomUUID().toString()

    override suspend fun payments(kametiId: String) = store.all(kametiId)
    override suspend fun payouts(kametiId: String) = store.payouts(kametiId)

    override suspend fun recordPayment(new: NewPayment): Payment {
        if (!new.amount.isPositive) throw Failure.Server("invalid_amount")
        val kametiId = when {
            SampleData.familyMembers.any { it.id == new.memberId } -> "family"
            SampleData.friendsMembers.any { it.id == new.memberId } -> "friends"
            else -> "office"
        }
        val payment = Payment(
            id = newId(), kametiId = kametiId, memberId = new.memberId, amount = new.amount,
            receivedOn = new.receivedOn, method = new.method, createdAt = Instant.now(),
            reference = new.reference, note = new.note, paidByName = new.paidByName,
        )
        store.add(payment)
        log.record(kametiId, "payment.record", entity = "payment", entityId = payment.id, member = payment.memberId, after = SampleAuditLog.payment(payment))
        return payment
    }

    override suspend fun recordPayments(
        kametiId: String, receivedOn: Day, items: List<BatchPaymentItem>, method: PaymentMethod,
    ): List<Payment> = items.map { item ->
        val payment = Payment(
            id = newId(), kametiId = kametiId, memberId = item.memberId, amount = item.amount,
            receivedOn = receivedOn, method = method, createdAt = Instant.now(),
        )
        store.add(payment)
        log.record(kametiId, "payment.record", entity = "payment", entityId = payment.id, member = payment.memberId, after = SampleAuditLog.payment(payment))
        payment
    }

    override suspend fun voidPayment(id: String, reason: String): Payment {
        val voided = store.void(id, reason) ?: throw notFound()
        log.record(voided.kametiId, "payment.void", entity = "payment", entityId = id, member = voided.memberId, after = SampleAuditLog.payment(voided))
        return voided
    }

    override suspend fun recordPayout(new: NewPayout): Payout {
        if (!new.amount.isPositive) throw Failure.Server("invalid_amount")
        val payout = Payout(
            id = newId(),
            kametiId = when {
                new.slotId.startsWith("fs") -> "family"
                new.slotId.startsWith("frs") -> "friends"
                else -> "office"
            },
            slotId = new.slotId, memberId = new.memberId, amount = new.amount, paidOn = new.paidOn,
            method = new.method, reference = new.reference, note = new.note,
        )
        store.add(payout)
        log.record(payout.kametiId, "payout.record", entity = "payout", entityId = payout.id, member = payout.memberId, after = SampleAuditLog.payout(payout))
        return payout
    }

    override suspend fun voidPayout(id: String, reason: String): Payout {
        val voided = store.voidPayout(id, reason) ?: throw notFound()
        log.record(voided.kametiId, "payout.void", entity = "payout", entityId = id, member = voided.memberId, after = SampleAuditLog.payout(voided))
        return voided
    }
}
