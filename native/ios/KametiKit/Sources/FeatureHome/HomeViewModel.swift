import KametiCore
import KametiDomain
import Observation

/// One kameti on Home with the parts that load separately. A part that fails
/// to load stays `nil`; the card still opens the kameti.
public struct HomeKametiSummary: Identifiable, Equatable, Sendable {
    public let kameti: Kameti
    public let isOwner: Bool
    /// This month's collection (live kametis only).
    public var currentMonth: MonthCollectionRow?
    /// What I owe so far (member view only).
    public var owes: Money?

    public var id: String { kameti.id }
}

/// Home's three groups (FR-1 to FR-3).
public struct HomeSections: Equatable, Sendable {
    public var mine: [HomeKametiSummary] = []
    public var joined: [HomeKametiSummary] = []
    public var past: [HomeKametiSummary] = []

    public var isEmpty: Bool { mine.isEmpty && joined.isEmpty && past.isEmpty }
}

@MainActor
@Observable
public final class HomeViewModel {
    public private(set) var sections = HomeSections()
    public private(set) var failure: Failure?
    public private(set) var isLoading = false
    public private(set) var hasLoaded = false

    private let userId: String
    private let dependencies: KametiDependencies

    public init(userId: String, dependencies: KametiDependencies) {
        self.userId = userId
        self.dependencies = dependencies
    }

    /// Past kametis are completed, archived or cancelled.
    nonisolated static func isPast(_ status: KametiStatus) -> Bool {
        switch status {
        case .completed, .archived, .cancelled: true
        case .draft, .active: false
        }
    }

    /// Groups kametis: mine (owner), joined (member), past. Order is kept.
    nonisolated static func sections(of summaries: [HomeKametiSummary]) -> HomeSections {
        var result = HomeSections()
        for item in summaries {
            if isPast(item.kameti.status) {
                result.past.append(item)
            } else if item.isOwner {
                result.mine.append(item)
            } else {
                result.joined.append(item)
            }
        }
        return result
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        failure = nil
        defer { isLoading = false; hasLoaded = true }
        do throws(Failure) {
            let all = try await dependencies.kametis.listKametis()
            var summaries = all.map {
                HomeKametiSummary(kameti: $0, isOwner: $0.isOwned(by: userId))
            }
            // Show the list right away, then fill in each card.
            sections = Self.sections(of: summaries)
            for index in summaries.indices where !Self.isPast(summaries[index].kameti.status) {
                summaries[index] = await detail(for: summaries[index])
            }
            sections = Self.sections(of: summaries)
        } catch {
            failure = error
        }
    }

    private func detail(for item: HomeKametiSummary) async -> HomeKametiSummary {
        var item = item
        let id = item.kameti.id
        if let months = try? await dependencies.ledger.monthCollections(kametiId: id) {
            item.currentMonth = months.first(where: \.isCurrent)
        }
        if !item.isOwner,
           let members = try? await dependencies.kametis.members(kametiId: id),
           let me = members.first(where: { $0.profileId == userId }),
           let balances = try? await dependencies.ledger.memberBalances(kametiId: id) {
            item.owes = balances.first(where: { $0.memberId == me.id })?.owes
        }
        return item
    }
}
