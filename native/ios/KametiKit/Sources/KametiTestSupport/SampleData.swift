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
        return KametiDependencies(
            kametis: SampleKametiRepository(), ledger: SampleLedgerRepository(store: store), payments: SamplePaymentsRepository(store: store),
            invites: UnusedRepositories(), audit: UnusedRepositories(),
            profiles: FakeProfileRepository(.success(Profile(id: userId, displayName: "Demo Owner"))),
            contacts: SampleContactsRepository(), auth: FakeAuthRepository(userId: userId),
            // The sample data is set in November 2026, so "today" is fixed there
            // whatever the phone's date is.
            clock: KametiClock(nowUTC: { DateOnly.make(year: 2026, month: 11, day: 10).addingTimeInterval(8 * 3600) })
        )
    }

    public static let contacts = [
        Contact(id: "c1", ownerId: userId, name: "Ali Raza", email: "ali.raza@gmail.com"),
        Contact(id: "c2", ownerId: userId, name: "Sara Khan", email: "sara.k@outlook.com"),
        Contact(id: "c3", ownerId: userId, name: "Hira Shah"),
        Contact(id: "c4", ownerId: userId, name: "Omar Farooq", email: "omar.f@gmail.com"),
        Contact(id: "c5", ownerId: userId, name: "Zainab Tariq", email: "zainab.t@gmail.com"),
    ]

    // MARK: Family kameti (I run it)

    static let family = Kameti(
        id: "family", ownerId: userId, name: "Family kameti", startMonth: date(10), monthsN: 6,
        slotAmountC: Money(250_000), dueDay: 10, reminderDays: [1, 3], maxSlotsPerMember: 4, status: .active
    )
    static let familyNames = ["Ali Raza", "Sara Khan", "Naveed Ahmed", "Osama Sheikh", "Hira Malik", "Faisal Iqbal"]
    static let familyMembers = familyNames.enumerated().map {
        Member(id: "f\($0.offset + 1)", kametiId: "family", name: $0.element, joinStatus: $0.offset == 5 ? .invited : .joined)
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

    /// `month` is counted from year 2026 (13 = January 2027).
    static func date(_ month: Int) -> Date {
        month > 12 ? DateOnly.make(year: 2027, month: month - 12) : DateOnly.make(year: 2026, month: month)
    }
}

struct SampleContactsRepository: ContactsRepository {
    func contacts() async throws(Failure) -> [Contact] { SampleData.contacts }
}

private let notFound = Failure.server(code: "not_found", detail: nil)

/// An in-memory kameti store seeded with the sample kametis. It supports the
/// whole create flow (draft, members, slot splits, order, start), so the
/// wizard can be tried without a backend. Nothing is saved to disk.
final class SampleKametiRepository: KametiRepository {
    private struct State {
        var kametis = [SampleData.family, SampleData.friends, SampleData.office]
        var members = ["family": SampleData.familyMembers, "friends": SampleData.friendsMembers, "office": SampleData.officeMembers]
        var slots = ["family": SampleData.familySlots, "friends": SampleData.friendsSlots, "office": SampleData.officeSlots]
        var shares = ["family": SampleData.familyShares, "friends": SampleData.friendsShares, "office": SampleData.officeShares]
        var counter = 0
    }

    private let state = Mutex(State())

    func listKametis() async throws(Failure) -> [Kameti] { state.withLock { $0.kametis } }

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
            let months = changes.months ?? old.monthsN
            let updated = Kameti(
                id: id, ownerId: old.ownerId, name: changes.name ?? old.name, description: changes.description ?? old.description,
                startMonth: changes.startMonth ?? old.startMonth, monthsN: months, slotAmountC: changes.slotAmount ?? old.slotAmountC,
                dueDay: changes.dueDay ?? old.dueDay, reminderDays: changes.reminderDays ?? old.reminderDays,
                maxSlotsPerMember: changes.maxSlotsPerMember ?? old.maxSlotsPerMember, status: old.status, startedAt: old.startedAt
            )
            s.kametis[index] = updated
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

    func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member {
        state.withLock { s in
            s.counter += 1
            let contact = new.contactId.flatMap { id in SampleData.contacts.first { $0.id == id } }
            let member = Member(
                id: "m-\(s.counter)", kametiId: kametiId, name: new.isSelf ? "Demo Owner" : (contact?.name ?? new.name ?? "Member"),
                joinStatus: new.isSelf ? .joined : .notInvited, contactId: new.contactId, profileId: new.isSelf ? SampleData.userId : nil
            )
            s.members[kametiId, default: []].append(member)
            return member
        }
    }

    func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member { throw readOnly }

    func removeMember(id: String) async throws(Failure) {
        state.withLock { s in
            for key in s.members.keys {
                s.members[key]?.removeAll { $0.id == id }
                s.shares[key]?.removeAll { $0.memberId == id }
            }
        }
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

private let readOnly = Failure.unknown(description: "sample data is read only")

/// The recorded payments of the sample kametis, shared by the ledger and the
/// payments repositories so a payment recorded in the demo shows up in the
/// balances, statuses and collections too.
final class SamplePaymentStore: Sendable {
    private let payments = Mutex([
        "family": SampleData.familyPayments, "friends": SampleData.friendsPayments, "office": SampleData.officePayments,
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

    static func compute(kameti: Kameti, members: [Member], shares: [Share], slots: [Slot], payments: [Payment], payouts: [Payout], current: Int) -> Result {
        var result = Result()
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
                    kametiId: kameti.id, memberId: member.id, monthIndex: month, monthStart: start(month), isCurrent: month == current,
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
            var state: MonthCollectionState = month < current ? .paidOut : (month == current ? (received >= target ? .fullyCollected : .collecting) : .upcoming)
            if paidOut > 0 { state = paidOut >= target ? .paidOut : .paidOutShort }
            result.collections.append(MonthCollectionRow(
                kametiId: kameti.id, monthIndex: month, monthStart: start(month), isCurrent: month == current, target: Money(target),
                received: Money(received), covered: Money(allocatedByMonth[month] ?? 0), paidCount: paidCountByMonth[month] ?? 0, memberCount: payers,
                payoutShortfall: Money(month <= current ? max(target - received, 0) : 0), paidOut: Money(paidOut > 0 ? paidOut : (month < current ? target : 0)),
                recipients: 1, recipientsPaid: month < current ? 1 : 0,
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
            created.append(payment)
        }
        return created
    }

    func voidPayment(id: String, reason: String) async throws(Failure) -> Payment {
        guard let voided = store.void(id: id, reason: reason) else { throw notFound }
        return voided
    }

    func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout {
        guard new.amount.isPositive else { throw Failure.server(code: "invalid_amount", detail: nil) }
        let payout = Payout(
            id: UUID().uuidString.lowercased(), kametiId: new.slotId.hasPrefix("fs") ? "family" : (new.slotId.hasPrefix("frs") ? "friends" : "office"), slotId: new.slotId,
            memberId: new.memberId, amount: new.amount, paidOn: new.paidOn, method: new.method, reference: new.reference, note: new.note
        )
        store.add(payout)
        return payout
    }

    func voidPayout(id: String, reason: String) async throws(Failure) -> Payout {
        guard let voided = store.voidPayout(id: id, reason: reason) else { throw notFound }
        return voided
    }
}
