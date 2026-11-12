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
    /// What I pay a month (member view); zero means I hold no share yet.
    public var monthlyDue: Money?
    /// When this month's payment is due.
    public var dueDate: Date?
    /// Who receives the pot this month.
    public var recipients: [Person] = []
    /// My next payout (member view).
    public var nextTurn: NextTurn?
    /// When this month's payout was made (the latest payout of its slot).
    public var payoutDate: Date?
    /// Everyone in it, in turn order from this month (people without a share
    /// last), for the avatar row.
    public var people: [Person] = []

    /// The same card's details on a freshly loaded kameti row.
    func replacing(_ kameti: Kameti) -> HomeKametiSummary {
        var copy = HomeKametiSummary(kameti: kameti, isOwner: isOwner)
        copy.currentMonth = currentMonth; copy.owes = owes; copy.monthlyDue = monthlyDue; copy.dueDate = dueDate
        copy.recipients = recipients; copy.nextTurn = nextTurn; copy.payoutDate = payoutDate
        copy.people = people
        return copy
    }

    public struct Person: Equatable, Sendable {
        public let name: String
        public let colorIndex: Int
        /// Their payout months (one per slot they're paid in), for the members sheet.
        public var turns: [Date] = []
        /// What they're paid across those turns (share × N each).
        public var payout: Money = .zero
        /// They receive this month's pot.
        public var isThisMonth = false
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
    /// Archived (§6.11): off the main list, behind the "Archived (n)" row.
    public var archived: [HomeKametiSummary] = []

    public var isEmpty: Bool { mine.isEmpty && joined.isEmpty && past.isEmpty && archived.isEmpty }
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
    /// Archived kametis go to their own list (§6.11: hidden from the main
    /// list), opened from the "Archived (n)" row at the end of Past.
    nonisolated static func sections(of summaries: [HomeKametiSummary]) -> HomeSections {
        var result = HomeSections()
        for item in summaries {
            if item.kameti.status == .archived {
                result.archived.append(item)
            } else if isPast(item.kameti.status) {
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
        (sections.mine + sections.joined + sections.past + sections.archived).first { $0.id == id }?.kameti
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        failure = nil
        defer { isLoading = false; hasLoaded = true }
        // The name comes from the profile saved on the phone; the server only
        // the first time (it's saved then for next time).
        if firstName == nil {
            var profile = ProfileCache.load(userId: userId).profile
            if profile == nil, let fetched = try? await dependencies.profiles.myProfile(userId: userId) {
                profile = fetched
                ProfileCache.update(userId: userId) { $0.profile = fetched }
            }
            firstName = profile?.displayName.split(separator: " ").first.map(String.init)
        }
        // Invitations and the list load together. Invitations are extra: a
        // failure there never blocks Home.
        let deps = dependencies
        async let invitationsCall = attempt { try await deps.invites.myInvitations() }
        async let listCall = attempt { try await deps.kametis.listKametis() }
        invitations = (try? await invitationsCall.get()) ?? []
        do throws(Failure) {
            let all = try await listCall.get()
            // Profile's counts and Past list read this, so they stay current.
            ProfileCache.update(userId: userId) { $0.kametis = all }
            // Cards already on screen keep their details while they refresh,
            // so pull to refresh never flashes a card back to "Not started yet".
            let shown = Dictionary(
                (sections.mine + sections.joined + sections.past + sections.archived).map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            var summaries = all.map { kameti in
                shown[kameti.id].map { $0.replacing(kameti) } ?? HomeKametiSummary(kameti: kameti, isOwner: kameti.isOwned(by: userId))
            }
            // Show the list right away, then fill in each card.
            sections = Self.sections(of: summaries)
            // Every card fills in at the same time, not one after another.
            let current = summaries
            await withTaskGroup(of: (Int, HomeKametiSummary).self) { group in
                for index in current.indices where !Self.isPast(current[index].kameti.status) {
                    group.addTask { (index, await self.detail(for: current[index])) }
                }
                for await (index, item) in group { summaries[index] = item }
            }
            sections = Self.sections(of: summaries)
            loadedAt = Date()
            KConnectivity.shared.record(nil)
        } catch {
            failure = error
            KConnectivity.shared.record(error)
        }
    }

    struct TurnEntry {
        let member: Member
        /// Payout months they hold, in turn order.
        var months: [Int]
        /// Their share in each of those slots, summed (× N is the payout).
        var monthly: Money
    }

    /// Each member once, in payout order starting at `month` (this month's
    /// recipients first, then the next turns, wrapping round to earlier ones);
    /// members holding no share come last, in list order. A person with two
    /// slots is one entry with both turns.
    nonisolated static func turnOrder(members: [Member], slots: [Slot], shares: [Share], from month: Int) -> [TurnEntry] {
        let byId = Dictionary(members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let total = max(slots.map(\.payoutMonthIndex).max() ?? 0, 1)
        let ordered = slots.sorted {
            ($0.payoutMonthIndex - month + total) % total < ($1.payoutMonthIndex - month + total) % total
        }
        var position: [String: Int] = [:], result: [TurnEntry] = []
        for slot in ordered {
            // Whoever holds the slot in its payout month (after any transfer).
            let holders = shares.filter {
                $0.slotId == slot.id && $0.effectiveFromMonth <= slot.payoutMonthIndex
                    && ($0.effectiveToMonth.map { $0 >= slot.payoutMonthIndex } ?? true)
            }
            for share in holders {
                guard let member = byId[share.memberId] else { continue }
                if let at = position[member.id] {
                    if result[at].months.last != slot.payoutMonthIndex { result[at].months.append(slot.payoutMonthIndex) }
                    result[at].monthly = result[at].monthly + share.monthlyAmount
                } else {
                    position[member.id] = result.count
                    result.append(TurnEntry(member: member, months: [slot.payoutMonthIndex], monthly: share.monthlyAmount))
                }
            }
        }
        result += members.filter { position[$0.id] == nil }.map { TurnEntry(member: $0, months: [], monthly: .zero) }
        return result
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

    /// Fills in a card. If a request fails (offline, or a refresh that was
    /// cancelled), the card keeps what it already showed.
    private func detail(for original: HomeKametiSummary) async -> HomeKametiSummary {
        var item = original
        let kameti = item.kameti
        let id = kameti.id
        let members: [Member], slots: [Slot], shares: [Share]
        // All at once; a member's balance is only needed on cards they don't run.
        let deps = dependencies, needsBalance = !item.isOwner
        async let collectionsCall = attempt { try await deps.ledger.monthCollections(kametiId: id) }
        async let membersCall = attempt { try await deps.kametis.members(kametiId: id) }
        async let slotsCall = attempt { try await deps.kametis.slots(kametiId: id) }
        async let sharesCall = attempt { try await deps.kametis.shares(kametiId: id) }
        async let balancesCall = attempt { needsBalance ? try await deps.ledger.memberBalances(kametiId: id) : [] }
        do throws(Failure) {
            item.currentMonth = try await collectionsCall.get().first(where: \.isCurrent)
            members = try await membersCall.get()
            slots = try await slotsCall.get()
            shares = try await sharesCall.get()
        } catch {
            return original
        }
        let balances = try? await balancesCall.get()
        let me = DetailLogic.myMember(in: members, userId: userId)
        func person(_ member: Member) -> HomeKametiSummary.Person {
            let index = Int(member.color ?? "") ?? max(members.firstIndex(of: member) ?? 0, 0)
            return HomeKametiSummary.Person(name: member.id == me?.id ? "You" : member.name, colorIndex: index)
        }
        item.people = Self.turnOrder(members: members, slots: slots, shares: shares, from: item.currentMonth?.monthIndex ?? 1)
            .map { entry in
                var p = person(entry.member)
                p.turns = entry.months.map { DetailLogic.monthStart(of: kameti, monthIndex: $0) }
                p.payout = entry.monthly * kameti.monthsN
                p.isThisMonth = item.currentMonth.map { entry.months.contains($0.monthIndex) } ?? false
                return p
            }
        if let month = item.currentMonth {
            item.dueDate = DetailLogic.dueDate(of: kameti, monthIndex: month.monthIndex)
            item.recipients = DetailLogic.recipients(kameti: kameti, monthIndex: month.monthIndex, slots: slots, shares: shares, members: members)
                .map { person($0.member) }
        }
        if let month = item.currentMonth, month.state == .paidOut || month.state == .paidOutShort,
           let payouts = try? await dependencies.payments.payouts(kametiId: id) {
            let slotIds = Set(slots.filter { $0.payoutMonthIndex == month.monthIndex }.map(\.id))
            item.payoutDate = payouts.filter { $0.voidedAt == nil && slotIds.contains($0.slotId) }.map(\.paidOn).max()
        }
        if !item.isOwner, let me {
            if let balances {
                let mine = balances.first(where: { $0.memberId == me.id })
                item.owes = mine?.owes
                item.monthlyDue = mine?.monthlyDue
            }
            if let turn = DetailLogic.nextTurn(for: me, kameti: kameti, from: item.currentMonth?.monthIndex ?? 1, slots: slots, shares: shares) {
                item.nextTurn = HomeKametiSummary.NextTurn(month: DetailLogic.monthStart(of: kameti, monthIndex: turn.monthIndex), payout: turn.payout)
            }
        }
        return item
    }
}
