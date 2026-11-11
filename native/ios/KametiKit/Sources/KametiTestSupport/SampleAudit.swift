import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// The demo's audit log, shared by the demo stores so whatever you do in the
/// demo shows up in Activity. Seeded with the sample payments and a few
/// realistic events. Payloads use the backend's column names.
final class SampleAuditLog: Sendable {
    private let state: Mutex<(entries: [AuditEntry], next: Int, tick: TimeInterval)>

    init() {
        let hour: TimeInterval = 3600, day: TimeInterval = 86_400
        let now = SampleData.now
        var seed: [AuditEntry] = []
        var id = 1
        func add(_ kameti: String, _ action: String, _ entity: String, _ entityId: String?, _ member: String?,
                 before: JSONValue? = nil, after: JSONValue? = nil, at: Date) {
            seed.append(AuditEntry(id: id, kametiId: kameti, action: action, entity: entity, at: at, memberId: member,
                                   actorId: SampleData.userId, entityId: entityId, before: before, after: after))
            id += 1
        }
        // Every sample payment, recorded on the day it was received.
        for payment in SampleData.familyPayments + SampleData.friendsPayments + SampleData.officePayments {
            add(payment.kametiId, "payment.record", "payment", payment.id, payment.memberId,
                after: Self.payment(payment), at: payment.receivedOn + 10 * hour)
        }
        add("family", "kameti.create", "kameti", "family", nil, at: SampleData.date(9) + 27 * day)
        add("family", "kameti.start", "kameti", "family", nil, at: SampleData.date(10) + 9 * hour)
        add("family", "note.add", "note", "n4", nil, after: .object(["body": .string("Payments by the 10th please. Bank: Meezan, account details in the family group.")]),
            at: now - 40 * day)
        add("family", "payout.record", "payout", "fp-oct", "f1",
            after: .object(["amount": .int(1_500_000), "member_id": .string("f1"), "slot_id": .string("fs1")]), at: SampleData.date(10) + 11 * day + 17 * hour)
        add("family", "slot.reorder", "kameti", "family", nil, at: SampleData.date(10) + 2 * day + 10 * hour)
        add("family", "invite.create", "invite", "inv-f6", "f6",
            after: .object(["member_id": .string("f6"), "email": .string("faisal.iqbal@gmail.com")]), at: now - 2 * day)
        add("family", "invite.accept_pending_approval", "invite", "inv-f5", "f5", at: now - day + 5 * hour)
        add("family", "kameti.update", "kameti", "family", nil,
            before: .object(["name": .string("Family kameti"), "due_day": .int(10), "reminder_days": .array([.int(1), .int(3), .int(8)])]),
            after: .object(["name": .string("Family kameti"), "due_day": .int(10), "reminder_days": .array([.int(1), .int(3)])]),
            at: now - day - 4 * hour)
        state = Mutex((entries: seed, next: id, tick: 0))
    }

    /// Adds an entry stamped "now" (a second later each time, so order holds).
    func record(_ kametiId: String, _ action: String, entity: String, entityId: String?, member: String?, before: JSONValue? = nil, after: JSONValue? = nil) {
        state.withLock { s in
            s.tick += 1
            s.entries.append(AuditEntry(
                id: s.next, kametiId: kametiId, action: action, entity: entity, at: SampleData.now + s.tick, memberId: member,
                actorId: SampleData.userId, entityId: entityId, before: before, after: after
            ))
            s.next += 1
        }
    }

    func entries(_ kametiId: String) -> [AuditEntry] {
        state.withLock { $0.entries.filter { $0.kametiId == kametiId } }
    }

    // MARK: Payloads

    static func payment(_ p: Payment) -> JSONValue {
        var fields: [String: JSONValue] = ["amount": .int(p.amount.rupees), "member_id": .string(p.memberId), "method": .string(p.method.rawValue)]
        if let reason = p.voidReason { fields["void_reason"] = .string(reason) }
        return .object(fields)
    }

    static func payout(_ p: Payout) -> JSONValue {
        var fields: [String: JSONValue] = ["amount": .int(p.amount.rupees), "member_id": .string(p.memberId), "slot_id": .string(p.slotId)]
        if let reason = p.voidReason { fields["void_reason"] = .string(reason) }
        return .object(fields)
    }

    static func kameti(_ k: Kameti) -> JSONValue {
        .object([
            "name": .string(k.name), "description": k.description.map(JSONValue.string) ?? .null,
            "due_day": .int(k.dueDay), "reminder_days": .array(k.reminderDays.map(JSONValue.int)),
        ])
    }

    static func member(_ m: Member) -> JSONValue {
        .object(["name": .string(m.name), "nickname": m.nickname.map(JSONValue.string) ?? .null, "join_status": .string(m.joinStatus.rawValue)])
    }
}

/// FR-90 in the demo: the owner reads everything; a member only the
/// entries about them.
struct SampleAuditRepository: AuditRepository {
    let log: SampleAuditLog
    let kametis: SampleKametiRepository

    func audit(kametiId: String, limit: Int) async throws(Failure) -> [AuditEntry] {
        guard let kameti = kametis.kametiRow(kametiId) else { throw Failure.server(code: "not_found", detail: nil) }
        var entries = log.entries(kametiId)
        if kameti.ownerId != SampleData.userId {
            let me = kametis.myMember(in: kametiId)?.id
            entries = entries.filter { me != nil && $0.memberId == me }
        }
        return Array(entries.sorted { $0.at > $1.at }.prefix(limit))
    }
}
