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
    /// The owner's saved people (for "From my people" and members' email and
    /// phone). Owner only: empty for a member.
    public var contacts: [Contact] = []
    /// Every invite of this kameti, newest first. Owner only.
    public var invites: [Invite] = []
    /// Notes I can read: all of them for the owner, shared ones I'm involved
    /// in for a member (FR-71). Newest first.
    public var notes: [Note] = []
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
    /// What the caller already knows (from Home), so the title and subtitle
    /// show the moment the screen opens, before the details load.
    public let preview: Kameti?
    /// An action to start once the owner's tabs are on screen (from Home).
    public var pendingAction: RecordAction?

    public init(kametiId: String, userId: String, dependencies: KametiDependencies, preview: Kameti? = nil) {
        self.preview = preview
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
            let contacts = owner ? ((try? await dependencies.contacts.contacts()) ?? []) : []
            let invites = owner ? ((try? await dependencies.invites.invites(kametiId: kametiId)) ?? []) : []
            // Notes are extra: if they fail to load, the rest still shows.
            let notes = (try? await dependencies.notes.notes(kametiId: kametiId)) ?? []
            state = .loaded(KametiDetailData(
                kameti: kameti, userId: userId, members: members, slots: slots, shares: shares,
                collections: collections, balances: balances, months: months, payments: payments,
                payouts: payouts, contacts: contacts, invites: invites, notes: notes, today: DetailLogic.pakistanToday(dependencies.clock.now())
            ))
        } catch {
            // Keep what is on screen if a refresh fails.
            if case .loaded = state { return }
            state = .failed(error)
        }
    }

    /// Records a payment the owner received, then reloads. `idempotencyKey` is
    /// made once per sheet so a retry never records it twice. Returns the
    /// failure to show, or `nil`.
    public func recordPayment(
        memberId: String, amount: Money, receivedOn: Date, method: PaymentMethod, reference: String?, note: String?, idempotencyKey: String
    ) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.payments.recordPayment(NewPayment(
                memberId: memberId, amount: amount, receivedOn: receivedOn, idempotencyKey: idempotencyKey,
                method: method, reference: reference, note: note
            ))
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// Records several payments in one go (tap-to-settle), then reloads.
    public func recordPayments(items: [BatchPaymentItem], receivedOn: Date, method: PaymentMethod) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.payments.recordPayments(kametiId: kametiId, receivedOn: receivedOn, items: items, method: method)
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// One recipient's payout, and any dues taken from it.
    public struct PayoutEntry: Sendable {
        public let slotId: String
        public let memberId: String
        public let amount: Money
        public let deduction: Money?
        public init(slotId: String, memberId: String, amount: Money, deduction: Money?) {
            self.slotId = slotId; self.memberId = memberId; self.amount = amount; self.deduction = deduction
        }
    }

    /// Records the payouts for a month, plus a payment for each deduction
    /// (dues taken from a payout), then reloads. Keys are made once per sheet so
    /// a retry never records anything twice. Stops at the first failure.
    public func recordPayouts(
        _ entries: [PayoutEntry], paidOn: Date, method: PaymentMethod, reference: String?, note: String?,
        deductionNote: String, payoutKeys: [String: String], deductionKeys: [String: String]
    ) async -> Failure? {
        var failure: Failure?
        loop: for entry in entries {
            do throws(Failure) {
                if let deduction = entry.deduction, deduction.isPositive {
                    _ = try await dependencies.payments.recordPayment(NewPayment(
                        memberId: entry.memberId, amount: deduction, receivedOn: paidOn,
                        idempotencyKey: deductionKeys[entry.memberId] ?? UUID().uuidString.lowercased(),
                        method: .other, note: deductionNote
                    ))
                }
                if entry.amount.isPositive {
                    _ = try await dependencies.payments.recordPayout(NewPayout(
                        slotId: entry.slotId, memberId: entry.memberId, amount: entry.amount, paidOn: paidOn,
                        idempotencyKey: payoutKeys[entry.memberId] ?? UUID().uuidString.lowercased(),
                        method: method, reference: reference, note: note
                    ))
                }
            } catch {
                failure = error
                break loop
            }
        }
        await load()
        return failure
    }

    /// Voids a payout with a reason.
    public func voidPayout(id: String, reason: String) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.payments.voidPayout(id: id, reason: reason)
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// Voids a payment with a reason (payments are never edited or deleted).
    public func voidPayment(id: String, reason: String) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.payments.voidPayment(id: id, reason: reason)
        } catch {
            return error
        }
        await load()
        return nil
    }

    // MARK: Members

    /// Adds a member (a new person, or one of the owner's saved people), then
    /// reloads. Returns the failure to show, or `nil`.
    public func addMember(_ new: NewMember) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.kametis.addMember(kametiId: kametiId, new)
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// Saves a member's name, email or phone, then reloads.
    public func updateMember(id: String, changes: MemberChanges) async -> Failure? {
        do throws(Failure) {
            _ = try await dependencies.kametis.updateMember(id: id, changes: changes)
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// Removes a member who holds no shares and has no payments, then reloads.
    public func removeMember(id: String) async -> Failure? {
        do throws(Failure) {
            try await dependencies.kametis.removeMember(id: id)
        } catch {
            return error
        }
        await load()
        return nil
    }

    // MARK: Invites

    /// A freshly made invite. The token and code can only be read when the
    /// invite is created or resent, so they're kept for this screen's life.
    public struct SentInvite: Equatable, Sendable {
        public let link: InviteLink
        /// `false` when email isn't set up: the owner shares the code or link.
        public let emailed: Bool
    }

    public private(set) var sentInvites: [String: SentInvite] = [:]

    /// Creates (or with `resend`, replaces) a member's invite and emails it
    /// when email is set up, then reloads.
    public func invite(memberId: String, resend: Bool = false) async -> Failure? {
        do throws(Failure) {
            let link = resend
                ? try await dependencies.invites.resendInvite(memberId: memberId)
                : try await dependencies.invites.createInvite(memberId: memberId)
            // The invite exists either way; a failed email only means sharing by hand.
            let emailed = (try? await dependencies.invites.sendInviteEmail(link)) ?? false
            sentInvites[memberId] = SentInvite(link: link, emailed: emailed)
        } catch {
            return error
        }
        await load()
        return nil
    }

    /// Invites everyone given, one by one. Returns how many were invited and
    /// the first failure, if any.
    public func inviteAll(memberIds: [String]) async -> (invited: Int, failure: Failure?) {
        var invited = 0
        var failure: Failure?
        for id in memberIds {
            do throws(Failure) {
                let link = try await dependencies.invites.createInvite(memberId: id)
                let emailed = (try? await dependencies.invites.sendInviteEmail(link)) ?? false
                sentInvites[id] = SentInvite(link: link, emailed: emailed)
                invited += 1
            } catch {
                failure = failure ?? error
            }
        }
        await load()
        return (invited, failure)
    }

    public func revokeInvite(memberId: String) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.invites.revokeInvite(memberId: memberId) } catch { return error }
        sentInvites[memberId] = nil
        await load()
        return nil
    }

    public func approveJoin(memberId: String) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.invites.approveJoin(memberId: memberId) } catch { return error }
        await load()
        return nil
    }

    public func declineJoin(memberId: String) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.invites.declineJoin(memberId: memberId) } catch { return error }
        await load()
        return nil
    }

    // MARK: Kameti

    /// Saves the owner's edits to a running kameti (name, description, due
    /// day, reminders), then reloads.
    public func updateKameti(_ changes: KametiChanges) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.kametis.updateKameti(id: kametiId, changes: changes) } catch { return error }
        await load()
        return nil
    }

    // MARK: Notes

    public func addNote(_ new: NewNote) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.notes.addNote(kametiId: kametiId, new) } catch { return error }
        await load()
        return nil
    }

    public func updateNote(id: String, body: String?, visibility: NoteVisibility?) async -> Failure? {
        do throws(Failure) { _ = try await dependencies.notes.updateNote(id: id, body: body, visibility: visibility) } catch { return error }
        await load()
        return nil
    }

    public func deleteNote(id: String) async -> Failure? {
        do throws(Failure) { try await dependencies.notes.deleteNote(id: id) } catch { return error }
        await load()
        return nil
    }

    /// The app clock's "now" (fixed in the demo), for "expires in".
    public var now: Date { dependencies.clock.now() }

    public var idempotencyKey: String { dependencies.makeIdempotencyKey() }
}
