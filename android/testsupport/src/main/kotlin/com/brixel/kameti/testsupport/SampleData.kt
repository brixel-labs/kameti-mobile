package com.brixel.kameti.testsupport

import com.brixel.kameti.core.DateOnly
import com.brixel.kameti.core.Failure
import com.brixel.kameti.core.KametiClock
import com.brixel.kameti.core.Money
import com.brixel.kameti.domain.Contact
import com.brixel.kameti.domain.JoinStatus
import com.brixel.kameti.domain.Kameti
import com.brixel.kameti.domain.KametiDependencies
import com.brixel.kameti.domain.KametiStatus
import com.brixel.kameti.domain.Member
import com.brixel.kameti.domain.MemberBalanceRow
import com.brixel.kameti.domain.MemberMonthRow
import com.brixel.kameti.domain.MonthCollectionRow
import com.brixel.kameti.domain.MonthCollectionState
import com.brixel.kameti.domain.MonthStatusCode
import com.brixel.kameti.domain.Payment
import com.brixel.kameti.domain.PaymentMethod
import com.brixel.kameti.domain.Profile
import com.brixel.kameti.domain.Share
import com.brixel.kameti.domain.Slot
import com.brixel.kameti.core.Attempt
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset

/** Midnight UTC at the start of this day. */
internal fun LocalDate.utc(): Instant = atStartOfDay(ZoneOffset.UTC).toInstant()

internal const val HOUR = 3_600L
internal const val DAY = 86_400L

internal fun notFound() = Failure.Server("not_found")

/**
 * Believable sample kametis, so every screen can be seen without a backend
 * (the "demo" flavor, previews). Two kametis: one I run, one I'm a member of.
 */
object SampleData {
    const val USER_ID = "demo-user"

    fun dependencies(): KametiDependencies {
        val store = SamplePaymentStore()
        val people = SampleContactStore()
        val log = SampleAuditLog()
        val kametis = SampleKametiRepository(store, people, log)
        val auth = FakeAuthRepository(USER_ID)
        return KametiDependencies(
            kametis = kametis,
            ledger = SampleLedgerRepository(store),
            payments = SamplePaymentsRepository(store, log),
            invites = SampleInvitesRepository(kametis, people, log),
            audit = SampleAuditRepository(log, kametis),
            profiles = FakeProfileRepository(Attempt.Success(Profile(USER_ID, "Demo Owner"))),
            contacts = SampleContactsRepository(people),
            auth = auth,
            notes = SampleNotesRepository(kametis, store, log),
            account = SampleAccountRepository(kametis, people, auth),
            notifications = SampleNotificationsRepository(now),
            // The sample data is set in November 2026, so "today" is fixed there
            // whatever the phone's date is.
            clock = KametiClock { now },
        )
    }

    /** "Now" in the demo: 10 Nov 2026, 1 pm in Pakistan. */
    val now: Instant = DateOnly.make(2026, 11, 10).utc().plusSeconds(8 * HOUR)

    /** The demo account's email, which invites to it are addressed to. */
    const val EMAIL = "demo@kameti.test"

    val contacts = listOf(
        Contact("c1", USER_ID, "Ali Raza", email = "ali.raza@gmail.com"),
        Contact("c2", USER_ID, "Sara Khan", email = "sara.k@outlook.com"),
        Contact("c3", USER_ID, "Hira Shah"),
        Contact("c4", USER_ID, "Omar Farooq", email = "omar.f@gmail.com"),
        Contact("c5", USER_ID, "Zainab Tariq", email = "zainab.t@gmail.com"),
        Contact("c6", USER_ID, "Hira Malik", email = "hira.malik@gmail.com"),
        Contact("c7", USER_ID, "Faisal Iqbal", email = "faisal.iqbal@gmail.com"),
    )

    /** `month` is counted from year 2026 (13 = January 2027). */
    fun date(month: Int): LocalDate =
        if (month > 12) DateOnly.make(2027, month - 12) else DateOnly.make(2026, month)

    private fun share(id: String, kameti: String, slot: String, member: String, amount: Long) =
        Share(id, kameti, slot, member, Money(amount), effectiveFromMonth = 1)

    // Family kameti (I run it)

    val family = Kameti(
        id = "family", ownerId = USER_ID, name = "Family kameti", startMonth = date(10), monthsN = 6,
        slotAmountC = Money(250_000), dueDay = 10, reminderDays = listOf(1, 3), maxSlotsPerMember = 4,
        status = KametiStatus.Active,
    )
    val familyNames = listOf("Ali Raza", "Sara Khan", "Naveed Ahmed", "Osama Sheikh", "Hira Malik", "Faisal Iqbal")

    /**
     * Members added from My people stay linked to that person, like on the
     * backend, so "From my people" doesn't offer them again.
     */
    val familyContactIds = mapOf("Ali Raza" to "c1", "Sara Khan" to "c2", "Hira Malik" to "c6", "Faisal Iqbal" to "c7")
    val familyMembers = familyNames.mapIndexed { index, name ->
        Member(
            id = "f${index + 1}", kametiId = "family", name = name,
            // Hira accepted with another email and waits for approval; Faisal is invited.
            joinStatus = when (index) {
                5 -> JoinStatus.Invited
                4 -> JoinStatus.PendingApproval
                else -> JoinStatus.Joined
            },
            contactId = familyContactIds[name],
            // Joined members have an account, as on the backend.
            profileId = when (index) {
                4 -> "hira-account"
                5 -> null
                else -> "account-f${index + 1}"
            },
        )
    }
    val familySlots = (1..6).map { Slot("fs$it", "family", it) }

    /**
     * Month 2's slot is shared between Sara and Ali, so the payout screen
     * shows two recipients (Ali also owes dues, to try "take it from the payout").
     */
    val familyShares: List<Share> = (1..6).flatMap { month ->
        if (month == 2) {
            listOf(share("fh2a", "family", "fs2", "f2", 125_000), share("fh2b", "family", "fs2", "f1", 125_000))
        } else {
            listOf(share("fh$month", "family", "fs$month", "f$month", 250_000))
        }
    }

    // Friends kameti (I run it; month 2 pays out to three people)

    val friends = Kameti(
        id = "friends", ownerId = USER_ID, name = "Friends kameti", startMonth = date(10), monthsN = 3,
        slotAmountC = Money(300_000), dueDay = 12, reminderDays = listOf(1, 5), maxSlotsPerMember = 3,
        status = KametiStatus.Active,
    )
    val friendsMembers = listOf(
        Member("fr1", "friends", "Hamza Ali", JoinStatus.Joined),
        Member("fr2", "friends", "Zara Noor", JoinStatus.Joined),
        Member("fr3", "friends", "Bilal Khan", JoinStatus.Joined),
        Member("fr4", "friends", "Mehwish Raza", JoinStatus.Joined),
    )
    val friendsSlots = (1..3).map { Slot("frs$it", "friends", it) }
    val friendsShares = listOf(
        share("frh1", "friends", "frs1", "fr1", 300_000),
        share("frh2a", "friends", "frs2", "fr2", 150_000),
        share("frh2b", "friends", "frs2", "fr3", 100_000),
        share("frh2c", "friends", "frs2", "fr4", 50_000),
        share("frh3a", "friends", "frs3", "fr1", 100_000),
        share("frh3b", "friends", "frs3", "fr3", 200_000),
    )

    // Office kameti (I'm a member)

    val office = Kameti(
        id = "office", ownerId = "someone-else", name = "Office kameti", startMonth = date(10), monthsN = 4,
        slotAmountC = Money(100_000), dueDay = 5, reminderDays = listOf(1), maxSlotsPerMember = 4,
        status = KametiStatus.Active,
    )
    val officeMembers = listOf(
        Member("o1", "office", "Bilal Qureshi", JoinStatus.Joined),
        Member("o2", "office", "Demo Owner", JoinStatus.Joined, profileId = USER_ID),
        Member("o3", "office", "Zainab Tariq", JoinStatus.Joined),
        Member("o4", "office", "Usman Ghani", JoinStatus.Joined),
    )
    val officeSlots = (1..4).map { Slot("os$it", "office", it) }
    val officeShares = (1..4).map { share("oh$it", "office", "os$it", "o$it", 100_000) }

    // Cousins kameti (someone else runs it; I'm invited)

    val ownerNames = mapOf(USER_ID to "Demo Owner", "someone-else" to "Bilal Qureshi", "ayesha" to "Ayesha Siddiqui")

    val cousins = Kameti(
        id = "cousins", ownerId = "ayesha", name = "Cousins kameti", startMonth = date(11), monthsN = 4,
        slotAmountC = Money(200_000), dueDay = 15, reminderDays = listOf(1), maxSlotsPerMember = 2,
        status = KametiStatus.Active,
    )
    val cousinsMembers = listOf(
        Member("cz1", "cousins", "Ayesha Siddiqui", JoinStatus.Joined, profileId = "ayesha"),
        Member("cz2", "cousins", "Imran Shah", JoinStatus.Joined),
        Member("cz3", "cousins", "Demo Owner", JoinStatus.Invited),
        Member("cz4", "cousins", "Nadia Ali", JoinStatus.Joined),
    )
    val cousinsSlots = (1..4).map { Slot("czs$it", "cousins", it) }
    val cousinsShares = (1..4).map { share("czh$it", "cousins", "czs$it", "cz$it", 200_000) }

    // Neighbours kameti (my draft: slot 1 filled, 2 and 3 still empty)

    val neighbours = Kameti(
        id = "neighbours", ownerId = USER_ID, name = "Neighbours kameti", startMonth = date(12), monthsN = 3,
        slotAmountC = Money(150_000), dueDay = 5, reminderDays = listOf(1, 3), maxSlotsPerMember = 2,
        status = KametiStatus.Draft,
    )
    val neighboursMembers = listOf(
        Member("nb1", "neighbours", "Ali Raza", JoinStatus.NotInvited, contactId = "c1"),
        Member("nb2", "neighbours", "Omar Farooq", JoinStatus.NotInvited, contactId = "c4"),
    )
    val neighboursSlots = (1..3).map { Slot("nbs$it", "neighbours", it) }
    val neighboursShares = listOf(share("nbh1", "neighbours", "nbs1", "nb1", 150_000))

    // Friends kameti 2025 (mine, completed)

    val past = Kameti(
        id = "past-2025", ownerId = USER_ID, name = "Friends kameti 2025", startMonth = DateOnly.make(2025, 6),
        monthsN = 2, slotAmountC = Money(100_000), dueDay = 10, reminderDays = listOf(1), maxSlotsPerMember = 2,
        status = KametiStatus.Completed, startedAt = DateOnly.make(2025, 6).utc(),
    )
    val pastMembers = listOf(
        Member("p1", "past-2025", "Hamza Ali", JoinStatus.Joined),
        Member("p2", "past-2025", "Bilal Khan", JoinStatus.Joined),
    )
    val pastSlots = (1..2).map { Slot("ps$it", "past-2025", it) }
    val pastShares = (1..2).map { share("ph$it", "past-2025", "ps$it", "p$it", 100_000) }

    // Ledger

    fun collection(
        kametiId: String, month: Int, target: Long, received: Long, covered: Long, paid: Int, members: Int, current: Int,
    ): MonthCollectionRow {
        val isPast = month < current
        return MonthCollectionRow(
            kametiId = kametiId, monthIndex = month, monthStart = date(9 + month), isCurrent = month == current,
            target = Money(target), received = Money(received), covered = Money(covered), paidCount = paid,
            memberCount = members, payoutShortfall = Money.ZERO, paidOut = Money(if (isPast) target else 0),
            recipients = 1, recipientsPaid = if (isPast) 1 else 0, paidOutShortBy = Money.ZERO,
            state = when {
                isPast -> MonthCollectionState.PaidOut
                month == current -> MonthCollectionState.Collecting
                else -> MonthCollectionState.Upcoming
            },
        )
    }

    val familyCollections: List<MonthCollectionRow> = (1..6).map { month ->
        when (month) {
            1 -> collection("family", 1, 1_500_000, 1_500_000, 1_500_000, 6, 6, 2)
            2 -> collection("family", 2, 1_500_000, 1_000_000, 875_000, 3, 6, 2)
            else -> collection("family", month, 1_500_000, 0, 0, 0, 6, 2)
        }
    }
    val officeCollections: List<MonthCollectionRow> = (1..4).map { month ->
        when (month) {
            1 -> collection("office", 1, 400_000, 400_000, 400_000, 4, 4, 2)
            2 -> collection("office", 2, 400_000, 200_000, 200_000, 2, 4, 2)
            else -> collection("office", month, 400_000, 0, 0, 0, 4, 2)
        }
    }

    private class Standing(val id: String, val paid: Long, val balance: Long, val status: MonthStatusCode, val allocated: Long)

    /** (member, paid, balance owed, month-2 status, month-2 allocated) */
    private val familyStanding = listOf(
        Standing("f1", 500_000, 0, MonthStatusCode.Paid, 250_000),
        Standing("f2", 500_000, 0, MonthStatusCode.Paid, 250_000),
        Standing("f3", 625_000, -125_000, MonthStatusCode.Advance, 250_000),
        Standing("f4", 250_000, 250_000, MonthStatusCode.Unpaid, 0),
        Standing("f5", 375_000, 125_000, MonthStatusCode.Partial, 125_000),
        Standing("f6", 250_000, 250_000, MonthStatusCode.Unpaid, 0),
    )
    val familyBalances = familyStanding.map {
        MemberBalanceRow(
            kametiId = "family", memberId = it.id, currentMonthIndex = 2, monthlyDue = Money(250_000),
            dueToDate = Money(500_000), totalPaid = Money(it.paid), balance = Money(it.balance),
            owes = Money(maxOf(it.balance, 0)), credit = Money(maxOf(-it.balance, 0)),
        )
    }
    val familyMonths: List<MemberMonthRow> = familyStanding.flatMap {
        listOf(
            MemberMonthRow("family", it.id, 1, date(10), false, Money(250_000), Money(250_000), Money.ZERO, MonthStatusCode.Paid),
            MemberMonthRow("family", it.id, 2, date(11), true, Money(250_000), Money(it.allocated), Money(250_000 - it.allocated), it.status),
        )
    }
    val officeBalances = listOf("o1", "o2", "o3", "o4").map { id ->
        val owes = if (id == "o2") 100_000L else 0L
        MemberBalanceRow(
            kametiId = "office", memberId = id, currentMonthIndex = 2, monthlyDue = Money(100_000),
            dueToDate = Money(200_000), totalPaid = Money(200_000 - owes), balance = Money(owes),
            owes = Money(owes), credit = Money.ZERO,
        )
    }
    val officeMonths = listOf(
        MemberMonthRow("office", "o2", 1, date(10), false, Money(100_000), Money(100_000), Money.ZERO, MonthStatusCode.Paid),
        MemberMonthRow("office", "o2", 2, date(11), true, Money(100_000), Money.ZERO, Money(100_000), MonthStatusCode.Unpaid),
    )

    // Payments

    fun payment(
        id: String, kameti: String, member: String, amount: Long, month: Int, day: Int,
        method: PaymentMethod = PaymentMethod.Cash, reference: String? = null,
    ): Payment {
        val received = date(month).withDayOfMonth(day)
        return Payment(
            id = id, kametiId = kameti, memberId = member, amount = Money(amount), receivedOn = received,
            method = method, createdAt = received.utc().plusSeconds(HOUR), reference = reference,
        )
    }

    val familyPayments: List<Payment> =
        (1..6).map {
            payment(
                "fp$it", "family", "f$it", 250_000, month = 10, day = 4 + it,
                method = if (it == 3) PaymentMethod.BankTransfer else PaymentMethod.Cash,
                reference = if (it == 3) "88213" else null,
            )
        } + listOf(
            payment("fp7", "family", "f1", 250_000, 11, 3),
            payment("fp8", "family", "f2", 250_000, 11, 4),
            payment("fp9", "family", "f3", 375_000, 11, 6, PaymentMethod.BankTransfer, "88990"),
            payment("fp10", "family", "f5", 125_000, 11, 8),
        )

    /** October fully paid; November short by Rs 1,00,000 (Zara and Mehwish owe). */
    val friendsPayments = listOf(
        payment("frp1", "friends", "fr1", 400_000, 10, 3), payment("frp2", "friends", "fr2", 150_000, 10, 4),
        payment("frp3", "friends", "fr3", 300_000, 10, 4), payment("frp4", "friends", "fr4", 50_000, 10, 6),
        payment("frp5", "friends", "fr1", 400_000, 11, 2), payment("frp6", "friends", "fr3", 300_000, 11, 5),
        payment("frp7", "friends", "fr2", 100_000, 11, 7),
    )

    val officePayments = listOf(
        payment("op1", "office", "o1", 100_000, 10, 2), payment("op2", "office", "o2", 100_000, 10, 3),
        payment("op3", "office", "o3", 100_000, 10, 3), payment("op4", "office", "o4", 100_000, 10, 4),
        payment("op5", "office", "o1", 100_000, 11, 2), payment("op6", "office", "o3", 100_000, 11, 4),
    )

    /** Friends kameti 2025 (June–July 2025): both paid in full and both paid out. */
    val pastPayments: List<Payment> = listOf(1 to 6, 2 to 6, 1 to 7, 2 to 7).mapIndexed { index, (member, month) ->
        val received = DateOnly.make(2025, month, 5)
        Payment(
            id = "pp${index + 1}", kametiId = "past-2025", memberId = "p$member", amount = Money(100_000),
            receivedOn = received, method = PaymentMethod.Cash, createdAt = received.utc().plusSeconds(HOUR),
        )
    }
}
