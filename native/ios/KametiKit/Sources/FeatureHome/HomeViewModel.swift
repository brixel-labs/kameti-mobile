import KametiCore
import FeatureKametiDetail
import Foundation
import KametiDomain
import KametiUI
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
    /// When this month's payment is due.
    public var dueDate: Date?
    /// Who receives the pot this month.
    public var recipients: [Person] = []
    /// My next payout (member view).
    public var nextTurn: NextTurn?
    /// When this month's payout was made (the latest payout of its slot).
    public var payoutDate: Date?

    public struct Person: Equatable, Sendable {
        public let name: String
        public let colorIndex: Int
    }

    public struct NextTurn: Equatable, Sendable {
        public let month: Date
        public let payout: Money
    }

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
    /// The signed-in user's first name, for the title.
    public private(set) var firstName: String?
    /// Live invitations addressed to my email (board AI-1b).
    public private(set) var invitations: [MyInvitation] = []
    /// When the kametis last loaded, for "Showing data from …" while offline.
    public private(set) var loadedAt: Date?
    /// The app clock's "now" (fixed in the demo), for "expires in".
    public var now: Date { dependencies.clock.now() }

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

    /// A kameti Home already loaded, by id.
    public func kameti(id: String) -> Kameti? {
        (sections.mine + sections.joined + sections.past).first { $0.id == id }?.kameti
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        failure = nil
        defer { isLoading = false; hasLoaded = true }
        if firstName == nil, let profile = try? await dependencies.profiles.myProfile(userId: userId) {
            firstName = profile.displayName.split(separator: " ").first.map(String.init)
        }
        // Invitations are extra: a failure here never blocks Home.
        invitations = (try? await dependencies.invites.myInvitations()) ?? []
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
            loadedAt = Date()
            KConnectivity.shared.record(nil)
        } catch {
            failure = error
            KConnectivity.shared.record(error)
        }
    }

    /// Declines an invitation from Home, then reloads.
    public func decline(_ invitation: MyInvitation) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.invites.declineInvite(token: nil, inviteId: invitation.inviteId)
        } catch {
            return error
        }
        await load()
        return nil
    }

    private func detail(for item: HomeKametiSummary) async -> HomeKametiSummary {
        var item = item
        let kameti = item.kameti
        let id = kameti.id
        if let months = try? await dependencies.ledger.monthCollections(kametiId: id) {
            item.currentMonth = months.first(where: \.isCurrent)
        }
        let members = (try? await dependencies.kametis.members(kametiId: id)) ?? []
        let slots = (try? await dependencies.kametis.slots(kametiId: id)) ?? []
        let shares = (try? await dependencies.kametis.shares(kametiId: id)) ?? []
        let me = DetailLogic.myMember(in: members, userId: userId)
        if let month = item.currentMonth {
            item.dueDate = DetailLogic.dueDate(of: kameti, monthIndex: month.monthIndex)
            item.recipients = DetailLogic.recipients(kameti: kameti, monthIndex: month.monthIndex, slots: slots, shares: shares, members: members)
                .map { recipient in
                    let index = Int(recipient.member.color ?? "") ?? max(members.firstIndex(of: recipient.member) ?? 0, 0)
                    return HomeKametiSummary.Person(name: recipient.member.id == me?.id ? "You" : recipient.member.name, colorIndex: index)
                }
        }
        if let month = item.currentMonth, month.state == .paidOut || month.state == .paidOutShort,
           let payouts = try? await dependencies.payments.payouts(kametiId: id) {
            let slotIds = Set(slots.filter { $0.payoutMonthIndex == month.monthIndex }.map(\.id))
            item.payoutDate = payouts.filter { $0.voidedAt == nil && slotIds.contains($0.slotId) }.map(\.paidOn).max()
        }
        if !item.isOwner, let me {
            if let balances = try? await dependencies.ledger.memberBalances(kametiId: id) {
                item.owes = balances.first(where: { $0.memberId == me.id })?.owes
            }
            if let turn = DetailLogic.nextTurn(for: me, kameti: kameti, from: item.currentMonth?.monthIndex ?? 1, slots: slots, shares: shares) {
                item.nextTurn = HomeKametiSummary.NextTurn(month: DetailLogic.monthStart(of: kameti, monthIndex: turn.monthIndex), payout: turn.payout)
            }
        }
        return item
    }
}
