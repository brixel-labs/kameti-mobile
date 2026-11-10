import Foundation
import KametiCore

/// Row of `public.audit_log` (FR-90). The owner reads every entry of a kameti;
/// a joined member reads the entries about themselves (row-level security).
public struct AuditEntry: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let kametiId: String
    public let action: String
    public let entity: String
    public let at: Date
    public let memberId: String?
    public let actorId: String?
    public let entityId: String?
    public let before: [String: JSONValue]?
    public let after: [String: JSONValue]?

    public init(
        id: Int, kametiId: String, action: String, entity: String, at: Date,
        memberId: String? = nil, actorId: String? = nil, entityId: String? = nil,
        before: [String: JSONValue]? = nil, after: [String: JSONValue]? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.action = action; self.entity = entity
        self.at = at; self.memberId = memberId; self.actorId = actorId
        self.entityId = entityId; self.before = before; self.after = after
    }
}

/// Row of `public.profiles`: the signed-in user's own profile.
public struct Profile: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let avatarUrl: String?

    public init(id: String, displayName: String, avatarUrl: String? = nil) {
        self.id = id; self.displayName = displayName; self.avatarUrl = avatarUrl
    }
}

/// Row of `public.contacts`: one person in the owner's private "My people"
/// list. Only the owner can read it; members never see it.
public struct Contact: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let ownerId: String
    public let name: String
    public let email: String?
    public let phone: String?
    public let note: String?

    public init(
        id: String, ownerId: String, name: String, email: String? = nil,
        phone: String? = nil, note: String? = nil
    ) {
        self.id = id; self.ownerId = ownerId; self.name = name
        self.email = email; self.phone = phone; self.note = note
    }
}
