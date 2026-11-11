import Foundation
import KametiCore
import KametiDomain

/// RPC arguments, one pure builder per call, so what we send to Postgres is
/// unit-tested without a network. Keys are the backend's `p_*` names.
typealias RPCParams = [String: JSONValue]

extension JSONValue {
    static func opt(_ value: String?) -> JSONValue { value.map { .string($0) } ?? .null }
    static func opt(_ value: Int?) -> JSONValue { value.map { .int($0) } ?? .null }
    static func day(_ date: Date) -> JSONValue { .string(DateOnly.string(from: date)) }
}

enum Params {
    static func addNote(kametiId: String, _ n: NewNote) -> RPCParams {
        [
            "p_kameti_id": .string(kametiId),
            "p_body": .string(n.body),
            "p_visibility": .string(n.visibility.rawValue),
            "p_target_type": .string(n.targetType.rawValue),
            "p_target_id": .opt(n.targetType == .kameti ? nil : n.targetId),
        ]
    }

    static func updateNote(id: String, body: String?, visibility: NoteVisibility?) -> RPCParams {
        ["p_note_id": .string(id), "p_body": .opt(body), "p_visibility": .opt(visibility?.rawValue)]
    }

    static func createKameti(_ new: NewKameti) -> RPCParams {
        [
            "p_name": .string(new.name),
            "p_start_month": .day(new.startMonth),
            "p_months_n": .int(new.months),
            "p_slot_amount_c": .int(new.slotAmount.rupees),
            "p_due_day": .int(new.dueDay),
            "p_reminder_days": .array(new.reminderDays.map { .int($0) }),
            "p_max_slots_per_member": .int(new.maxSlotsPerMember),
            "p_description": .opt(new.description),
        ]
    }

    /// `null` leaves a field unchanged on the backend.
    static func updateKameti(id: String, _ c: KametiChanges) -> RPCParams {
        [
            "p_kameti_id": .string(id),
            "p_name": .opt(c.name),
            "p_description": .opt(c.description),
            "p_start_month": c.startMonth.map { .day($0) } ?? .null,
            "p_months_n": .opt(c.months),
            "p_slot_amount_c": .opt(c.slotAmount?.rupees),
            "p_due_day": .opt(c.dueDay),
            "p_reminder_days": c.reminderDays.map { .array($0.map { .int($0) }) } ?? .null,
            "p_max_slots_per_member": .opt(c.maxSlotsPerMember),
        ]
    }

    static func addMember(kametiId: String, _ m: NewMember) -> RPCParams {
        [
            "p_kameti_id": .string(kametiId),
            "p_name": .opt(m.name),
            "p_contact_id": .opt(m.contactId),
            "p_email": .opt(m.email),
            "p_phone": .opt(m.phone),
            "p_nickname": .opt(m.nickname),
            "p_is_self": .bool(m.isSelf),
        ]
    }

    static func updateMember(id: String, _ c: MemberChanges) -> RPCParams {
        [
            "p_member_id": .string(id),
            "p_name": .opt(c.name),
            "p_nickname": .opt(c.nickname),
            "p_email": .opt(c.email),
            "p_phone": .opt(c.phone),
        ]
    }

    static func setSlotShares(slotId: String, _ shares: [ShareInput]) -> RPCParams {
        [
            "p_slot_id": .string(slotId),
            "p_shares": .array(shares.map {
                .object(["member_id": .string($0.memberId), "monthly_amount": .int($0.monthlyAmount.rupees)])
            }),
        ]
    }

    static func recordPayment(_ p: NewPayment) -> RPCParams {
        [
            "p_member_id": .string(p.memberId),
            "p_amount": .int(p.amount.rupees),
            "p_received_on": .day(p.receivedOn),
            "p_idempotency_key": .string(p.idempotencyKey),
            "p_method": .string(p.method.rawValue),
            "p_reference": .opt(p.reference),
            "p_note": .opt(p.note),
            "p_paid_by_name": .opt(p.paidByName),
        ]
    }

    static func recordPayments(
        kametiId: String, receivedOn: Date, items: [BatchPaymentItem], method: PaymentMethod
    ) -> RPCParams {
        [
            "p_kameti_id": .string(kametiId),
            "p_received_on": .day(receivedOn),
            "p_items": .array(items.map(batchItem)),
            "p_method": .string(method.rawValue),
        ]
    }

    /// Optional fields are left out, not sent as null.
    static func batchItem(_ i: BatchPaymentItem) -> JSONValue {
        var object: [String: JSONValue] = [
            "member_id": .string(i.memberId),
            "amount": .int(i.amount.rupees),
            "idempotency_key": .string(i.idempotencyKey),
        ]
        if let name = i.paidByName { object["paid_by_name"] = .string(name) }
        if let reference = i.reference { object["reference"] = .string(reference) }
        if let note = i.note { object["note"] = .string(note) }
        return .object(object)
    }

    static func recordPayout(_ p: NewPayout) -> RPCParams {
        [
            "p_slot_id": .string(p.slotId),
            "p_member_id": .string(p.memberId),
            "p_amount": .int(p.amount.rupees),
            "p_paid_on": .day(p.paidOn),
            "p_idempotency_key": .string(p.idempotencyKey),
            "p_method": .string(p.method.rawValue),
            "p_reference": .opt(p.reference),
            "p_note": .opt(p.note),
        ]
    }

    /// `preview_invite`, `accept_invite` and `decline_invite`: exactly one of
    /// the token (or the 6-character code) and the invite id.
    static func inviteLookup(token: String?, inviteId: String?) -> RPCParams {
        ["p_token": .opt(token), "p_invite_id": .opt(inviteId)]
    }
}
