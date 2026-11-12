import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

private func kameti(owner: String) -> Kameti {
    Kameti(
        id: "k", ownerId: owner, name: "K", startMonth: DateOnly.make(year: 2026, month: 11), monthsN: 2,
        slotAmountC: Money(100_000), dueDay: 10, reminderDays: [], maxSlotsPerMember: 4, status: .active
    )
}

@MainActor
private func dependencies(owner: String, ledger: StubLedgerRepository) -> KametiDependencies {
    KametiDependencies(
        kametis: StubKametiRepository(
            [kameti(owner: owner)], members: [Member(id: "m", kametiId: "k", name: "M", joinStatus: .joined, profileId: "me")]
        ),
        ledger: ledger, payments: StubPaymentsRepository(), invites: UnusedRepositories(), audit: UnusedRepositories(),
        profiles: FakeProfileRepository(), contacts: UnusedRepositories(), auth: FakeAuthRepository(userId: "me")
    )
}

@MainActor
@Suite("KametiDetailViewModel")
struct KametiDetailViewModelTests {
    @Test func ownerLoadsEveryMembersMonths() async {
        let month = MemberMonthRow(
            kametiId: "k", memberId: "m", monthIndex: 1, monthStart: DateOnly.make(year: 2026, month: 11),
            isCurrent: true, due: Money(1), allocated: .zero, remaining: Money(1), status: .unpaid
        )
        let model = KametiDetailViewModel(kametiId: "k", userId: "me", dependencies: dependencies(owner: "me", ledger: StubLedgerRepository(months: [month])))
        await model.load()
        guard case .loaded(let data) = model.state else { Issue.record("not loaded"); return }
        #expect(data.isOwner)
        #expect(data.months.count == 1)
        #expect(data.me?.id == "m")
    }

    @Test func aMemberLoadsOnlyTheirOwnMonths() async {
        func row(_ member: String) -> MemberMonthRow {
            MemberMonthRow(
                kametiId: "k", memberId: member, monthIndex: 1, monthStart: DateOnly.make(year: 2026, month: 11),
                isCurrent: true, due: Money(1), allocated: .zero, remaining: Money(1), status: .unpaid
            )
        }
        let model = KametiDetailViewModel(
            kametiId: "k", userId: "me", dependencies: dependencies(owner: "other", ledger: StubLedgerRepository(months: [row("x"), row("m")]))
        )
        await model.load()
        guard case .loaded(let data) = model.state else { Issue.record("not loaded"); return }
        #expect(!data.isOwner)
        #expect(data.months.map(\.memberId) == ["m"])
    }

    @Test func aFailureShowsAsFailedState() async {
        let model = KametiDetailViewModel(
            kametiId: "k", userId: "me", dependencies: dependencies(owner: "me", ledger: StubLedgerRepository(failure: .network))
        )
        await model.load()
        #expect(model.state == .failed(.network))
    }
}
