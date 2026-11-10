import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureHome

private func kameti(_ id: String, owner: String, status: KametiStatus = .active) -> Kameti {
    Kameti(
        id: id, ownerId: owner, name: id, startMonth: DateOnly.make(year: 2026, month: 10), monthsN: 4,
        slotAmountC: Money(100_000), dueDay: 10, reminderDays: [1], maxSlotsPerMember: 4, status: status
    )
}

private func summary(_ id: String, owner: Bool, status: KametiStatus = .active) -> HomeKametiSummary {
    HomeKametiSummary(kameti: kameti(id, owner: owner ? "me" : "other", status: status), isOwner: owner)
}

@MainActor
private func dependencies(kametis: [Kameti]) -> KametiDependencies {
    KametiDependencies(
        kametis: StubKametiRepository(kametis), ledger: UnusedRepositories(), payments: UnusedRepositories(),
        invites: UnusedRepositories(), audit: UnusedRepositories(), profiles: FakeProfileRepository(),
        contacts: UnusedRepositories(), auth: FakeAuthRepository(userId: "me")
    )
}

@Suite("HomeViewModel grouping")
struct HomeGroupingTests {
    @Test func splitsMineJoinedAndPastKeepingOrder() {
        let result = HomeViewModel.sections(of: [
            summary("a", owner: true), summary("b", owner: false), summary("c", owner: true),
            summary("old", owner: true, status: .completed), summary("gone", owner: false, status: .cancelled),
        ])
        #expect(result.mine.map(\.id) == ["a", "c"])
        #expect(result.joined.map(\.id) == ["b"])
        #expect(result.past.map(\.id) == ["old", "gone"])
    }

    @Test func draftCountsAsLive() {
        let result = HomeViewModel.sections(of: [summary("d", owner: true, status: .draft)])
        #expect(result.mine.count == 1)
        #expect(result.past.isEmpty)
    }

    @Test func archivedIsPast() {
        #expect(HomeViewModel.isPast(.archived))
        #expect(!HomeViewModel.isPast(.active))
    }

    @Test func emptyWhenNothing() {
        #expect(HomeViewModel.sections(of: []).isEmpty)
    }
}

@MainActor
@Suite("HomeViewModel loading")
struct HomeLoadingTests {
    @Test func loadsAndGroupsEvenWhenCardDetailsFail() async {
        // Ledger and members are "not stubbed": cards load without their detail.
        let model = HomeViewModel(
            userId: "me", dependencies: dependencies(kametis: [kameti("a", owner: "me"), kameti("b", owner: "x"), kameti("z", owner: "me", status: .completed)])
        )
        await model.load()
        #expect(model.hasLoaded)
        #expect(model.failure == nil)
        #expect(model.sections.mine.map(\.id) == ["a"])
        #expect(model.sections.joined.map(\.id) == ["b"])
        #expect(model.sections.past.map(\.id) == ["z"])
        #expect(model.sections.mine.first?.currentMonth == nil)
    }

    @Test func noKametisIsEmptyNotFailed() async {
        let model = HomeViewModel(userId: "me", dependencies: dependencies(kametis: []))
        await model.load()
        #expect(model.sections.isEmpty)
        #expect(model.failure == nil)
    }
}
