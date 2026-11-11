import Foundation
import KametiCore
import KametiDomain
import Synchronization

/// The demo's notes, with the backend's rules (FR-70 to FR-72): the owner
/// reads and writes everything; a member reads only shared notes they're
/// involved in (any kameti-wide note, a note on themselves, on a slot they
/// share, or on their own payment or payout).
final class SampleNotesRepository: NotesRepository {
    private let kametis: SampleKametiRepository
    private let payments: SamplePaymentStore
    private let log: SampleAuditLog
    private let state: Mutex<(notes: [Note], counter: Int)>

    init(kametis: SampleKametiRepository, payments: SamplePaymentStore, log: SampleAuditLog = SampleAuditLog()) {
        self.kametis = kametis
        self.payments = payments
        self.log = log
        let day: TimeInterval = 86_400
        let now = SampleData.now
        func note(_ id: String, _ kameti: String, _ target: NoteTarget, _ targetId: String?, _ visibility: NoteVisibility, _ author: String, _ ago: TimeInterval, _ body: String) -> Note {
            Note(id: id, kametiId: kameti, targetType: target, targetId: targetId, body: body, visibility: visibility,
                 authorId: author, authorName: SampleData.ownerNames[author], createdAt: now - ago)
        }
        state = Mutex((notes: [
            note("n1", "family", .member, "f1", .private, SampleData.userId, 2 * 3600,
                 "Ali is travelling until the 12th and will pay November when he's back."),
            note("n2", "family", .member, "f2", .shared, SampleData.userId, 7 * day,
                 "Sara's extra Rs 2,50,000 in October counts as credit for November."),
            note("n3", "family", .slot, "fs1", .private, SampleData.userId, 29 * day,
                 "October's payout was handed to Ali in cash at home."),
            note("n4", "family", .kameti, nil, .shared, SampleData.userId, 40 * day,
                 "Payments by the 10th please. Bank: Meezan, account details in the family group."),
            note("o-n1", "office", .kameti, nil, .shared, "someone-else", 5 * day,
                 "From December, bank transfers only please, no cash."),
            note("o-n2", "office", .member, "o2", .shared, "someone-else", 3 * day,
                 "Your October payment came in on the 7th, thanks."),
            note("o-n3", "office", .member, "o3", .shared, "someone-else", 3 * day,
                 "Zainab paid November early."),
            note("o-n4", "office", .kameti, nil, .private, "someone-else", 1 * day,
                 "Remind Usman about the shortfall."),
        ], counter: 0))
    }

    func notes(kametiId: String) async throws(Failure) -> [Note] {
        guard let kameti = kametis.kametiRow(kametiId) else { throw Failure.server(code: "not_kameti_member", detail: nil) }
        let all = state.withLock { $0.notes.filter { $0.kametiId == kametiId } }
        let visible = kameti.ownerId == SampleData.userId ? all : all.filter { canMemberRead($0) }
        return visible.sorted { $0.createdAt > $1.createdAt }
    }

    func addNote(kametiId: String, _ new: NewNote) async throws(Failure) -> Note {
        guard let kameti = kametis.kametiRow(kametiId) else { throw Failure.server(code: "not_found", detail: nil) }
        guard kameti.ownerId == SampleData.userId else { throw Failure.server(code: "not_kameti_owner", detail: nil) }
        let body = try clean(new.body)
        if new.targetType != .kameti {
            guard let id = new.targetId, exists(new.targetType, id, in: kametiId) else { throw Failure.server(code: "target_not_found", detail: nil) }
        }
        return state.withLock { s in
            s.counter += 1
            let created = Note(
                id: "n-new-\(s.counter)", kametiId: kametiId, targetType: new.targetType,
                targetId: new.targetType == .kameti ? nil : new.targetId, body: body, visibility: new.visibility,
                authorId: SampleData.userId, authorName: SampleData.ownerNames[SampleData.userId],
                createdAt: SampleData.now + TimeInterval(s.counter)
            )
            s.notes.append(created)
            log.record(kametiId, "note.add", entity: "note", entityId: created.id, member: nil, after: .object(["body": .string(body)]))
            return created
        }
    }

    func updateNote(id: String, body: String?, visibility: NoteVisibility?) async throws(Failure) -> Note {
        guard body != nil || visibility != nil else { throw Failure.server(code: "nothing_to_change", detail: nil) }
        let cleaned = try body.map { (text: String) throws(Failure) -> String in try clean(text) }
        let old = try ownedNote(id)
        let new = Note(
            id: old.id, kametiId: old.kametiId, targetType: old.targetType, targetId: old.targetId, body: cleaned ?? old.body,
            visibility: visibility ?? old.visibility, authorId: old.authorId, authorName: old.authorName,
            createdAt: old.createdAt, updatedAt: max(old.createdAt + 1, SampleData.now)
        )
        state.withLock { s in if let index = s.notes.firstIndex(where: { $0.id == id }) { s.notes[index] = new } }
        log.record(old.kametiId, "note.update", entity: "note", entityId: id, member: nil,
                   before: .object(["body": .string(old.body)]), after: .object(["body": .string(new.body)]))
        return new
    }

    func deleteNote(id: String) async throws(Failure) {
        let old = try ownedNote(id)
        state.withLock { $0.notes.removeAll { $0.id == id } }
        log.record(old.kametiId, "note.delete", entity: "note", entityId: id, member: nil, before: .object(["body": .string(old.body)]))
    }

    // MARK: Helpers

    private func ownedNote(_ id: String) throws(Failure) -> Note {
        guard let note = state.withLock({ $0.notes.first { $0.id == id } }) else { throw Failure.server(code: "not_found", detail: nil) }
        guard kametis.kametiRow(note.kametiId)?.ownerId == SampleData.userId else { throw Failure.server(code: "not_kameti_owner", detail: nil) }
        return note
    }

    private func clean(_ body: String) throws(Failure) -> String {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...2000).contains(text.count) else { throw Failure.server(code: "invalid_note_body", detail: nil) }
        return text
    }

    private func exists(_ target: NoteTarget, _ id: String, in kametiId: String) -> Bool {
        switch target {
        case .kameti: true
        case .member: kametis.memberRow(id)?.kametiId == kametiId
        case .slot: kametis.slotRow(id)?.kametiId == kametiId
        case .payment: payments.all(kametiId).contains { $0.id == id }
        case .payout: payments.payouts(kametiId).contains { $0.id == id }
        }
    }

    /// FR-71 for a member of someone else's kameti.
    private func canMemberRead(_ note: Note) -> Bool {
        guard note.visibility == .shared else { return false }
        let me = kametis.myMember(in: note.kametiId)
        guard let me, me.joinStatus == .joined else { return false }
        switch note.targetType {
        case .kameti: return true
        case .member: return note.targetId == me.id
        case .slot: return kametis.shareRows(memberId: me.id, kametiId: note.kametiId).contains { $0.share.slotId == note.targetId }
        case .payment: return payments.all(note.kametiId).contains { $0.id == note.targetId && $0.memberId == me.id }
        case .payout: return payments.payouts(note.kametiId).contains { $0.id == note.targetId && $0.memberId == me.id }
        }
    }
}
