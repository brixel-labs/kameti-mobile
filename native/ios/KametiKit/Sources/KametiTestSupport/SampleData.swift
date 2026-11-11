import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// Believable sample kametis, so every screen can be seen without a backend
/// (the "demo" flavor, previews). Two kametis: one I run, one I'm a member of.
public enum SampleData {
    public static let userId = "demo-user"

    public static func dependencies() -> KametiDependencies {
        let store = SamplePaymentStore()
        let people = SampleContactStore()
        let log = SampleAuditLog()
        let kametis = SampleKametiRepository(payments: store, contacts: people, log: log)
        let auth = FakeAuthRepository(userId: userId)
        return KametiDependencies(
            kametis: kametis, ledger: SampleLedgerRepository(store: store), payments: SamplePaymentsRepository(store: store, log: log),
            invites: SampleInvitesRepository(kametis: kametis, contacts: people, log: log), audit: SampleAuditRepository(log: log, kametis: kametis),
            profiles: FakeProfileRepository(.success(Profile(id: userId, displayName: "Demo Owner"))),
            contacts: SampleContactsRepository(store: people), auth: auth,
            notes: SampleNotesRepository(kametis: kametis, payments: store, log: log),
            account: SampleAccountRepository(kametis: kametis, contacts: people, auth: auth),
            // The sample data is set in November 2026, so "today" is fixed there
            // whatever the phone's date is.
            clock: KametiClock(nowUTC: { now })
        )
    }

    /// "Now" in the demo: 10 Nov 2026, 1 pm in Pakistan.
    static let now = DateOnly.make(year: 2026, month: 11, day: 10).addingTimeInterval(8 * 3600)
    /// The demo account's email, which invites to it are addressed to.
    static let email = "demo@kameti.test"

    public static let contacts = [
        Contact(id: "c1", ownerId: userId, name: "Ali Raza", email: "ali.raza@gmail.com"),
        Contact(id: "c2", ownerId: userId, name: "Sara Khan", email: "sara.k@outlook.com"),
        Contact(id: "c3", ownerId: userId, name: "Hira Shah"),
        Contact(id: "c4", ownerId: userId, name: "Omar Farooq", email: "omar.f@gmail.com"),
        Contact(id: "c5", ownerId: userId, name: "Zainab Tariq", email: "zainab.t@gmail.com"),
        Contact(id: "c6", ownerId: userId, name: "Hira Malik", email: "hira.malik@gmail.com"),
        Contact(id: "c7", ownerId: userId, name: "Faisal Iqbal", email: "faisal.iqbal@gmail.com"),
    ]

    // MARK: Family kameti (I run it)

    static let family = Kameti(
        id: "family", ownerId: userId, name: "Family kameti", startMonth: date(10), monthsN: 6,
        slotAmountC: Money(250_000), dueDay: 10, reminderDays: [1, 3], maxSlotsPerMember: 4, status: .active
    )
    static let familyNames = ["Ali Raza", "Sara Khan", "Naveed Ahmed", "Osama Sheikh", "Hira Malik", "Faisal Iqbal"]
    /// Members added from My people stay linked to that person, like on the
    /// backend, so "From my people" doesn't offer them again.
    static let familyContactIds = ["Ali Raza": "c1", "Sara Khan": "c2", "Hira Malik": "c6", "Faisal Iqbal": "c7"]
    static let familyMembers = familyNames.enumerated().map {
        Member(
            id: "f\($0.offset + 1)", kametiId: "family", name: $0.element,
            // Hira accepted with another email and waits for approval; Faisal is invited.
            joinStatus: $0.offset == 5 ? .invited : ($0.offset == 4 ? .pendingApproval : .joined),
            // Joined members have an account, as on the backend.
            contactId: familyContactIds[$0.element],
            profileId: $0.offset == 4 ? "hira-account" : ($0.offset == 5 ? nil : "account-f\($0.offset + 1)")
        )
    }
    static let familySlots = (1...6).map { Slot(id: "fs\($0)", kametiId: "family", payoutMonthIndex: $0) }
    /// Month 2's slot is shared between Sara and Ali, so the payout screen
    /// shows two recipients (Ali also owes dues, to try "take it from the payout").
    static let familyShares: [Share] = (1...6).flatMap { month -> [Share] in
        if month == 2 {
            return [
                Share(id: "fh2a", kametiId: "family", slotId: "fs2", memberId: "f2", monthlyAmount: Money(125_000), effectiveFromMonth: 1),
                Share(id: "fh2b", kametiId: "family", slotId: "fs2", memberId: "f1", monthlyAmount: Money(125_000), effectiveFromMonth: 1),
            ]
        }
        return [Share(id: "fh\(month)", kametiId: "family", slotId: "fs\(month)", memberId: "f\(month)", monthlyAmount: Money(250_000), effectiveFromMonth: 1)]
    }

    // MARK: Friends kameti (I run it; month 2 pays out to three people)

    static let friends = Kameti(
        id: "friends", ownerId: userId, name: "Friends kameti", startMonth: date(10), monthsN: 3,
        slotAmountC: Money(300_000), dueDay: 12, reminderDays: [1, 5], maxSlotsPerMember: 3, status: .active
    )
    static let friendsMembers = [
        Member(id: "fr1", kametiId: "friends", name: "Hamza Ali", joinStatus: .joined),
        Member(id: "fr2", kametiId: "friends", name: "Zara Noor", joinStatus: .joined),
        Member(id: "fr3", kametiId: "friends", name: "Bilal Khan", joinStatus: .joined),
        Member(id: "fr4", kametiId: "friends", name: "Mehwish Raza", joinStatus: .joined),
    ]
    static let friendsSlots = (1...3).map { Slot(id: "frs\($0)", kametiId: "friends", payoutMonthIndex: $0) }
    static let friendsShares = [
        Share(id: "frh1", kametiId: "friends", slotId: "frs1", memberId: "fr1", monthlyAmount: Money(300_000), effectiveFromMonth: 1),
        Share(id: "frh2a", kametiId: "friends", slotId: "frs2", memberId: "fr2", monthlyAmount: Money(150_000), effectiveFromMonth: 1),
        Share(id: "frh2b", kametiId: "friends", slotId: "frs2", memberId: "fr3", monthlyAmount: Money(100_000), effectiveFromMonth: 1),
        Share(id: "frh2c", kametiId: "friends", slotId: "frs2", memberId: "fr4", monthlyAmount: Money(50_000), effectiveFromMonth: 1),
        Share(id: "frh3a", kametiId: "friends", slotId: "frs3", memberId: "fr1", monthlyAmount: Money(100_000), effectiveFromMonth: 1),
        Share(id: "frh3b", kametiId: "friends", slotId: "frs3", memberId: "fr3", monthlyAmount: Money(200_000), effectiveFromMonth: 1),
    ]

    // MARK: Office kameti (I'm a member)

    static let office = Kameti(
        id: "office", ownerId: "someone-else", name: "Office kameti", startMonth: date(10), monthsN: 4,
        slotAmountC: Money(100_000), dueDay: 5, reminderDays: [1], maxSlotsPerMember: 4, status: .active
    )
    static let officeMembers = [
        Member(id: "o1", kametiId: "office", name: "Bilal Qureshi", joinStatus: .joined),
        Member(id: "o2", kametiId: "office", name: "Demo Owner", joinStatus: .joined, profileId: userId),
        Member(id: "o3", kametiId: "office", name: "Zainab Tariq", joinStatus: .joined),
        Member(id: "o4", kametiId: "office", name: "Usman Ghani", joinStatus: .joined),
    ]
    static let officeSlots = (1...4).map { Slot(id: "os\($0)", kametiId: "office", payoutMonthIndex: $0) }
    static let officeShares = (1...4).map {
        Share(id: "oh\($0)", kametiId: "office", slotId: "os\($0)", memberId: "o\($0)", monthlyAmount: Money(100_000), effectiveFromMonth: 1)
    }

    // MARK: Cousins kameti (someone else runs it; I'm invited)

    static let ownerNames = [userId: "Demo Owner", "someone-else": "Bilal Qureshi", "ayesha": "Ayesha Siddiqui"]

    static let cousins = Kameti(
        id: "cousins", ownerId: "ayesha", name: "Cousins kameti", startMonth: date(11), monthsN: 4,
        slotAmountC: Money(200_000), dueDay: 15, reminderDays: [1], maxSlotsPerMember: 2, status: .active
    )
    static let cousinsMembers = [
        Member(id: "cz1", kametiId: "cousins", name: "Ayesha Siddiqui", joinStatus: .joined, profileId: "ayesha"),
        Member(id: "cz2", kametiId: "cousins", name: "Imran Shah", joinStatus: .joined),
        Member(id: "cz3", kametiId: "cousins", name: "Demo Owner", joinStatus: .invited),
        Member(id: "cz4", kametiId: "cousins", name: "Nadia Ali", joinStatus: .joined),
    ]
    static let cousinsSlots = (1...4).map { Slot(id: "czs\($0)", kametiId: "cousins", payoutMonthIndex: $0) }
    static let cousinsShares = (1...4).map {
        Share(id: "czh\($0)", kametiId: "cousins", slotId: "czs\($0)", memberId: "cz\($0)", monthlyAmount: Money(200_000), effectiveFromMonth: 1)
    }

    // MARK: Neighbours kameti (my draft: slot 1 filled, 2 and 3 still empty)

    static let neighbours = Kameti(
        id: "neighbours", ownerId: userId, name: "Neighbours kameti", startMonth: date(12), monthsN: 3,
        slotAmountC: Money(150_000), dueDay: 5, reminderDays: [1, 3], maxSlotsPerMember: 2, status: .draft
    )
    static let neighboursMembers = [
        Member(id: "nb1", kametiId: "neighbours", name: "Ali Raza", joinStatus: .notInvited, contactId: "c1"),
        Member(id: "nb2", kametiId: "neighbours", name: "Omar Farooq", joinStatus: .notInvited, contactId: "c4"),
    ]
    static let neighboursSlots = (1...3).map { Slot(id: "nbs\($0)", kametiId: "neighbours", payoutMonthIndex: $0) }
    static let neighboursShares = [
        Share(id: "nbh1", kametiId: "neighbours", slotId: "nbs1", memberId: "nb1", monthlyAmount: Money(150_000), effectiveFromMonth: 1),
    ]

    // MARK: Friends kameti 2025 (mine, completed)

    static let past = Kameti(
        id: "past-2025", ownerId: userId, name: "Friends kameti 2025", startMonth: DateOnly.make(year: 2025, month: 6), monthsN: 2,
        slotAmountC: Money(100_000), dueDay: 10, reminderDays: [1], maxSlotsPerMember: 2, status: .completed,
        startedAt: DateOnly.make(year: 2025, month: 6)
    )
    static let pastMembers = [
        Member(id: "p1", kametiId: "past-2025", name: "Hamza Ali", joinStatus: .joined),
        Member(id: "p2", kametiId: "past-2025", name: "Bilal Khan", joinStatus: .joined),
    ]
    static let pastSlots = (1...2).map { Slot(id: "ps\($0)", kametiId: "past-2025", payoutMonthIndex: $0) }
    static let pastShares = (1...2).map {
        Share(id: "ph\($0)", kametiId: "past-2025", slotId: "ps\($0)", memberId: "p\($0)", monthlyAmount: Money(100_000), effectiveFromMonth: 1)
    }

    // MARK: Ledger

    static func collection(
        _ kametiId: String, month: Int, target: Int, received: Int, covered: Int, paid: Int, members: Int, current: Int, n: Int
    ) -> MonthCollectionRow {
        let isPast = month < current
        let state: MonthCollectionState = isPast ? .paidOut : (month == current ? .collecting : .upcoming)
        return MonthCollectionRow(
            kametiId: kametiId, monthIndex: month, monthStart: date(9 + month), isCurrent: month == current,
            target: Money(target), received: Money(received), covered: Money(covered), paidCount: paid, memberCount: members,
            payoutShortfall: .zero, paidOut: Money(isPast ? target : 0), recipients: 1, recipientsPaid: isPast ? 1 : 0,
            paidOutShortBy: .zero, state: state
        )
    }

    static let familyCollections: [MonthCollectionRow] = (1...6).map { month in
        switch month {
        case 1: collection("family", month: 1, target: 1_500_000, received: 1_500_000, covered: 1_500_000, paid: 6, members: 6, current: 2, n: 6)
        case 2: collection("family", month: 2, target: 1_500_000, received: 1_000_000, covered: 875_000, paid: 3, members: 6, current: 2, n: 6)
        default: collection("family", month: month, target: 1_500_000, received: 0, covered: 0, paid: 0, members: 6, current: 2, n: 6)
        }
    }
    static let officeCollections: [MonthCollectionRow] = (1...4).map { month in
        switch month {
        case 1: collection("office", month: 1, target: 400_000, received: 400_000, covered: 400_000, paid: 4, members: 4, current: 2, n: 4)
        case 2: collection("office", month: 2, target: 400_000, received: 200_000, covered: 200_000, paid: 2, members: 4, current: 2, n: 4)
        default: collection("office", month: month, target: 400_000, received: 0, covered: 0, paid: 0, members: 4, current: 2, n: 4)
        }
    }

    /// (member, paid, balance owed, month-2 status, month-2 allocated)
    private static let familyStanding: [(String, Int, Int, MonthStatusCode, Int)] = [
        ("f1", 500_000, 0, .paid, 250_000), ("f2", 500_000, 0, .paid, 250_000), ("f3", 625_000, -125_000, .advance, 250_000),
        ("f4", 250_000, 250_000, .unpaid, 0), ("f5", 375_000, 125_000, .partial, 125_000), ("f6", 250_000, 250_000, .unpaid, 0),
    ]
    static let familyBalances = familyStanding.map { id, paid, balance, _, _ in
        MemberBalanceRow(
            kametiId: "family", memberId: id, currentMonthIndex: 2, monthlyDue: Money(250_000), dueToDate: Money(500_000),
            totalPaid: Money(paid), balance: Money(balance), owes: Money(max(balance, 0)), credit: Money(max(-balance, 0))
        )
    }
    static let familyMonths: [MemberMonthRow] = familyStanding.flatMap { id, _, _, status, allocated in
        [
            MemberMonthRow(kametiId: "family", memberId: id, monthIndex: 1, monthStart: date(10), isCurrent: false, due: Money(250_000), allocated: Money(250_000), remaining: .zero, status: .paid),
            MemberMonthRow(kametiId: "family", memberId: id, monthIndex: 2, monthStart: date(11), isCurrent: true, due: Money(250_000), allocated: Money(allocated), remaining: Money(250_000 - allocated), status: status),
        ]
    }
    static let officeBalances = ["o1", "o2", "o3", "o4"].map { id in
        let owes = id == "o2" ? 100_000 : 0
        return MemberBalanceRow(
            kametiId: "office", memberId: id, currentMonthIndex: 2, monthlyDue: Money(100_000), dueToDate: Money(200_000),
            totalPaid: Money(200_000 - owes), balance: Money(owes), owes: Money(owes), credit: .zero
        )
    }

    static let officeMonths = [
        MemberMonthRow(kametiId: "office", memberId: "o2", monthIndex: 1, monthStart: date(10), isCurrent: false, due: Money(100_000), allocated: Money(100_000), remaining: .zero, status: .paid),
        MemberMonthRow(kametiId: "office", memberId: "o2", monthIndex: 2, monthStart: date(11), isCurrent: true, due: Money(100_000), allocated: .zero, remaining: Money(100_000), status: .unpaid),
    ]

    // MARK: Payments

    static func payment(_ id: String, _ kameti: String, _ member: String, _ amount: Int, month: Int, day: Int, method: PaymentMethod = .cash, reference: String? = nil) -> Payment {
        let received = DateOnly.make(year: month > 12 ? 2027 : 2026, month: month > 12 ? month - 12 : month, day: day)
        return Payment(
            id: id, kametiId: kameti, memberId: member, amount: Money(amount), receivedOn: received,
            method: method, createdAt: received.addingTimeInterval(3_600), reference: reference
        )
    }
    static let familyPayments: [Payment] =
        (1...6).map { payment("fp\($0)", "family", "f\($0)", 250_000, month: 10, day: 4 + $0, method: $0 == 3 ? .bankTransfer : .cash, reference: $0 == 3 ? "88213" : nil) }
        + [
            payment("fp7", "family", "f1", 250_000, month: 11, day: 3), payment("fp8", "family", "f2", 250_000, month: 11, day: 4),
            payment("fp9", "family", "f3", 375_000, month: 11, day: 6, method: .bankTransfer, reference: "88990"),
            payment("fp10", "family", "f5", 125_000, month: 11, day: 8),
        ]
    /// October fully paid; November short by Rs 1,00,000 (Zara and Mehwish owe).
    static let friendsPayments = [
        payment("frp1", "friends", "fr1", 400_000, month: 10, day: 3), payment("frp2", "friends", "fr2", 150_000, month: 10, day: 4),
        payment("frp3", "friends", "fr3", 300_000, month: 10, day: 4), payment("frp4", "friends", "fr4", 50_000, month: 10, day: 6),
        payment("frp5", "friends", "fr1", 400_000, month: 11, day: 2), payment("frp6", "friends", "fr3", 300_000, month: 11, day: 5),
        payment("frp7", "friends", "fr2", 100_000, month: 11, day: 7),
    ]

    static let officePayments = [
        payment("op1", "office", "o1", 100_000, month: 10, day: 2), payment("op2", "office", "o2", 100_000, month: 10, day: 3),
        payment("op3", "office", "o3", 100_000, month: 10, day: 3), payment("op4", "office", "o4", 100_000, month: 10, day: 4),
        payment("op5", "office", "o1", 100_000, month: 11, day: 2), payment("op6", "office", "o3", 100_000, month: 11, day: 4),
    ]

    /// Friends kameti 2025 (June–July 2025): both paid in full and both paid out.
    static let pastPayments: [Payment] = [(1, 6), (2, 6), (1, 7), (2, 7)].enumerated().map { index, item in
        let received = DateOnly.make(year: 2025, month: item.1, day: 5)
        return Payment(
            id: "pp\(index + 1)", kametiId: "past-2025", memberId: "p\(item.0)", amount: Money(100_000), receivedOn: received,
            method: .cash, createdAt: received.addingTimeInterval(3_600)
        )
    }

    /// `month` is counted from year 2026 (13 = January 2027).
    static func date(_ month: Int) -> Date {
        month > 12 ? DateOnly.make(year: 2027, month: month - 12) : DateOnly.make(year: 2026, month: month)
    }
}

/// The owner's people, shared by the contacts and kameti repositories so a
/// person added or edited in a kameti shows up in "From my people" too.
final class SampleContactStore: Sendable {
    private let state = Mutex((rows: SampleData.contacts, counter: 0))

    var all: [Contact] { state.withLock { $0.rows } }

    func contact(id: String?) -> Contact? {
        guard let id else { return nil }
        return state.withLock { $0.rows.first { $0.id == id } }
    }

    /// Like `add_member`: an email already in the list reuses that person.
    func findOrCreate(name: String, email: String?, phone: String?) -> Contact {
        state.withLock { s in
            if let email, let found = s.rows.first(where: { $0.email?.lowercased() == email }) { return found }
            s.counter += 1
            let created = Contact(id: "c-new-\(s.counter)", ownerId: SampleData.userId, name: name, email: email, phone: phone)
            s.rows.append(created)
            return created
        }
    }

    /// Like `update_member`: `nil` keeps a field, an empty string clears it.
    func update(id: String?, name: String, email: String?, phone: String?) -> Contact {
        state.withLock { s in
            let index = id.flatMap { id in s.rows.firstIndex { $0.id == id } }
            let old = index.map { s.rows[$0] }
            if old == nil { s.counter += 1 }
            let updated = Contact(
                id: old?.id ?? "c-new-\(s.counter)", ownerId: SampleData.userId, name: old?.name ?? name,
                email: email.map { $0.isEmpty ? nil : $0 } ?? old?.email,
                phone: phone.map { $0.isEmpty ? nil : $0 } ?? old?.phone, note: old?.note
            )
            if let index { s.rows[index] = updated } else { s.rows.append(updated) }
            return updated
        }
    }
}

struct SampleContactsRepository: ContactsRepository {
    let store: SampleContactStore
    func contacts() async throws(Failure) -> [Contact] { store.all }
}

private let notFound = Failure.server(code: "not_found", detail: nil)

/// An in-memory kameti store seeded with the sample kametis. It supports the
/// whole create flow (draft, members, slot splits, order, start), so the
/// wizard can be tried without a backend. Nothing is saved to disk.
final class SampleKametiRepository: KametiRepository {
    private struct State {
        var kametis = [SampleData.neighbours, SampleData.family, SampleData.friends, SampleData.office, SampleData.cousins, SampleData.past]
        var members = [
            "family": SampleData.familyMembers, "friends": SampleData.friendsMembers, "office": SampleData.officeMembers,
            "cousins": SampleData.cousinsMembers, "neighbours": SampleData.neighboursMembers, "past-2025": SampleData.pastMembers,
        ]
        var slots = [
            "family": SampleData.familySlots, "friends": SampleData.friendsSlots, "office": SampleData.officeSlots,
            "cousins": SampleData.cousinsSlots, "neighbours": SampleData.neighboursSlots, "past-2025": SampleData.pastSlots,
        ]
        var shares = [
            "family": SampleData.familyShares, "friends": SampleData.friendsShares, "office": SampleData.officeShares,
            "cousins": SampleData.cousinsShares, "neighbours": SampleData.neighboursShares, "past-2025": SampleData.pastShares,
        ]
        var counter = 0
        /// What each archived kameti was before, for restore.
        var archivedFrom: [String: KametiStatus] = [:]
    }

    private let state = Mutex(State())
    private let payments: SamplePaymentStore
    private let contacts: SampleContactStore
    private let log: SampleAuditLog

    init(payments: SamplePaymentStore, contacts: SampleContactStore, log: SampleAuditLog = SampleAuditLog()) {
        self.payments = payments
        self.contacts = contacts
        self.log = log
    }

    /// Like RLS: kametis I run, or where a member is linked to my account.
    func listKametis() async throws(Failure) -> [Kameti] {
        state.withLock { s in
            s.kametis.filter { k in
                k.ownerId == SampleData.userId || (s.members[k.id] ?? []).contains { $0.profileId == SampleData.userId }
            }
        }
    }

    // MARK: For the invites store

    func kametiRow(_ id: String) -> Kameti? { state.withLock { $0.kametis.first { $0.id == id } } }

    func memberRow(_ id: String) -> Member? { member(id) }

    func slotRow(_ id: String) -> Slot? { state.withLock { s in s.slots.values.lazy.flatMap { $0 }.first { $0.id == id } } }

    /// My own member row in a kameti, if I'm in it.
    func myMember(in kametiId: String) -> Member? {
        state.withLock { s in s.members[kametiId]?.first { $0.profileId == SampleData.userId } }
    }

    func shareRows(memberId: String, kametiId: String) -> [(share: Share, slot: Slot?)] {
        state.withLock { s in
            (s.shares[kametiId] ?? []).filter { $0.memberId == memberId }.map { share in
                (share, s.slots[kametiId]?.first { $0.id == share.slotId })
            }
        }
    }

    /// Replaces a member's join status and linked account.
    @discardableResult
    func setJoin(memberId: String, status: JoinStatus, profileId: String?) -> Member? {
        state.withLock { s in
            for key in s.members.keys {
                guard let index = s.members[key]?.firstIndex(where: { $0.id == memberId }), let old = s.members[key]?[index] else { continue }
                let new = Member(
                    id: old.id, kametiId: old.kametiId, name: old.name, joinStatus: status, contactId: old.contactId,
                    profileId: profileId, nickname: old.nickname, color: old.color
                )
                s.members[key]?[index] = new
                return new
            }
            return nil
        }
    }

    func kameti(id: String) async throws(Failure) -> Kameti {
        guard let found = state.withLock({ $0.kametis.first { $0.id == id } }) else { throw notFound }
        return found
    }
    func members(kametiId: String) async throws(Failure) -> [Member] { state.withLock { $0.members[kametiId] ?? [] } }
    func slots(kametiId: String) async throws(Failure) -> [Slot] { state.withLock { ($0.slots[kametiId] ?? []).sorted { $0.payoutMonthIndex < $1.payoutMonthIndex } } }
    func shares(kametiId: String) async throws(Failure) -> [Share] { state.withLock { $0.shares[kametiId] ?? [] } }

    func createKameti(_ new: NewKameti) async throws(Failure) -> Kameti {
        state.withLock { s in
            s.counter += 1
            let id = "draft-\(s.counter)"
            let created = Kameti(
                id: id, ownerId: SampleData.userId, name: new.name, description: new.description, startMonth: new.startMonth,
                monthsN: new.months, slotAmountC: new.slotAmount, dueDay: new.dueDay, reminderDays: new.reminderDays,
                maxSlotsPerMember: new.maxSlotsPerMember, status: .draft
            )
            s.kametis.insert(created, at: 0)
            s.members[id] = []
            s.shares[id] = []
            s.slots[id] = (1...new.months).map { Slot(id: "\(id)-s\($0)", kametiId: id, payoutMonthIndex: $0) }
            return created
        }
    }

    func updateKameti(id: String, changes: KametiChanges) async throws(Failure) -> Kameti {
        try state.withLock { s throws(Failure) in
            guard let index = s.kametis.firstIndex(where: { $0.id == id }) else { throw notFound }
            let old = s.kametis[index]
            // Like update_kameti_draft: drafts and running kametis only, and
            // once started the money shape is fixed (FR-34).
            guard [.draft, .active].contains(old.status) else { throw Failure.server(code: "kameti_not_editable", detail: nil) }
            let structural = (changes.startMonth.map { $0 != old.startMonth } ?? false)
                || (changes.months.map { $0 != old.monthsN } ?? false)
                || (changes.slotAmount.map { $0 != old.slotAmountC } ?? false)
                || (changes.maxSlotsPerMember.map { $0 != old.maxSlotsPerMember } ?? false)
            if structural, old.status != .draft { throw Failure.server(code: "kameti_not_draft", detail: nil) }
            if let name = changes.name {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard (3...40).contains(trimmed.count) else { throw Failure.server(code: "invalid_name", detail: nil) }
                if s.kametis.contains(where: { $0.id != id && $0.ownerId == old.ownerId && $0.name.lowercased() == trimmed.lowercased() && [.draft, .active].contains($0.status) }) {
                    throw Failure.server(code: "kameti_name_taken", detail: nil)
                }
            }
            let months = changes.months ?? old.monthsN
            let updated = Kameti(
                id: id, ownerId: old.ownerId, name: changes.name ?? old.name, description: changes.description ?? old.description,
                startMonth: changes.startMonth ?? old.startMonth, monthsN: months, slotAmountC: changes.slotAmount ?? old.slotAmountC,
                dueDay: changes.dueDay ?? old.dueDay, reminderDays: changes.reminderDays ?? old.reminderDays,
                maxSlotsPerMember: changes.maxSlotsPerMember ?? old.maxSlotsPerMember, status: old.status, startedAt: old.startedAt
            )
            s.kametis[index] = updated
            log.record(id, "kameti.update", entity: "kameti", entityId: id, member: nil,
                       before: SampleAuditLog.kameti(old), after: SampleAuditLog.kameti(updated))
            if old.status == .draft, months != (s.slots[id] ?? []).count {
                s.slots[id] = (1...months).map { Slot(id: "\(id)-s\($0)", kametiId: id, payoutMonthIndex: $0) }
                s.shares[id] = []
            }
            return updated
        }
    }

    func startKameti(id: String) async throws(Failure) -> Kameti {
        try state.withLock { s throws(Failure) in
            guard let index = s.kametis.firstIndex(where: { $0.id == id }) else { throw notFound }
            let old = s.kametis[index]
            let slots = s.slots[id] ?? []
            let shares = s.shares[id] ?? []
            let filled = slots.allSatisfy { slot in shares.contains { $0.slotId == slot.id } }
            guard filled, !slots.isEmpty else { throw Failure.server(code: "kameti_not_ready", detail: nil) }
            let started = Kameti(
                id: id, ownerId: old.ownerId, name: old.name, description: old.description, startMonth: old.startMonth,
                monthsN: old.monthsN, slotAmountC: old.slotAmountC, dueDay: old.dueDay, reminderDays: old.reminderDays,
                maxSlotsPerMember: old.maxSlotsPerMember, status: .active, startedAt: Date()
            )
            s.kametis[index] = started
            return started
        }
    }

    /// Mirrors `archive_kameti`: owner only, anything but an archived kameti.
    func archiveKameti(id: String) async throws(Failure) -> Kameti {
        try state.withLock { s throws(Failure) in
            guard let index = s.kametis.firstIndex(where: { $0.id == id }) else { throw notFound }
            let old = s.kametis[index]
            guard old.ownerId == SampleData.userId else { throw Failure.server(code: "not_kameti_owner", detail: nil) }
            guard old.status != .archived else { throw Failure.server(code: "kameti_already_archived", detail: nil) }
            s.archivedFrom[id] = old.status
            s.kametis[index] = Self.with(old, status: .archived)
            return s.kametis[index]
        }
    }

    /// Mirrors `restore_kameti`: back to what it was, if the name is still free.
    func restoreKameti(id: String) async throws(Failure) -> Kameti {
        try state.withLock { s throws(Failure) in
            guard let index = s.kametis.firstIndex(where: { $0.id == id }) else { throw notFound }
            let old = s.kametis[index]
            guard old.ownerId == SampleData.userId else { throw Failure.server(code: "not_kameti_owner", detail: nil) }
            guard old.status == .archived else { throw Failure.server(code: "kameti_not_archived", detail: nil) }
            let to = s.archivedFrom[id] ?? .completed
            if [.draft, .active].contains(to), s.kametis.contains(where: {
                $0.id != id && $0.ownerId == old.ownerId && $0.name.lowercased() == old.name.lowercased() && [.draft, .active].contains($0.status)
            }) {
                throw Failure.server(code: "kameti_name_taken", detail: nil)
            }
            s.archivedFrom[id] = nil
            s.kametis[index] = Self.with(old, status: to)
            return s.kametis[index]
        }
    }

    /// Mirrors `duplicate_kameti` (FR-13): settings, members, current shares and
    /// payout order; only my own member row stays linked; no payments.
    func duplicateKameti(id: String, name: String, startMonth: Date) async throws(Failure) -> Kameti {
        try state.withLock { s throws(Failure) in
            guard let old = s.kametis.first(where: { $0.id == id }) else { throw notFound }
            guard old.ownerId == SampleData.userId else { throw Failure.server(code: "not_kameti_owner", detail: nil) }
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            guard (3...40).contains(trimmed.count) else { throw Failure.server(code: "invalid_name", detail: nil) }
            if s.kametis.contains(where: { $0.ownerId == old.ownerId && $0.name.lowercased() == trimmed.lowercased() && [.draft, .active].contains($0.status) }) {
                throw Failure.server(code: "kameti_name_taken", detail: nil)
            }
            s.counter += 1
            let newId = "draft-\(s.counter)"
            let copy = Kameti(
                id: newId, ownerId: old.ownerId, name: trimmed, description: old.description, startMonth: startMonth,
                monthsN: old.monthsN, slotAmountC: old.slotAmountC, dueDay: old.dueDay, reminderDays: old.reminderDays,
                maxSlotsPerMember: old.maxSlotsPerMember, status: .draft
            )
            var memberIds: [String: String] = [:]
            s.members[newId] = (s.members[id] ?? []).enumerated().map { index, m in
                let mine = m.profileId == SampleData.userId
                memberIds[m.id] = "\(newId)-m\(index + 1)"
                return Member(
                    id: "\(newId)-m\(index + 1)", kametiId: newId, name: m.name, joinStatus: mine ? .joined : .notInvited,
                    contactId: m.contactId, profileId: mine ? m.profileId : nil, nickname: m.nickname, color: m.color
                )
            }
            var slotIds: [String: String] = [:]
            s.slots[newId] = (s.slots[id] ?? []).map { slot in
                slotIds[slot.id] = "\(newId)-s\(slot.payoutMonthIndex)"
                return Slot(id: "\(newId)-s\(slot.payoutMonthIndex)", kametiId: newId, payoutMonthIndex: slot.payoutMonthIndex, note: slot.note)
            }
            s.shares[newId] = (s.shares[id] ?? []).filter { $0.effectiveToMonth == nil }.enumerated().compactMap { index, share in
                guard let slot = slotIds[share.slotId], let member = memberIds[share.memberId] else { return nil }
                return Share(id: "\(newId)-h\(index + 1)", kametiId: newId, slotId: slot, memberId: member, monthlyAmount: share.monthlyAmount, effectiveFromMonth: 1)
            }
            s.kametis.insert(copy, at: 0)
            return copy
        }
    }

    private static func with(_ k: Kameti, status: KametiStatus) -> Kameti {
        Kameti(
            id: k.id, ownerId: k.ownerId, name: k.name, description: k.description, startMonth: k.startMonth,
            monthsN: k.monthsN, slotAmountC: k.slotAmountC, dueDay: k.dueDay, reminderDays: k.reminderDays,
            maxSlotsPerMember: k.maxSlotsPerMember, status: status, startedAt: k.startedAt
        )
    }

    /// Mirrors `add_member`: the kameti must be a draft or active, a name of
    /// 1–80 characters, and the same person can't be added twice.
    func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member {
        try requireEditable(kametiId)
        let contact: Contact?
        let name: String
        if new.isSelf {
            contact = nil
            name = "Demo Owner"
            if state.withLock({ ($0.members[kametiId] ?? []).contains { $0.profileId == SampleData.userId } }) {
                throw Failure.server(code: "already_member", detail: nil)
            }
        } else if let id = new.contactId {
            guard let found = contacts.contact(id: id) else { throw Failure.server(code: "contact_not_found", detail: nil) }
            contact = found
            name = trimmed(new.name) ?? found.name
        } else {
            guard let typed = trimmed(new.name) else { throw Failure.server(code: "invalid_name", detail: nil) }
            name = typed
            contact = contacts.findOrCreate(name: typed, email: trimmed(new.email)?.lowercased(), phone: trimmed(new.phone))
        }
        guard name.count <= 80 else { throw Failure.server(code: "invalid_name", detail: nil) }
        return try state.withLock { s throws(Failure) in
            if let contact, (s.members[kametiId] ?? []).contains(where: { $0.contactId == contact.id }) {
                throw Failure.server(code: "contact_already_member", detail: nil)
            }
            s.counter += 1
            let member = Member(
                id: "m-\(s.counter)", kametiId: kametiId, name: name, joinStatus: new.isSelf ? .joined : .notInvited,
                contactId: contact?.id, profileId: new.isSelf ? SampleData.userId : nil, nickname: trimmed(new.nickname)
            )
            s.members[kametiId, default: []].append(member)
            log.record(kametiId, "member.add", entity: "member", entityId: member.id, member: member.id, after: SampleAuditLog.member(member))
            return member
        }
    }

    /// Mirrors `update_member`: `nil` keeps a field, an empty string clears
    /// it; an email or phone goes on the member's contact (made if missing).
    func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member {
        guard let old = member(id) else { throw notFound }
        guard let kameti = state.withLock({ $0.kametis.first { $0.id == old.kametiId } }),
              [.draft, .active, .completed].contains(kameti.status) else { throw Failure.server(code: "kameti_not_editable", detail: nil) }
        if let name = changes.name {
            let count = name.trimmingCharacters(in: .whitespacesAndNewlines).count
            guard (1...80).contains(count) else { throw Failure.server(code: "invalid_name", detail: nil) }
        }
        let name = changes.name.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? old.name
        var contactId = old.contactId
        if changes.email != nil || changes.phone != nil {
            let email = changes.email.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let phone = changes.phone.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            contactId = contacts.update(id: old.contactId, name: name, email: email, phone: phone).id
        }
        let nickname = changes.nickname.map { trimmed($0) } ?? old.nickname
        let updated = Member(
            id: old.id, kametiId: old.kametiId, name: name, joinStatus: old.joinStatus, contactId: contactId,
            profileId: old.profileId, nickname: nickname, color: old.color
        )
        state.withLock { s in
            if let index = s.members[old.kametiId]?.firstIndex(where: { $0.id == id }) { s.members[old.kametiId]?[index] = updated }
        }
        log.record(old.kametiId, "member.update", entity: "member", entityId: id, member: id,
                   before: SampleAuditLog.member(old), after: SampleAuditLog.member(updated))
        return updated
    }

    /// Mirrors `remove_member`: once a kameti has started, someone who holds a
    /// share or has any payment or payout (voided ones too) stays on the ledger.
    func removeMember(id: String) async throws(Failure) {
        guard let old = member(id) else { throw notFound }
        try requireEditable(old.kametiId)
        let status = state.withLock { s in s.kametis.first { $0.id == old.kametiId }?.status }
        let holdsShares = state.withLock { s in (s.shares[old.kametiId] ?? []).contains { $0.memberId == id } }
        let hasMoney = payments.all(old.kametiId).contains { $0.memberId == id } || payments.payouts(old.kametiId).contains { $0.memberId == id }
        if status != .draft, holdsShares || hasMoney {
            throw Failure.server(code: "member_has_history", detail: nil)
        }
        state.withLock { s in
            s.members[old.kametiId]?.removeAll { $0.id == id }
            s.shares[old.kametiId]?.removeAll { $0.memberId == id }
        }
        log.record(old.kametiId, "member.remove", entity: "member", entityId: id, member: id, before: SampleAuditLog.member(old))
    }

    private func member(_ id: String) -> Member? {
        state.withLock { s in s.members.values.lazy.flatMap { $0 }.first { $0.id == id } }
    }

    private func requireEditable(_ kametiId: String) throws(Failure) {
        guard let kameti = state.withLock({ $0.kametis.first { $0.id == kametiId } }) else { throw notFound }
        guard [.draft, .active].contains(kameti.status) else { throw Failure.server(code: "kameti_not_editable", detail: nil) }
    }

    private func trimmed(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }

    func setSlotShares(slotId: String, shares: [ShareInput]) async throws(Failure) -> [Share] {
        try state.withLock { s throws(Failure) in
            guard let kametiId = s.slots.first(where: { $0.value.contains { $0.id == slotId } })?.key,
                  let kameti = s.kametis.first(where: { $0.id == kametiId }) else { throw notFound }
            let total = shares.reduce(Money.zero) { $0 + $1.monthlyAmount }
            guard shares.isEmpty || (total == kameti.slotAmountC && shares.count <= 4 && shares.allSatisfy { $0.monthlyAmount.rupees % 1_000 == 0 && $0.monthlyAmount.rupees >= 1_000 }) else {
                throw Failure.server(code: "invalid_shares", detail: nil)
            }
            s.shares[kametiId]?.removeAll { $0.slotId == slotId }
            let created = shares.enumerated().map {
                Share(id: "\(slotId)-h\($0.offset)", kametiId: kametiId, slotId: slotId, memberId: $0.element.memberId, monthlyAmount: $0.element.monthlyAmount, effectiveFromMonth: 1)
            }
            s.shares[kametiId, default: []].append(contentsOf: created)
            return created
        }
    }

    func reorderSlots(kametiId: String, slotIdsInOrder: [String]) async throws(Failure) -> [Slot] {
        state.withLock { s in
            let reordered = slotIdsInOrder.enumerated().map { Slot(id: $0.element, kametiId: kametiId, payoutMonthIndex: $0.offset + 1) }
            s.slots[kametiId] = reordered
            return reordered
        }
    }
}


/// The recorded payments of the sample kametis, shared by the ledger and the
/// payments repositories so a payment recorded in the demo shows up in the
/// balances, statuses and collections too.
final class SamplePaymentStore: Sendable {
    private let payments = Mutex([
        "family": SampleData.familyPayments, "friends": SampleData.friendsPayments, "office": SampleData.officePayments,
        "past-2025": SampleData.pastPayments,
    ])

    private let payouts = Mutex([String: [Payout]]())

    func all(_ kametiId: String) -> [Payment] { payments.withLock { $0[kametiId] ?? [] } }

    func payouts(_ kametiId: String) -> [Payout] { payouts.withLock { $0[kametiId] ?? [] } }

    func add(_ payout: Payout) { payouts.withLock { $0[payout.kametiId, default: []].append(payout) } }

    func voidPayout(id: String, reason: String) -> Payout? {
        payouts.withLock { state in
            for key in state.keys {
                guard let index = state[key]?.firstIndex(where: { $0.id == id }), let old = state[key]?[index] else { continue }
                let voided = Payout(
                    id: old.id, kametiId: old.kametiId, slotId: old.slotId, memberId: old.memberId, amount: old.amount, paidOn: old.paidOn,
                    method: old.method, reference: old.reference, note: old.note, voidedAt: Date(), voidReason: reason
                )
                state[key]?[index] = voided
                return voided
            }
            return nil
        }
    }

    func add(_ payment: Payment) { payments.withLock { $0[payment.kametiId, default: []].append(payment) } }

    func void(id: String, reason: String) -> Payment? {
        payments.withLock { state in
            for key in state.keys {
                guard let index = state[key]?.firstIndex(where: { $0.id == id }), let old = state[key]?[index] else { continue }
                let voided = Payment(
                    id: old.id, kametiId: old.kametiId, memberId: old.memberId, amount: old.amount, receivedOn: old.receivedOn,
                    method: old.method, createdAt: old.createdAt, reference: old.reference, note: old.note,
                    paidByName: old.paidByName, voidedAt: Date(), voidReason: reason
                )
                state[key]?[index] = voided
                return voided
            }
            return nil
        }
    }
}

/// A small stand-in for the backend's ledger views: oldest due first, so the
/// demo's balances and statuses follow the payments.
enum SampleLedger {
    struct Result {
        var balances: [MemberBalanceRow] = []
        var months: [MemberMonthRow] = []
        var collections: [MonthCollectionRow] = []
    }

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    static func compute(kameti: Kameti, members: [Member], shares: [Share], slots: [Slot], payments: [Payment], payouts: [Payout], current: Int, finished: Bool = false) -> Result {
        var result = Result()
        // A finished kameti has no current month: every month is in the past.
        func isBefore(_ month: Int) -> Bool { finished ? month <= current : month < current }
        func isNow(_ month: Int) -> Bool { !finished && month == current }
        let valid = payments.filter { $0.voidedAt == nil }
        func monthIndex(of date: Date) -> Int {
            let parts = calendar.dateComponents([.month], from: kameti.startMonth, to: date)
            return (parts.month ?? 0) + 1
        }
        func start(_ index: Int) -> Date { calendar.date(byAdding: .month, value: index - 1, to: kameti.startMonth) ?? kameti.startMonth }
        var allocatedByMonth: [Int: Int] = [:]
        var paidCountByMonth: [Int: Int] = [:]
        for member in members {
            let due = shares.filter { $0.memberId == member.id && $0.effectiveToMonth == nil }.reduce(0) { $0 + $1.monthlyAmount.rupees }
            guard due > 0 else { continue }
            let paid = valid.filter { $0.memberId == member.id }.reduce(0) { $0 + $1.amount.rupees }
            var left = paid
            for month in 1...max(current, 1) {
                let allocated = min(due, left)
                left -= allocated
                allocatedByMonth[month, default: 0] += allocated
                if allocated >= due { paidCountByMonth[month, default: 0] += 1 }
                let status: MonthStatusCode = allocated >= due
                    ? (left > 0 && month == current ? .advance : .paid)
                    : (allocated == 0 ? (month < current ? .overdue : .unpaid) : .partial)
                result.months.append(MemberMonthRow(
                    kametiId: kameti.id, memberId: member.id, monthIndex: month, monthStart: start(month), isCurrent: isNow(month),
                    due: Money(due), allocated: Money(allocated), remaining: Money(due - allocated), status: status
                ))
            }
            let dueToDate = due * current
            result.balances.append(MemberBalanceRow(
                kametiId: kameti.id, memberId: member.id, currentMonthIndex: current, monthlyDue: Money(due), dueToDate: Money(dueToDate),
                totalPaid: Money(paid), balance: Money(dueToDate - paid), owes: Money(max(dueToDate - paid, 0)), credit: Money(max(paid - dueToDate, 0))
            ))
        }
        let payers = members.filter { member in shares.contains { $0.memberId == member.id && $0.effectiveToMonth == nil } }.count
        let target = kameti.pot.rupees
        for month in 1...kameti.monthsN {
            let received = valid.filter { monthIndex(of: $0.receivedOn) == month }.reduce(0) { $0 + $1.amount.rupees }
            let slotIds = Set(slots.filter { $0.payoutMonthIndex == month }.map(\.id))
            let paidOut = payouts.filter { $0.voidedAt == nil && slotIds.contains($0.slotId) }.reduce(0) { $0 + $1.amount.rupees }
            var state: MonthCollectionState = isBefore(month) ? .paidOut : (isNow(month) ? (received >= target ? .fullyCollected : .collecting) : .upcoming)
            if paidOut > 0 { state = paidOut >= target ? .paidOut : .paidOutShort }
            result.collections.append(MonthCollectionRow(
                kametiId: kameti.id, monthIndex: month, monthStart: start(month), isCurrent: isNow(month), target: Money(target),
                received: Money(received), covered: Money(allocatedByMonth[month] ?? 0), paidCount: paidCountByMonth[month] ?? 0, memberCount: payers,
                payoutShortfall: Money(month <= current ? max(target - received, 0) : 0), paidOut: Money(paidOut > 0 ? paidOut : (isBefore(month) ? target : 0)),
                recipients: 1, recipientsPaid: isBefore(month) ? 1 : 0,
                paidOutShortBy: Money(paidOut > 0 ? max(target - paidOut, 0) : 0), state: state
            ))
        }
        return result
    }
}

struct SampleLedgerRepository: LedgerRepository {
    let store: SamplePaymentStore

    private func ledger(_ kametiId: String) -> SampleLedger.Result {
        switch kametiId {
        case "family":
            return SampleLedger.compute(kameti: SampleData.family, members: SampleData.familyMembers, shares: SampleData.familyShares, slots: SampleData.familySlots, payments: store.all("family"), payouts: store.payouts("family"), current: 2)
        case "friends":
            return SampleLedger.compute(kameti: SampleData.friends, members: SampleData.friendsMembers, shares: SampleData.friendsShares, slots: SampleData.friendsSlots, payments: store.all("friends"), payouts: store.payouts("friends"), current: 2)
        case "office":
            return SampleLedger.compute(kameti: SampleData.office, members: SampleData.officeMembers, shares: SampleData.officeShares, slots: SampleData.officeSlots, payments: store.all("office"), payouts: store.payouts("office"), current: 2)
        case "cousins":
            return SampleLedger.compute(kameti: SampleData.cousins, members: SampleData.cousinsMembers, shares: SampleData.cousinsShares, slots: SampleData.cousinsSlots, payments: store.all("cousins"), payouts: store.payouts("cousins"), current: 1)
        case "past-2025":
            return SampleLedger.compute(kameti: SampleData.past, members: SampleData.pastMembers, shares: SampleData.pastShares, slots: SampleData.pastSlots, payments: store.all("past-2025"), payouts: store.payouts("past-2025"), current: 2, finished: true)
        default:
            return SampleLedger.Result()
        }
    }

    func memberBalances(kametiId: String) async throws(Failure) -> [MemberBalanceRow] { ledger(kametiId).balances }
    func memberMonths(kametiId: String, memberId: String?) async throws(Failure) -> [MemberMonthRow] {
        ledger(kametiId).months.filter { memberId == nil || $0.memberId == memberId }
    }
    func monthCollections(kametiId: String) async throws(Failure) -> [MonthCollectionRow] { ledger(kametiId).collections }
}

struct SamplePaymentsRepository: PaymentsRepository {
    let store: SamplePaymentStore
    var log = SampleAuditLog()

    func payments(kametiId: String) async throws(Failure) -> [Payment] { store.all(kametiId) }
    func payouts(kametiId: String) async throws(Failure) -> [Payout] { store.payouts(kametiId) }

    func recordPayment(_ new: NewPayment) async throws(Failure) -> Payment {
        guard new.amount.isPositive else { throw Failure.server(code: "invalid_amount", detail: nil) }
        let kametiId = SampleData.familyMembers.contains { $0.id == new.memberId } ? "family" : (SampleData.friendsMembers.contains { $0.id == new.memberId } ? "friends" : "office")
        let payment = Payment(
            id: UUID().uuidString.lowercased(), kametiId: kametiId, memberId: new.memberId, amount: new.amount, receivedOn: new.receivedOn,
            method: new.method, createdAt: Date(), reference: new.reference, note: new.note, paidByName: new.paidByName
        )
        store.add(payment)
        log.record(kametiId, "payment.record", entity: "payment", entityId: payment.id, member: payment.memberId, after: SampleAuditLog.payment(payment))
        return payment
    }

    func recordPayments(kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod) async throws(Failure) -> [Payment] {
        var created: [Payment] = []
        for item in items {
            let payment = Payment(
                id: UUID().uuidString.lowercased(), kametiId: kametiId, memberId: item.memberId, amount: item.amount, receivedOn: receivedOn,
                method: method, createdAt: Date()
            )
            store.add(payment)
            log.record(kametiId, "payment.record", entity: "payment", entityId: payment.id, member: payment.memberId, after: SampleAuditLog.payment(payment))
            created.append(payment)
        }
        return created
    }

    func voidPayment(id: String, reason: String) async throws(Failure) -> Payment {
        guard let voided = store.void(id: id, reason: reason) else { throw notFound }
        log.record(voided.kametiId, "payment.void", entity: "payment", entityId: id, member: voided.memberId, after: SampleAuditLog.payment(voided))
        return voided
    }

    func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout {
        guard new.amount.isPositive else { throw Failure.server(code: "invalid_amount", detail: nil) }
        let payout = Payout(
            id: UUID().uuidString.lowercased(), kametiId: new.slotId.hasPrefix("fs") ? "family" : (new.slotId.hasPrefix("frs") ? "friends" : "office"), slotId: new.slotId,
            memberId: new.memberId, amount: new.amount, paidOn: new.paidOn, method: new.method, reference: new.reference, note: new.note
        )
        store.add(payout)
        log.record(payout.kametiId, "payout.record", entity: "payout", entityId: payout.id, member: payout.memberId, after: SampleAuditLog.payout(payout))
        return payout
    }

    func voidPayout(id: String, reason: String) async throws(Failure) -> Payout {
        guard let voided = store.voidPayout(id: id, reason: reason) else { throw notFound }
        log.record(voided.kametiId, "payout.void", entity: "payout", entityId: id, member: voided.memberId, after: SampleAuditLog.payout(voided))
        return voided
    }
}
