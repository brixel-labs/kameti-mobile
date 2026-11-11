import Foundation
import KametiCore

// Repository protocols. Features depend on these, never on the Supabase
// implementations, so every screen and view model can be tested with a fake.
// All of them throw only `Failure` (typed throws).
//
// Writes are Postgres RPCs; reads use row-level-secured tables and views.

/// Kametis, members, slots and shares.
public protocol KametiRepository: Sendable {
    /// Every kameti the user owns or has joined (the backend decides).
    func listKametis() async throws(Failure) -> [Kameti]
    func kameti(id: String) async throws(Failure) -> Kameti
    func members(kametiId: String) async throws(Failure) -> [Member]
    func slots(kametiId: String) async throws(Failure) -> [Slot]
    func shares(kametiId: String) async throws(Failure) -> [Share]

    func createKameti(_ new: NewKameti) async throws(Failure) -> Kameti
    /// Draft only for structure; name, description and due day also while active.
    func updateKameti(id: String, changes: KametiChanges) async throws(Failure) -> Kameti
    /// Validates FR-12 on the server; fails with `kameti_not_ready`.
    func startKameti(id: String) async throws(Failure) -> Kameti
    /// Owner only (§6.11): hides it from the running lists and makes it
    /// read-only for everyone. Fails with `kameti_already_archived`.
    func archiveKameti(id: String) async throws(Failure) -> Kameti
    /// Owner only: back to the state it was archived from. Fails with
    /// `kameti_not_archived` or `kameti_name_taken`.
    func restoreKameti(id: String) async throws(Failure) -> Kameti
    /// Owner only (FR-13): a new draft with the same settings, members, shares
    /// and payout order, and no payments. Fails with `kameti_name_taken`.
    func duplicateKameti(id: String, name: String, startMonth: Date) async throws(Failure) -> Kameti

    func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member
    func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member
    func removeMember(id: String) async throws(Failure)

    /// Replaces a slot's shares. The server checks the sum equals C, the
    /// Rs 1,000 steps, at most 4 sharers and the member slot limit.
    func setSlotShares(slotId: String, shares: [ShareInput]) async throws(Failure) -> [Share]
    /// FR-33: moves a running kameti's share to another member from
    /// `fromMonth` on; returns the new holder's share. The note is the optional
    /// settlement note, saved as a private note.
    func transferShare(shareId: String, toMemberId: String, fromMonth: Int, note: String?) async throws(Failure) -> Share
    /// New payout order: slot ids in month order (1...N).
    func reorderSlots(kametiId: String, slotIdsInOrder: [String]) async throws(Failure) -> [Slot]
}

/// The backend's calculated views.
public protocol LedgerRepository: Sendable {
    func memberBalances(kametiId: String) async throws(Failure) -> [MemberBalanceRow]
    func memberMonths(kametiId: String, memberId: String?) async throws(Failure) -> [MemberMonthRow]
    func monthCollections(kametiId: String) async throws(Failure) -> [MonthCollectionRow]
}

/// Payments and payouts. Append-only; corrections are voids.
public protocol PaymentsRepository: Sendable {
    func payments(kametiId: String) async throws(Failure) -> [Payment]
    func payouts(kametiId: String) async throws(Failure) -> [Payout]

    func recordPayment(_ new: NewPayment) async throws(Failure) -> Payment
    /// Tap to settle: all items in one transaction.
    func recordPayments(
        kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod
    ) async throws(Failure) -> [Payment]
    func voidPayment(id: String, reason: String) async throws(Failure) -> Payment

    func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout
    func voidPayout(id: String, reason: String) async throws(Failure) -> Payout
}

/// Invites and joining.
public protocol InvitesRepository: Sendable {
    // Owner
    func createInvite(memberId: String) async throws(Failure) -> InviteLink
    func resendInvite(memberId: String) async throws(Failure) -> InviteLink
    func revokeInvite(memberId: String) async throws(Failure) -> Member
    func approveJoin(memberId: String) async throws(Failure) -> Member
    func declineJoin(memberId: String) async throws(Failure) -> Member
    func unlinkMember(memberId: String) async throws(Failure) -> Member
    /// Emails the link. `false` means email isn't configured on the server
    /// (the link is still valid: share it by hand).
    func sendInviteEmail(_ link: InviteLink) async throws(Failure) -> Bool
    func invites(kametiId: String) async throws(Failure) -> [Invite]

    // Invitee: exactly one of `token` (or the 6-character code) and `inviteId`.
    func previewInvite(token: String?, inviteId: String?) async throws(Failure) -> InvitePreview
    func acceptInvite(token: String?, inviteId: String?) async throws(Failure) -> Member
    func declineInvite(token: String?, inviteId: String?) async throws(Failure) -> Member
    func myInvitations() async throws(Failure) -> [MyInvitation]
}

public protocol AuditRepository: Sendable {
    /// Newest first.
    func audit(kametiId: String, limit: Int) async throws(Failure) -> [AuditEntry]
}

public protocol ProfileRepository: Sendable {
    func myProfile(userId: String) async throws(Failure) -> Profile
    /// The name other people see (1–80 characters).
    func updateDisplayName(userId: String, _ name: String) async throws(Failure) -> Profile
}

/// The owner's private contact list. Read only.
public protocol ContactsRepository: Sendable {
    func contacts() async throws(Failure) -> [Contact]
}

/// Sign-in state and sign-in methods.
public protocol AuthRepository: Sendable {
    /// The signed-in user's id, or `nil`.
    var currentUserId: String? { get }
    /// Emits the current user id first, then every change.
    func userIdChanges() -> AsyncStream<String?>

    /// Native Google sign-in. `false` means the user closed the sheet.
    func signInWithGoogle() async throws(Failure) -> Bool
    /// Native Sign in with Apple. `false` means the user cancelled.
    func signInWithApple() async throws(Failure) -> Bool
    /// Local development only: email and password for seeded test users.
    func signInWithPassword(email: String, password: String) async throws(Failure)
    func signOut() async throws(Failure)
    /// How the signed-in account can sign in (Apple, Google, email), with
    /// the email each one uses. Empty when unknown.
    func signInMethods() async -> [SignInMethod]
}

/// One way to sign in to the account.
public struct SignInMethod: Hashable, Sendable {
    public enum Provider: String, Sendable { case apple, google, email }
    public let provider: Provider
    public let email: String?

    public init(provider: Provider, email: String?) {
        self.provider = provider; self.email = email
    }
}
