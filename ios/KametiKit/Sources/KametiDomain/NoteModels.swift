import Foundation
import KametiCore

/// What a note is about (`public.note_target`).
public enum NoteTarget: String, Codable, Hashable, Sendable, CaseIterable {
    case kameti, member, slot, payment, payout
}

/// Who can read a note (`public.note_visibility`, FR-71): the owner only, or
/// also the members involved.
public enum NoteVisibility: String, Codable, Hashable, Sendable {
    case `private`, shared
}

/// A row of `list_notes()` (FR-70 to FR-72): a note with its author's name.
public struct Note: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let kametiId: String
    public let targetType: NoteTarget
    /// `nil` for a kameti-wide note.
    public let targetId: String?
    public let body: String
    public let visibility: NoteVisibility
    public let authorId: String?
    public let authorName: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: String, kametiId: String, targetType: NoteTarget = .kameti, targetId: String? = nil, body: String,
        visibility: NoteVisibility = .private, authorId: String? = nil, authorName: String? = nil,
        createdAt: Date, updatedAt: Date? = nil
    ) {
        self.id = id; self.kametiId = kametiId; self.targetType = targetType; self.targetId = targetId
        self.body = body; self.visibility = visibility; self.authorId = authorId; self.authorName = authorName
        self.createdAt = createdAt; self.updatedAt = updatedAt ?? createdAt
    }

    /// Edited after it was written.
    public var isEdited: Bool { updatedAt > createdAt }
}

/// Input for `add_note`.
public struct NewNote: Sendable {
    public var body: String
    public var visibility: NoteVisibility
    public var targetType: NoteTarget
    public var targetId: String?

    public init(body: String, visibility: NoteVisibility = .private, targetType: NoteTarget = .kameti, targetId: String? = nil) {
        self.body = body; self.visibility = visibility; self.targetType = targetType; self.targetId = targetId
    }
}

/// Notes on a kameti. Writes are owner only; reads follow FR-71.
public protocol NotesRepository: Sendable {
    /// Newest first. Members get only the shared notes they're involved in.
    func notes(kametiId: String) async throws(Failure) -> [Note]
    func addNote(kametiId: String, _ new: NewNote) async throws(Failure) -> Note
    /// `nil` leaves a field unchanged.
    func updateNote(id: String, body: String?, visibility: NoteVisibility?) async throws(Failure) -> Note
    func deleteNote(id: String) async throws(Failure)
}

/// The default when no notes backend is wired (older test setups): every
/// call fails, and screens treat notes as unavailable.
public struct UnavailableNotesRepository: NotesRepository {
    public init() {}
    private var failure: Failure { .unknown(description: "notes are not available") }
    public func notes(kametiId: String) async throws(Failure) -> [Note] { throw failure }
    public func addNote(kametiId: String, _ new: NewNote) async throws(Failure) -> Note { throw failure }
    public func updateNote(id: String, body: String?, visibility: NoteVisibility?) async throws(Failure) -> Note { throw failure }
    public func deleteNote(id: String) async throws(Failure) { throw failure }
}
