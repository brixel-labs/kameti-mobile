import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// Archive and restore (§6.11) against the demo store, which follows the
/// backend's `archive_kameti` / `restore_kameti` rules.
@MainActor
@Suite("Archive kameti")
struct ArchiveKametiTests {
    private func loaded(_ id: String = "family") async -> (KametiDetailViewModel, KametiDependencies, () -> Kameti?) {
        let dependencies = SampleData.dependencies()
        let model = KametiDetailViewModel(kametiId: id, userId: SampleData.userId, dependencies: dependencies)
        await model.load()
        return (model, dependencies, {
            if case .loaded(let data) = model.state { return data.kameti }
            return nil
        })
    }

    @Test func archiveThenRestoreReturnsToActive() async throws {
        let (model, _, kameti) = await loaded()
        #expect(kameti()?.status == .active)

        #expect(await model.archive() == nil)
        #expect(kameti()?.status == .archived)

        #expect(await model.restore() == nil)
        #expect(kameti()?.status == .active)
    }

    @Test func archivingTwiceFails() async throws {
        let (model, _, _) = await loaded()
        #expect(await model.archive() == nil)
        #expect(await model.archive() == .server(code: "kameti_already_archived", detail: nil))
    }

    @Test func restoringNeedsAnArchivedKameti() async throws {
        let (model, _, _) = await loaded()
        #expect(await model.restore() == .server(code: "kameti_not_archived", detail: nil))
    }

    @Test func archivedKametisStillListForPast() async throws {
        let (model, dependencies, _) = await loaded()
        _ = await model.archive()
        let listed = try await dependencies.kametis.listKametis()
        #expect(listed.first { $0.id == "family" }?.status == .archived)
    }

    @Test func archivingUnblocksAccountDeletion() async throws {
        let (_, dependencies, _) = await loaded()
        let before = try await dependencies.account.deletionCheck()
        #expect(!before.canDelete)
        for ref in before.blockingKametis {
            _ = try await dependencies.kametis.archiveKameti(id: ref.id)
        }
        #expect(try await dependencies.account.deletionCheck().canDelete)
    }

    @Test func nameTakenMessageExplainsTheFix() {
        let message = KametiDetailView.message(for: .server(code: "kameti_name_taken", detail: nil))
        #expect(message.contains("Rename"))
    }
}

/// A kameti whose months are all over shows totals, not "Not started yet".
@MainActor
@Suite("Finished overview")
struct FinishedOverviewTests {
    @Test func finishedKametiHasASummary() async throws {
        let model = KametiDetailViewModel(kametiId: "past-2025", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        guard case .loaded(let data) = model.state else { Issue.record("not loaded"); return }
        #expect(data.current == nil)
        let summary = try #require(DetailLogic.finalSummary(data))
        #expect(summary.months == data.kameti.monthsN)
        #expect(summary.collected.isPositive)
    }

    @Test func runningKametiHasNone() async throws {
        let model = KametiDetailViewModel(kametiId: "family", userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        guard case .loaded(let data) = model.state else { Issue.record("not loaded"); return }
        #expect(DetailLogic.finalSummary(data) == nil)
    }
}

/// Duplicating a kameti as a new draft (FR-13) against the demo store.
@MainActor
@Suite("Duplicate kameti")
struct DuplicateKametiTests {
    @Test func copiesMembersAndSharesButNoPayments() async throws {
        let dependencies = SampleData.dependencies()
        let model = KametiDetailViewModel(kametiId: "family", userId: SampleData.userId, dependencies: dependencies)
        await model.load()
        guard case .loaded(let source) = model.state else { Issue.record("not loaded"); return }

        let id = try await model.duplicate().get()
        let copy = try await dependencies.kametis.kameti(id: id)
        #expect(copy.status == .draft)
        #expect(copy.name == "Family kameti (copy)")
        #expect(copy.monthsN == source.kameti.monthsN && copy.slotAmountC == source.kameti.slotAmountC)
        #expect(copy.startMonth == DuplicateLogic.startMonth(after: source.kameti, currentMonth: dependencies.clock.currentMonth()))

        let members = try await dependencies.kametis.members(kametiId: id)
        #expect(members.map(\.name) == source.members.map(\.name))
        #expect(members.allSatisfy { $0.profileId == nil || $0.profileId == SampleData.userId })
        let shares = try await dependencies.kametis.shares(kametiId: id)
        #expect(shares.count == source.shares.filter { $0.effectiveToMonth == nil }.count)
        #expect(try await dependencies.payments.payments(kametiId: id).isEmpty)

        // A second copy gets the next free name.
        let second = try await model.duplicate().get()
        #expect(try await dependencies.kametis.kameti(id: second).name == "Family kameti (copy 2)")
    }

    @Test func namesStayWithinTheLimit() {
        let long = String(repeating: "a", count: 40)
        #expect(DuplicateLogic.name(for: long, attempt: 1).count <= 40)
        #expect(DuplicateLogic.name(for: long, attempt: 3).hasSuffix("(copy 3)"))
    }
}
