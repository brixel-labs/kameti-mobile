import Foundation
import KametiCore

public enum PaymentMethod: String, Codable, Hashable, Sendable {
    case cash
    case bankTransfer = "bank_transfer"
    case other
}

/// Row of `public.payments`. Append-only: corrections are voids.
public struct Payment: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let memberId: String
    public let amount: Money
    public let receivedOn: Date
    public let method: PaymentMethod
    public let createdAt: Date
    public let reference: String?
    public let note: String?
    public let paidByName: String?
    public let voidedAt: Date?
    public let voidReason: String?

    public init(
        id: String, kametiId: String, memberId: String, amount: Money, receivedOn: Date,
        method: PaymentMethod, createdAt: Date, reference: String? = nil, note: String? = nil,
        paidByName: String? = nil, voidedAt: Date? = nil, voidReason: String? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.memberId = memberId
        self.amount = amount; self.receivedOn = receivedOn; self.method = method
        self.createdAt = createdAt; self.reference = reference; self.note = note
        self.paidByName = paidByName; self.voidedAt = voidedAt; self.voidReason = voidReason
    }

    public var isVoided: Bool { voidedAt != nil }
}

/// Row of `public.payouts`.
public struct Payout: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let slotId: String
    public let memberId: String
    public let amount: Money
    public let paidOn: Date
    public let method: PaymentMethod
    public let reference: String?
    public let note: String?
    public let voidedAt: Date?
    public let voidReason: String?

    public init(
        id: String, kametiId: String, slotId: String, memberId: String, amount: Money,
        paidOn: Date, method: PaymentMethod, reference: String? = nil, note: String? = nil,
        voidedAt: Date? = nil, voidReason: String? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.slotId = slotId
        self.memberId = memberId; self.amount = amount; self.paidOn = paidOn
        self.method = method; self.reference = reference; self.note = note
        self.voidedAt = voidedAt; self.voidReason = voidReason
    }

    public var isVoided: Bool { voidedAt != nil }
}

/// Input for `record_payment`. `idempotencyKey` is one per user action and is
/// reused on retry, so a double tap never records twice.
public struct NewPayment: Sendable {
    public var memberId: String
    public var amount: Money
    public var receivedOn: Date
    public var idempotencyKey: String
    public var method: PaymentMethod
    public var reference: String?
    public var note: String?
    public var paidByName: String?

    public init(
        memberId: String, amount: Money, receivedOn: Date, idempotencyKey: String,
        method: PaymentMethod = .cash, reference: String? = nil, note: String? = nil,
        paidByName: String? = nil
    ) {
        self.memberId = memberId; self.amount = amount; self.receivedOn = receivedOn
        self.idempotencyKey = idempotencyKey; self.method = method
        self.reference = reference; self.note = note; self.paidByName = paidByName
    }
}

/// One line of a tap-to-settle batch (`record_payments_batch`).
public struct BatchPaymentItem: Hashable, Sendable {
    public var memberId: String
    public var amount: Money
    public var idempotencyKey: String
    public var paidByName: String?
    public var reference: String?
    public var note: String?

    public init(
        memberId: String, amount: Money, idempotencyKey: String,
        paidByName: String? = nil, reference: String? = nil, note: String? = nil
    ) {
        self.memberId = memberId; self.amount = amount; self.idempotencyKey = idempotencyKey
        self.paidByName = paidByName; self.reference = reference; self.note = note
    }
}

/// Input for `record_payout`.
public struct NewPayout: Sendable {
    public var slotId: String
    public var memberId: String
    public var amount: Money
    public var paidOn: Date
    public var idempotencyKey: String
    public var method: PaymentMethod
    public var reference: String?
    public var note: String?

    public init(
        slotId: String, memberId: String, amount: Money, paidOn: Date, idempotencyKey: String,
        method: PaymentMethod = .cash, reference: String? = nil, note: String? = nil
    ) {
        self.slotId = slotId; self.memberId = memberId; self.amount = amount
        self.paidOn = paidOn; self.idempotencyKey = idempotencyKey; self.method = method
        self.reference = reference; self.note = note
    }
}
