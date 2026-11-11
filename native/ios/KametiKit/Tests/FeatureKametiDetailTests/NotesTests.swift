import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// Notes against the demo store, which follows the backend's rules: the owner
/// sees and writes everything; a member sees only shared notes about them or
/// the whole kameti (FR-70 to FR-72).
@MainActor
@Suite("Notes")
struct NotesTests {
    private func loaded(_ id: String) async -> (KametiDetailViewModel, () -> KametiDetailData?) {
        let model = KametiDetailViewModel(kametiId: id, userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        return (model, {
            if case .loaded(let data) = model.state { return data }
            return nil
        })
    }

    @Test func theOwnerSeesEveryNoteNewestFirst() async throws {
        let (_, data) = await loaded("family")
        let current = try #require(data())
        #expect(current.notes.map(\.id) == ["n1", "n2", "n3", "n4"])
        #expect(NoteLogic.count(current.notes, .private) == 2)
        #expect(NoteLogic.count(current.notes, .shared) == 2)
        #expect(NoteLogic.targetLabel(current.notes[0], current) == "Ali Raza")
        #expect(NoteLogic.targetLabel(current.notes[2], current) == "October payout")
        #expect(NoteLogic.targetLabel(current.notes[3], current) == "Kameti")
    }

    @Test func aMemberSeesOnlySharedNotesAboutThemOrTheKameti() async throws {
        let (_, data) = await loaded("office")
        let current = try #require(data())
        // Not the private one, and not the shared one about Zainab.
        #expect(Set(current.notes.map(\.id)) == ["o-n1", "o-n2"])
    }

    @Test func filterAndSearch() async throws {
        let (_, data) = await loaded("family")
        let current = try #require(data())
        #expect(NoteLogic.visible(current.notes, filter: .shared, search: "", data: current).map(\.id) == ["n2", "n4"])
        #expect(NoteLogic.visible(current.notes, filter: .all, search: "meezan", data: current).map(\.id) == ["n4"])
        // The search also matches what a note is about.
        #expect(NoteLogic.visible(current.notes, filter: .all, search: "october payout", data: current).map(\.id) == ["n3"])
    }

    @Test func addEditShareAndDelete() async throws {
        let (model, data) = await loaded("family")
        #expect(await model.addNote(NewNote(body: "  Faisal will pay by cheque  ", targetType: .member, targetId: "f6")) == nil)
        let added = try #require(data()?.notes.first)
        #expect(added.body == "Faisal will pay by cheque")
        #expect(added.visibility == .private)
        #expect(added.targetId == "f6")

        #expect(await model.updateNote(id: added.id, body: nil, visibility: .shared) == nil)
        let shared = try #require(data()?.notes.first { $0.id == added.id })
        #expect(shared.visibility == .shared)
        #expect(shared.isEdited)

        #expect(await model.deleteNote(id: added.id) == nil)
        #expect(data()?.notes.contains { $0.id == added.id } == false)
    }

    @Test func badNotesAreRefused() async {
        let (model, _) = await loaded("family")
        #expect(await model.addNote(NewNote(body: "   ")) == .server(code: "invalid_note_body", detail: nil))
        #expect(await model.addNote(NewNote(body: "x", targetType: .member, targetId: "nobody")) == .server(code: "target_not_found", detail: nil))
        #expect(await model.updateNote(id: "n1", body: nil, visibility: nil) == .server(code: "nothing_to_change", detail: nil))
    }

    @Test func aMemberCantWriteNotes() async {
        let (model, _) = await loaded("office")
        #expect(await model.addNote(NewNote(body: "hello")) == .server(code: "not_kameti_owner", detail: nil))
    }

    @Test func dayText() {
        let today = DateOnly.make(year: 2026, month: 11, day: 10)
        #expect(NoteLogic.dayText(today.addingTimeInterval(8 * 3600), today: today) == "Today")
        #expect(NoteLogic.dayText(today.addingTimeInterval(-10 * 3600), today: today) == "Yesterday")
        let third = DateOnly.make(year: 2026, month: 11, day: 3)
        #expect(NoteLogic.dayText(third.addingTimeInterval(8 * 3600), today: today) == DetailLogic.dayMonth(third))
    }
}
