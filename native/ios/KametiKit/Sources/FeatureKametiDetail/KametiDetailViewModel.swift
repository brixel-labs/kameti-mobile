import Foundation
import KametiCore
import KametiDomain
import Observation

/// Everything the detail screens show, loaded together.
public struct KametiDetailData: Equatable, Sendable {
    public let kameti: Kameti
    public let userId: String
    public let members: [Member]
    public let slots: [Slot]
    public let shares: [Share]
    public let collections: [MonthCollectionRow]
    public let balances: [MemberBalanceRow]
    /// Every member's month statuses. Owner only: empty for a member.
    public let months: [MemberMonthRow]
    public let payments: [Payment]
    public let payouts: [Payout]
    /// Today in Pakistan (date-only), for "Today" labels.
    public let today: Date

    public var isOwner: Bool { kameti.isOwned(by: userId) }
    public var me: Member? { DetailLogic.myMember(in: members, userId: userId) }
    public var current: MonthCollectionRow? { DetailLogic.currentCollection(collections) }
}

@MainActor
@Observable
public final class KametiDetailViewModel {
    public enum State: Equatable, Sendable {
        case loading
        case loaded(KametiDetailData)
        case failed(Failure)
    }

    public private(set) var state = State.loading
    public private(set) var isRefreshing = false

    private let kametiId: String
    private let userId: String
    private let dependencies: KametiDependencies

    public init(kametiId: String, userId: String, dependencies: KametiDependencies) {
        self.kametiId = kametiId
        self.userId = userId
        self.dependencies = dependencies
    }

    public func load() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do throws(Failure) {
            // Sequential: `async let` would drop the typed error.
            let kameti = try await dependencies.kametis.kameti(id: kametiId)
            let owner = kameti.isOwned(by: userId)
            let members = try await dependencies.kametis.members(kametiId: kametiId)
            let slots = try await dependencies.kametis.slots(kametiId: kametiId)
            let shares = try await dependencies.kametis.shares(kametiId: kametiId)
            let collections = try await dependencies.ledger.monthCollections(kametiId: kametiId)
            let balances = try await dependencies.ledger.memberBalances(kametiId: kametiId)
            // Owners see every member's months; a member only their own.
            let mine = DetailLogic.myMember(in: members, userId: userId)
            let months = owner
                ? try await dependencies.ledger.memberMonths(kametiId: kametiId, memberId: nil)
                : (mine == nil ? [] : try await dependencies.ledger.memberMonths(kametiId: kametiId, memberId: mine?.id))
            let payments = try await dependencies.payments.payments(kametiId: kametiId)
            let payouts = (try? await dependencies.payments.payouts(kametiId: kametiId)) ?? []
            state = .loaded(KametiDetailData(
                kameti: kameti, userId: userId, members: members, slots: slots, shares: shares,
                collections: collections, balances: balances, months: months, payments: payments,
                payouts: payouts, today: DetailLogic.pakistanToday(dependencies.clock.now())
            ))
        } catch {
            // Keep what is on screen if a refresh fails.
            if case .loaded = state { return }
            state = .failed(error)
        }
    }
}
