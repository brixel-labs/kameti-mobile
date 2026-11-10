import Foundation
import KametiCore

/// Everything a screen may depend on, as protocols. The app target builds the
/// real one (Supabase); tests and previews build one from fakes.
public struct KametiDependencies: Sendable {
    public var kametis: any KametiRepository
    public var ledger: any LedgerRepository
    public var payments: any PaymentsRepository
    public var invites: any InvitesRepository
    public var audit: any AuditRepository
    public var profiles: any ProfileRepository
    public var contacts: any ContactsRepository
    public var auth: any AuthRepository
    public var clock: KametiClock
    /// One key per user action, reused on retry, so a double tap never
    /// records a payment twice.
    public var makeIdempotencyKey: @Sendable () -> String

    public init(
        kametis: any KametiRepository, ledger: any LedgerRepository,
        payments: any PaymentsRepository, invites: any InvitesRepository,
        audit: any AuditRepository, profiles: any ProfileRepository,
        contacts: any ContactsRepository, auth: any AuthRepository,
        clock: KametiClock = KametiClock(),
        makeIdempotencyKey: @escaping @Sendable () -> String = { UUID().uuidString.lowercased() }
    ) {
        self.kametis = kametis; self.ledger = ledger; self.payments = payments
        self.invites = invites; self.audit = audit; self.profiles = profiles
        self.contacts = contacts; self.auth = auth; self.clock = clock
        self.makeIdempotencyKey = makeIdempotencyKey
    }
}
