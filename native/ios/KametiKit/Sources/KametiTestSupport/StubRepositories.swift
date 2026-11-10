import Foundation
import KametiCore
import KametiDomain

private let notStubbed = Failure.unknown(description: "not stubbed in this test")

/// Satisfies every repository protocol except the ones a test cares about:
/// each call fails with an "unused" failure, so a test that touches one by
/// accident fails loudly.
public struct UnusedRepositories: LedgerRepository, PaymentsRepository, InvitesRepository, AuditRepository, ContactsRepository {
    public init() {}

    // LedgerRepository
    public func memberBalances(kametiId: String) async throws(Failure) -> [MemberBalanceRow] { throw notStubbed }
    public func memberMonths(kametiId: String, memberId: String?) async throws(Failure) -> [MemberMonthRow] { throw notStubbed }
    public func monthCollections(kametiId: String) async throws(Failure) -> [MonthCollectionRow] { throw notStubbed }

    // PaymentsRepository
    public func payments(kametiId: String) async throws(Failure) -> [Payment] { throw notStubbed }
    public func payouts(kametiId: String) async throws(Failure) -> [Payout] { throw notStubbed }
    public func recordPayment(_ new: NewPayment) async throws(Failure) -> Payment { throw notStubbed }
    public func recordPayments(kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod) async throws(Failure) -> [Payment] { throw notStubbed }
    public func voidPayment(id: String, reason: String) async throws(Failure) -> Payment { throw notStubbed }
    public func recordPayout(_ new: NewPayout) async throws(Failure) -> Payout { throw notStubbed }
    public func voidPayout(id: String, reason: String) async throws(Failure) -> Payout { throw notStubbed }

    // InvitesRepository
    public func createInvite(memberId: String) async throws(Failure) -> InviteLink { throw notStubbed }
    public func resendInvite(memberId: String) async throws(Failure) -> InviteLink { throw notStubbed }
    public func revokeInvite(memberId: String) async throws(Failure) -> Member { throw notStubbed }
    public func approveJoin(memberId: String) async throws(Failure) -> Member { throw notStubbed }
    public func declineJoin(memberId: String) async throws(Failure) -> Member { throw notStubbed }
    public func unlinkMember(memberId: String) async throws(Failure) -> Member { throw notStubbed }
    public func sendInviteEmail(_ link: InviteLink) async throws(Failure) -> Bool { throw notStubbed }
    public func invites(kametiId: String) async throws(Failure) -> [Invite] { throw notStubbed }
    public func previewInvite(token: String?, inviteId: String?) async throws(Failure) -> InvitePreview { throw notStubbed }
    public func acceptInvite(token: String?, inviteId: String?) async throws(Failure) -> Member { throw notStubbed }
    public func declineInvite(token: String?, inviteId: String?) async throws(Failure) -> Member { throw notStubbed }
    public func myInvitations() async throws(Failure) -> [MyInvitation] { throw notStubbed }

    // AuditRepository
    public func audit(kametiId: String, limit: Int) async throws(Failure) -> [AuditEntry] { throw notStubbed }

    // ContactsRepository
    public func contacts() async throws(Failure) -> [Contact] { throw notStubbed }
}

/// A `KametiRepository` that only knows its list of kametis; every other
/// call fails as "not stubbed".
public struct StubKametiRepository: KametiRepository {
    private let kametis: [Kameti]

    public init(_ kametis: [Kameti] = []) { self.kametis = kametis }

    public func listKametis() async throws(Failure) -> [Kameti] { kametis }
    public func kameti(id: String) async throws(Failure) -> Kameti {
        guard let found = kametis.first(where: { $0.id == id }) else { throw Failure.server(code: "not_found", detail: nil) }
        return found
    }
    public func members(kametiId: String) async throws(Failure) -> [Member] { throw notStubbed }
    public func slots(kametiId: String) async throws(Failure) -> [Slot] { throw notStubbed }
    public func shares(kametiId: String) async throws(Failure) -> [Share] { throw notStubbed }
    public func createKameti(_ new: NewKameti) async throws(Failure) -> Kameti { throw notStubbed }
    public func updateKameti(id: String, changes: KametiChanges) async throws(Failure) -> Kameti { throw notStubbed }
    public func startKameti(id: String) async throws(Failure) -> Kameti { throw notStubbed }
    public func addMember(kametiId: String, _ new: NewMember) async throws(Failure) -> Member { throw notStubbed }
    public func updateMember(id: String, changes: MemberChanges) async throws(Failure) -> Member { throw notStubbed }
    public func removeMember(id: String) async throws(Failure) { throw notStubbed }
    public func setSlotShares(slotId: String, shares: [ShareInput]) async throws(Failure) -> [Share] { throw notStubbed }
    public func reorderSlots(kametiId: String, slotIdsInOrder: [String]) async throws(Failure) -> [Slot] { throw notStubbed }
}
