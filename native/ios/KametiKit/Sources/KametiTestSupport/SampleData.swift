import Foundation
import KametiCore
import KametiDomain

/// Believable sample kametis, so every screen can be seen without a backend
/// (the "demo" flavor, previews). Two kametis: one I run, one I'm a member of.
public enum SampleData {
    public static let userId = "demo-user"

    public static func dependencies() -> KametiDependencies {
        KametiDependencies(
            kametis: SampleKametiRepository(), ledger: SampleLedgerRepository(), payments: SamplePaymentsRepository(),
            invites: UnusedRepositories(), audit: UnusedRepositories(),
            profiles: FakeProfileRepository(.success(Profile(id: userId, displayName: "Demo Owner"))),
            contacts: UnusedRepositories(), auth: FakeAuthRepository(userId: userId)
        )
    }

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
    static let familyShares = (1...6).map {
        Share(id: "fh\($0)", kametiId: "family", slotId: "fs\($0)", memberId: "f\($0)", monthlyAmount: Money(250_000), effectiveFromMonth: 1)
    }

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

private let notFound = Failure.server(code: "not_found", detail: nil)

struct SampleKametiRepository: KametiRepository {
    func listKametis() async throws(Failure) -> [Kameti] { [SampleData.family, SampleData.office] }
    func kameti(id: String) async throws(Failure) -> Kameti {
        guard let found = [SampleData.family, SampleData.office].first(where: { $0.id == id }) else { throw notFound }
        return found
    }
    func members(kametiId: String) async throws(Failure) -> [Member] { kametiId == "family" ? SampleData.familyMembers : SampleData.officeMembers }
    func slots(kametiId: String) async throws(Failure) -> [Slot] { kametiId == "family" ? SampleData.familySlots : SampleData.officeSlots }
    func shares(kametiId: String) async throws(Failure) -> [Share] { kametiId == "family" ? SampleData.familyShares : SampleData.officeShares }
    func createKameti(_ new: NewKameti) async throws(Failure) -> Kameti { throw readOnly }
    func updateKameti(id: String, changes: KametiChanges) async throws(Failure) -> Kameti { throw readOnly }
    func startKameti(id: String) async throws(Failure) -> Kameti { throw readOnly }
    func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member { throw readOnly }
    func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member { throw readOnly }
    func removeMember(id: String) async throws(Failure) { throw readOnly }
    func setSlotShares(slotId: String, shares: [ShareInput]) async throws(Failure) -> [Share] { throw readOnly }
    func reorderSlots(kametiId: String, slotIdsInOrder: [String]) async throws(Failure) -> [Slot] { throw readOnly }
}

private let readOnly = Failure.unknown(description: "sample data is read only")

struct SampleLedgerRepository: LedgerRepository {
    func memberBalances(kametiId: String) async throws(Failure) -> [MemberBalanceRow] {
        kametiId == "family" ? SampleData.familyBalances : SampleData.officeBalances
    }
    func memberMonths(kametiId: String, memberId: String?) async throws(Failure) -> [MemberMonthRow] {
        kametiId == "family" ? SampleData.familyMonths : []
    }
    func monthCollections(kametiId: String) async throws(Failure) -> [MonthCollectionRow] {
        kametiId == "family" ? SampleData.familyCollections : SampleData.officeCollections
    }
}

struct SamplePaymentsRepository: PaymentsRepository {
    func payments(kametiId: String) async throws(Failure) -> [Payment] {
        kametiId == "family" ? SampleData.familyPayments : SampleData.officePayments
    }
    func payouts(kametiId: String) async throws(Failure) -> [Payout] { [] }
    func recordPayment(_ new: NewPayment) async throws(Failure) -> Payment { throw readOnly }
    func recordPayments(kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod) async throws(Failure) -> [Payment] { throw readOnly }
    func voidPayment(id: String, reason: String) async throws(Failure) -> Payment { throw readOnly }
    func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout { throw readOnly }
    func voidPayout(id: String, reason: String) async throws(Failure) -> Payout { throw readOnly }
}
