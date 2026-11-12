import Foundation
import KametiCore
import KametiDomain

/// Account deletion in the demo, with the backend's rules: running kametis
/// the user owns block it; otherwise it "deletes" by signing out.
struct SampleAccountRepository: AccountRepository {
    let kametis: SampleKametiRepository
    let contacts: SampleContactStore
    let auth: FakeAuthRepository

    func deletionCheck() async throws(Failure) -> AccountDeletionCheck {
        let all = try await kametis.listKametis()
        let mine = all.filter { $0.ownerId == SampleData.userId }
        let ref = { (k: Kameti) in AccountDeletionCheck.KametiRef(id: k.id, name: k.name, status: k.status) }
        let blocking = mine.filter { $0.status == .active }.map(ref)
        return AccountDeletionCheck(
            canDelete: blocking.isEmpty, blockingKametis: blocking,
            draftsToDelete: mine.filter { $0.status == .draft }.map(ref),
            ownedKametisKept: mine.filter { [.completed, .archived, .cancelled].contains($0.status) }.map(ref),
            membershipsToUnlink: all.filter { $0.ownerId != SampleData.userId }.count,
            contactsToDelete: contacts.all.count
        )
    }

    func deleteAccount() async throws(Failure) {
        guard try await deletionCheck().canDelete else { throw Failure.server(code: "owner_has_active_kametis", detail: nil) }
        try await auth.signOut()
    }
}
