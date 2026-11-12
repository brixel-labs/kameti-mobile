import Foundation
import KametiCore
import KametiDomain
import Supabase

/// Notes through the backend's RPCs (migration `notes`): `list_notes` reads
/// what the caller may see, and only the owner can add, edit or delete.
public final class SupabaseNotesRepository: NotesRepository {
    private let client: SupabaseClient

    public init(client: SupabaseClient) { self.client = client }

    public func notes(kametiId: String) async throws(Failure) -> [Note] {
        try await run {
            try await client.rpc("list_notes", params: ["p_kameti_id": JSONValue.string(kametiId)]).execute().value
        }
    }

    public func addNote(kametiId: String, _ new: NewNote) async throws(Failure) -> Note {
        try await run {
            try await client.rpc("add_note", params: Params.addNote(kametiId: kametiId, new)).execute().value
        }
    }

    public func updateNote(id: String, body: String?, visibility: NoteVisibility?) async throws(Failure) -> Note {
        try await run {
            try await client.rpc("update_note", params: Params.updateNote(id: id, body: body, visibility: visibility)).execute().value
        }
    }

    public func deleteNote(id: String) async throws(Failure) {
        try await run {
            _ = try await client.rpc("delete_note", params: ["p_note_id": JSONValue.string(id)]).execute()
        }
    }
}
