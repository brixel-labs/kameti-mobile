import Foundation
import KametiCore

/// Matches `public.invite_status`.
public enum InviteStatus: String, Codable, Hashable, Sendable {
    case pending, accepted, declined, revoked, superseded
}

/// What happened to an invite's email (`public.email_delivery`), reported by
/// Resend. `bounced` or `complained` means it didn't arrive (E39b).
public enum EmailDelivery: String, Codable, Hashable, Sendable {
    case sent, delivered, delayed, bounced, complained

    public var didNotArrive: Bool { self == .bounced || self == .complained }
}

/// Row of `public.invites`: owner-only. The token itself is never stored in
/// readable form, so "copy link" later means resending (a new link).
public struct Invite: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let memberId: String
    public let status: InviteStatus
    public let expiresAt: Date
    public let sendCount: Int
    public let email: String?
    public let sentAt: Date?
    /// The email the invitee signed in with. Show it masked.
    public let acceptedEmail: String?
    /// What happened to the last invite email; `nil` when none was sent.
    public let deliveryStatus: EmailDelivery?

    /// The columns the app may read (the table hides the token and code
    /// hashes, so `select *` is refused).
    public static let columns = "id,kameti_id,member_id,status,expires_at,send_count,email,sent_at,accepted_email,delivery_status"

    public init(
        id: String, kametiId: String, memberId: String, status: InviteStatus,
        expiresAt: Date, sendCount: Int, email: String? = nil, sentAt: Date? = nil,
        acceptedEmail: String? = nil, deliveryStatus: EmailDelivery? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.memberId = memberId
        self.status = status; self.expiresAt = expiresAt; self.sendCount = sendCount
        self.email = email; self.sentAt = sentAt; self.acceptedEmail = acceptedEmail
        self.deliveryStatus = deliveryStatus
    }

    /// Expired is derived: pending past its expiry (the member stays
    /// `invited` on the backend).
    public func isExpired(at now: Date) -> Bool {
        status == .pending && expiresAt < now
    }
}

/// Result of `create_invite` / `resend_invite`. `token` and `code` are
/// readable exactly once: hand them to the email function or the owner.
public struct InviteLink: Codable, Hashable, Sendable {
    public let inviteId: String
    public let memberId: String
    public let token: String
    public let code: String
    public let link: String
    public let expiresAt: Date
    public let email: String?

    public init(
        inviteId: String, memberId: String, token: String, code: String, link: String,
        expiresAt: Date, email: String? = nil
    ) {
        self.inviteId = inviteId; self.memberId = memberId; self.token = token
        self.code = code; self.link = link; self.expiresAt = expiresAt; self.email = email
    }
}

/// One share of the invited member, shown before they accept.
public struct InviteShare: Codable, Hashable, Sendable {
    public let payoutMonthIndex: Int
    public let monthlyAmount: Money

    public init(payoutMonthIndex: Int, monthlyAmount: Money) {
        self.payoutMonthIndex = payoutMonthIndex; self.monthlyAmount = monthlyAmount
    }
}

/// Result of `preview_invite`: what the invitee sees on the accept screen.
public struct InvitePreview: Codable, Hashable, Sendable {
    public let inviteId: String
    public let status: String
    public let expired: Bool
    public let expiresAt: Date
    public let emailMatches: Bool
    public let kametiName: String
    public let ownerName: String
    public let memberName: String
    public let shares: [InviteShare]
    /// First day of month 1. `nil` from a backend without the
    /// `invite_preview_dates` migration.
    public let startMonth: Date?
    /// N, the number of months (and slots).
    public let monthsN: Int?

    public init(
        inviteId: String, status: String, expired: Bool, expiresAt: Date, emailMatches: Bool,
        kametiName: String, ownerName: String, memberName: String, shares: [InviteShare] = [],
        startMonth: Date? = nil, monthsN: Int? = nil
    ) {
        self.inviteId = inviteId; self.status = status; self.expired = expired
        self.expiresAt = expiresAt; self.emailMatches = emailMatches
        self.kametiName = kametiName; self.ownerName = ownerName
        self.memberName = memberName; self.shares = shares
        self.startMonth = startMonth; self.monthsN = monthsN
    }

    /// Still open: pending and not past its expiry.
    public var isOpen: Bool { status == "pending" && !expired }
}

/// Row of `list_my_invitations()`: live invites addressed to the signed-in
/// account's email.
public struct MyInvitation: Codable, Hashable, Identifiable, Sendable {
    public let inviteId: String
    public let kametiName: String
    public let ownerName: String
    public let memberName: String
    public let expiresAt: Date
    public let createdAt: Date

    public var id: String { inviteId }

    public init(
        inviteId: String, kametiName: String, ownerName: String, memberName: String,
        expiresAt: Date, createdAt: Date
    ) {
        self.inviteId = inviteId; self.kametiName = kametiName; self.ownerName = ownerName
        self.memberName = memberName; self.expiresAt = expiresAt; self.createdAt = createdAt
    }
}
