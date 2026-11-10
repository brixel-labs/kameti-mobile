import Foundation
import KametiCore

public enum KametiStatus: String, Codable, Hashable, Sendable {
    case draft, active, completed, archived, cancelled
}

public enum JoinStatus: String, Codable, Hashable, Sendable {
    case notInvited = "not_invited"
    case invited
    case pendingApproval = "pending_approval"
    case joined
    case declined
}

/// Row of `public.kametis`.
public struct Kameti: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let ownerId: String
    public let name: String
    public let description: String?
    public let startMonth: Date
    public let monthsN: Int
    public let slotAmountC: Money
    public let dueDay: Int
    public let reminderDays: [Int]
    public let maxSlotsPerMember: Int
    public let status: KametiStatus
    public let startedAt: Date?

    public init(
        id: String, ownerId: String, name: String, description: String? = nil,
        startMonth: Date, monthsN: Int, slotAmountC: Money, dueDay: Int,
        reminderDays: [Int], maxSlotsPerMember: Int, status: KametiStatus,
        startedAt: Date? = nil
    ) {
        self.id = id; self.ownerId = ownerId; self.name = name
        self.description = description; self.startMonth = startMonth
        self.monthsN = monthsN; self.slotAmountC = slotAmountC; self.dueDay = dueDay
        self.reminderDays = reminderDays; self.maxSlotsPerMember = maxSlotsPerMember
        self.status = status; self.startedAt = startedAt
    }

    /// The monthly pot: N × C.
    public var pot: Money { slotAmountC * monthsN }

    public func isOwned(by userId: String?) -> Bool {
        userId != nil && ownerId == userId
    }
}

/// Row of `public.members`.
public struct Member: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let name: String
    public let joinStatus: JoinStatus
    public let contactId: String?
    public let profileId: String?
    public let nickname: String?
    public let color: String?

    public init(
        id: String, kametiId: String, name: String, joinStatus: JoinStatus,
        contactId: String? = nil, profileId: String? = nil,
        nickname: String? = nil, color: String? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.name = name
        self.joinStatus = joinStatus; self.contactId = contactId
        self.profileId = profileId; self.nickname = nickname; self.color = color
    }
}

/// Row of `public.slots`. Created automatically, one per month.
public struct Slot: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let payoutMonthIndex: Int
    public let note: String?

    public init(id: String, kametiId: String, payoutMonthIndex: Int, note: String? = nil) {
        self.id = id; self.kametiId = kametiId
        self.payoutMonthIndex = payoutMonthIndex; self.note = note
    }
}

/// Row of `public.shares`.
public struct Share: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let slotId: String
    public let memberId: String
    public let monthlyAmount: Money
    public let effectiveFromMonth: Int
    public let effectiveToMonth: Int?

    public init(
        id: String, kametiId: String, slotId: String, memberId: String,
        monthlyAmount: Money, effectiveFromMonth: Int, effectiveToMonth: Int? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.slotId = slotId
        self.memberId = memberId; self.monthlyAmount = monthlyAmount
        self.effectiveFromMonth = effectiveFromMonth
        self.effectiveToMonth = effectiveToMonth
    }
}

/// Input for `set_slot_shares`.
public struct ShareInput: Hashable, Sendable {
    public let memberId: String
    public let monthlyAmount: Money

    public init(memberId: String, monthlyAmount: Money) {
        self.memberId = memberId; self.monthlyAmount = monthlyAmount
    }
}

/// Input for `create_kameti`.
public struct NewKameti: Sendable {
    public var name: String
    public var startMonth: Date
    public var months: Int
    public var slotAmount: Money
    public var dueDay: Int
    public var reminderDays: [Int]
    public var maxSlotsPerMember: Int
    public var description: String?

    public init(
        name: String, startMonth: Date, months: Int, slotAmount: Money,
        dueDay: Int = 10, reminderDays: [Int] = [1, 5, 8, 10],
        maxSlotsPerMember: Int = 4, description: String? = nil
    ) {
        self.name = name; self.startMonth = startMonth; self.months = months
        self.slotAmount = slotAmount; self.dueDay = dueDay
        self.reminderDays = reminderDays; self.maxSlotsPerMember = maxSlotsPerMember
        self.description = description
    }
}

/// Input for `update_kameti_draft`. `nil` leaves a field unchanged.
public struct KametiChanges: Sendable {
    public var name: String?
    public var description: String?
    public var startMonth: Date?
    public var months: Int?
    public var slotAmount: Money?
    public var dueDay: Int?
    public var reminderDays: [Int]?
    public var maxSlotsPerMember: Int?

    public init(
        name: String? = nil, description: String? = nil, startMonth: Date? = nil,
        months: Int? = nil, slotAmount: Money? = nil, dueDay: Int? = nil,
        reminderDays: [Int]? = nil, maxSlotsPerMember: Int? = nil
    ) {
        self.name = name; self.description = description; self.startMonth = startMonth
        self.months = months; self.slotAmount = slotAmount; self.dueDay = dueDay
        self.reminderDays = reminderDays; self.maxSlotsPerMember = maxSlotsPerMember
    }
}

/// Input for `add_member`.
public struct NewMember: Sendable {
    public var name: String?
    public var contactId: String?
    public var email: String?
    public var phone: String?
    public var nickname: String?
    public var isSelf: Bool

    public init(
        name: String? = nil, contactId: String? = nil, email: String? = nil,
        phone: String? = nil, nickname: String? = nil, isSelf: Bool = false
    ) {
        self.name = name; self.contactId = contactId; self.email = email
        self.phone = phone; self.nickname = nickname; self.isSelf = isSelf
    }
}

/// Input for `update_member`. `nil` leaves a field unchanged; an empty
/// string clears it.
public struct MemberChanges: Sendable {
    public var name: String?
    public var nickname: String?
    public var email: String?
    public var phone: String?

    public init(name: String? = nil, nickname: String? = nil, email: String? = nil, phone: String? = nil) {
        self.name = name; self.nickname = nickname; self.email = email; self.phone = phone
    }
}
