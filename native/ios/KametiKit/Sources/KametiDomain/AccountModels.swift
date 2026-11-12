import Foundation
import KametiCore

/// What deleting the account would do (`account_deletion_check()`,
/// REQUIREMENTS §5.5): running kametis the user owns block it; drafts and
/// saved people are deleted; member records are unlinked but stay in the
/// owners' ledgers; past kametis are kept for their members.
public struct AccountDeletionCheck: Codable, Hashable, Sendable {
    public struct KametiRef: Codable, Hashable, Identifiable, Sendable {
        public let id: String
        public let name: String
        public let status: KametiStatus?

        public init(id: String, name: String, status: KametiStatus? = nil) {
            self.id = id; self.name = name; self.status = status
        }
    }

    public let canDelete: Bool
    public let blockingKametis: [KametiRef]
    public let draftsToDelete: [KametiRef]
    public let ownedKametisKept: [KametiRef]
    public let membershipsToUnlink: Int
    public let contactsToDelete: Int

    public init(
        canDelete: Bool, blockingKametis: [KametiRef] = [], draftsToDelete: [KametiRef] = [],
        ownedKametisKept: [KametiRef] = [], membershipsToUnlink: Int = 0, contactsToDelete: Int = 0
    ) {
        self.canDelete = canDelete; self.blockingKametis = blockingKametis; self.draftsToDelete = draftsToDelete
        self.ownedKametisKept = ownedKametisKept; self.membershipsToUnlink = membershipsToUnlink
        self.contactsToDelete = contactsToDelete
    }
}

/// Deleting the signed-in account (the `delete-account` Edge Function).
public protocol AccountRepository: Sendable {
    func deletionCheck() async throws(Failure) -> AccountDeletionCheck
    /// Deletes the account. Fails with `owner_has_active_kametis` while the
    /// user still runs a kameti. The app signs out afterwards.
    func deleteAccount() async throws(Failure)
}

/// The default when no account backend is wired (older test setups).
public struct UnavailableAccountRepository: AccountRepository {
    public init() {}
    public func deletionCheck() async throws(Failure) -> AccountDeletionCheck { throw .unknown(description: "account deletion is not available") }
    public func deleteAccount() async throws(Failure) { throw .unknown(description: "account deletion is not available") }
}
