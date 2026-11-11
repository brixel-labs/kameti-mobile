import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Notes (board A2 · Notes tab, FR-70 to FR-72): All / Private / Shared,
/// search, and one card per note. Swipe a note left to edit, share or delete.
struct NotesTab: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let isSearching: Bool
    /// The one note whose swipe actions are showing (owned by `OwnerTabs`, so
    /// a tap anywhere or a tab change closes it).
    @Binding var openNote: String?

    @State private var filter = NoteLogic.Filter.all
    @State private var search = ""
    @State private var editing: Note?
    @State private var deleting: Note?
    @State private var failure: Failure?

    var body: some View {
        let list = NoteLogic.visible(data.notes, filter: filter, search: search, data: data)
        VStack(alignment: .leading, spacing: KSpace.md) {
            if isSearching {
                HStack(spacing: KSpace.sm) {
                    Image(systemName: "magnifyingglass").foregroundStyle(KColors.textSecondary)
                    TextField(String(localized: "Search notes", bundle: .module), text: $search)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: 44)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
            }
            HStack(spacing: KSpace.sm) {
                chip(.all, String(localized: "All · \(NoteLogic.count(data.notes, .all))", bundle: .module))
                chip(.private, String(localized: "Private · \(NoteLogic.count(data.notes, .private))", bundle: .module))
                chip(.shared, String(localized: "Shared · \(NoteLogic.count(data.notes, .shared))", bundle: .module))
            }
            if let failure {
                Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                    .kText(KTextToken.bodySm, color: KColors.negative)
            }
            if list.isEmpty {
                ContentUnavailableView(
                    data.notes.isEmpty ? String(localized: "No notes yet", bundle: .module) : String(localized: "No matching notes", bundle: .module),
                    systemImage: "note.text",
                    description: Text(data.notes.isEmpty
                        ? String(localized: "Keep track of promises, cash handovers and anything else. Private notes are only for you.", bundle: .module)
                        : String(localized: "Try another filter or search.", bundle: .module))
                )
                .padding(.top, KSpace.xl)
            } else {
                ForEach(list) { note in
                    KSwipeRow(id: note.id, openRow: $openNote, actions: [
                        KSwipeAction(String(localized: "Edit", bundle: .module), symbol: "pencil", tint: KColors.brand) { editing = note },
                        note.visibility == .private
                            ? KSwipeAction(String(localized: "Share with the people involved", bundle: .module), symbol: "person.2.fill", tint: KColors.info) { toggleVisibility(note) }
                            : KSwipeAction(String(localized: "Make private", bundle: .module), symbol: "lock.fill", tint: KColors.info) { toggleVisibility(note) },
                        KSwipeAction(String(localized: "Delete", bundle: .module), symbol: "trash.fill", tint: KColors.negative) { deleting = note },
                    ]) {
                        NoteCard(note: note, data: data)
                    }
                }
            }
        }
        .kBottomSheet(
            isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } }),
            title: String(localized: "Edit note", bundle: .module), detents: [.medium, .large]
        ) {
            if let note = editing { EditNoteSheet(note: note, model: model) { editing = nil }.id(note.id) }
        }
        .alert(
            String(localized: "Delete this note?", bundle: .module),
            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting
        ) { note in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Delete", bundle: .module), role: .destructive) {
                Task { failure = await model.deleteNote(id: note.id) }
            }
        } message: { _ in
            Text("It's removed for everyone who could see it. This can't be undone.", bundle: .module)
        }
    }

    private func chip(_ value: NoteLogic.Filter, _ title: String) -> some View {
        KChip(title, isOn: filter == value) { filter = value }
    }

    private func toggleVisibility(_ note: Note) {
        Task { failure = await model.updateNote(id: note.id, body: nil, visibility: note.visibility == .private ? .shared : .private) }
    }
}

/// One note: what it's about, private or shared, the day, then the text.
struct NoteCard: View {
    let note: Note
    let data: KametiDetailData

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            HStack(spacing: KSpace.sm) {
                Text("@ \(NoteLogic.targetLabel(note, data))")
                    .kText(KTextStyle(size: 12, weight: .semibold), color: KColors.onBrandSubtle)
                    .lineLimit(1)
                    .padding(.horizontal, KSpace.sm).padding(.vertical, 3)
                    .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: 6))
                VisibilityTag(visibility: note.visibility)
                Spacer(minLength: KSpace.sm)
                Text(NoteLogic.dayText(note.createdAt, today: data.today) + (note.isEdited ? String(localized: " · edited", bundle: .module) : ""))
                    .kText(KTextToken.caption, color: KColors.textSecondary)
                    .lineLimit(1)
            }
            Text(note.body).kText(KTextToken.body).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            if !data.isOwner, let author = note.authorName {
                Text("From \(author)", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
            }
        }
        .padding(KSpace.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(KColors.border))
    }
}

struct VisibilityTag: View {
    let visibility: NoteVisibility

    var body: some View {
        switch visibility {
        case .private:
            KPill(String(localized: "Private", bundle: .module), symbol: "lock.fill", foreground: KColors.textSecondary, background: KColors.surfaceSunken)
        case .shared:
            KPill(String(localized: "Shared", bundle: .module), symbol: "person.2.fill", foreground: KColors.info, background: KColors.infoSubtle)
        }
    }
}

/// The composer pinned under the Notes tab (board A2 · Notes): what the note
/// is about, private or shared, the text and Save.
struct NoteComposer: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel

    @State private var target = NoteLogic.kametiTarget()
    @State private var visibility = NoteVisibility.private
    @State private var text = ""
    @State private var isBusy = false
    @State private var failure: Failure?
    @FocusState private var focused: Bool

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            HStack(spacing: KSpace.sm) {
                Menu {
                    Button(NoteLogic.kametiTarget().label) { target = NoteLogic.kametiTarget() }
                    Section(String(localized: "Members", bundle: .module)) {
                        ForEach(NoteLogic.memberTargets(data), id: \.self) { item in Button(item.label) { target = item } }
                    }
                    Section(String(localized: "Months", bundle: .module)) {
                        ForEach(NoteLogic.slotTargets(data), id: \.self) { item in Button(item.label) { target = item } }
                    }
                } label: {
                    smallPill("@ \(target.label)", symbol: "chevron.down")
                }
                Button {
                    // One animation for the label, the pill's width and the
                    // hint line, so the composer grows and shrinks smoothly.
                    withAnimation(.smooth(duration: 0.3)) {
                        visibility = visibility == .private ? .shared : .private
                    }
                } label: {
                    smallPill(
                        visibility == .private ? String(localized: "Private", bundle: .module) : String(localized: "Shared", bundle: .module),
                        symbol: visibility == .private ? "lock.fill" : "person.2.fill"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Switches between private and shared", bundle: .module))
                Spacer(minLength: 0)
            }
            if visibility == .shared {
                Text(sharedHint).kText(KTextToken.caption, color: KColors.info)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            if let failure {
                Text(failure.userMessage).kText(KTextToken.caption, color: KColors.negative)
            }
            HStack(alignment: .bottom, spacing: KSpace.sm) {
                TextField(String(localized: "Write a note…", bundle: .module), text: $text, axis: .vertical)
                    // Typing a new line grows the box without a jump.
                    .animation(.smooth(duration: 0.2), value: text.count)
                    .lineLimit(1...5)
                    .focused($focused)
                    .padding(.horizontal, KSpace.md).padding(.vertical, 11)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
                Button(action: save) {
                    ZStack {
                        Image(systemName: "paperplane.fill").opacity(isBusy ? 0 : 1)
                        if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KColors.textOnBrand)
                    .frame(width: 44, height: 44)
                    .background(trimmed.isEmpty ? KColors.textTertiary : KColors.brand, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(trimmed.isEmpty || isBusy)
                .accessibilityLabel(Text("Save note", bundle: .module))
            }
        }
        .padding(.horizontal, KSpace.lg)
        .padding(.top, KSpace.md)
        .padding(.bottom, KSpace.sm)
        .background(KColors.surface)
        .overlay(alignment: .top) { Rectangle().fill(KColors.border).frame(height: 1) }
    }

    private var sharedHint: String {
        switch target.type {
        case .kameti: String(localized: "Every joined member will see this note.", bundle: .module)
        case .member: String(localized: "\(target.label) will see this note.", bundle: .module)
        case .slot: String(localized: "The people in the \(target.label) slot will see this note.", bundle: .module)
        case .payment, .payout: String(localized: "The person it's about will see this note.", bundle: .module)
        }
    }

    private func smallPill(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .labelStyle(TrailingIconLabelStyle(trailing: symbol == "chevron.down"))
            .contentTransition(.interpolate)
            .kText(KTextStyle(size: 13, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, KSpace.md).frame(minHeight: 32)
            .background(KColors.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(KColors.border))
            .contentShape(RoundedRectangle(cornerRadius: 8))
    }

    private func save() {
        let body = trimmed
        guard !body.isEmpty else { return }
        isBusy = true
        failure = nil
        Task {
            let result = await model.addNote(NewNote(body: body, visibility: visibility, targetType: target.type, targetId: target.id))
            isBusy = false
            if let result { failure = result } else { text = "" }
        }
    }
}

/// Puts a chevron after the title, other icons before it.
private struct TrailingIconLabelStyle: LabelStyle {
    let trailing: Bool
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            if trailing {
                configuration.title
                configuration.icon.font(.system(size: 10, weight: .bold))
            } else {
                configuration.icon.font(.system(size: 11, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                configuration.title
            }
        }
    }
}

/// Edit a note's text and who can see it.
struct EditNoteSheet: View {
    let note: Note
    let model: KametiDetailViewModel
    let onDone: () -> Void

    @State private var text: String
    @State private var visibility: NoteVisibility
    @State private var isBusy = false
    @State private var failure: Failure?

    init(note: Note, model: KametiDetailViewModel, onDone: @escaping () -> Void) {
        self.note = note
        self.model = model
        self.onDone = onDone
        _text = State(initialValue: note.body)
        _visibility = State(initialValue: note.visibility)
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var changed: Bool { trimmed != note.body || visibility != note.visibility }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                TextField(String(localized: "Note", bundle: .module), text: $text, axis: .vertical)
                    .lineLimit(3...10)
                    .padding(KSpace.md)
                    .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(KColors.border))
                KSegmented(
                    [(NoteVisibility.private, String(localized: "Private", bundle: .module)), (.shared, String(localized: "Shared", bundle: .module))],
                    selection: $visibility
                )
                Text(visibility == .private
                     ? String(localized: "Only you can see private notes.", bundle: .module)
                     : String(localized: "The members this note is about can see it.", bundle: .module))
                    .kText(KTextToken.caption, color: KColors.textSecondary)
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
                }
                Button(action: save) {
                    ZStack {
                        Text("Save note", bundle: .module).opacity(isBusy ? 0 : 1)
                        if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                    }
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(KColors.brand)
                .controlSize(.large)
                .disabled(!changed || trimmed.isEmpty || isBusy)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
    }

    private func save() {
        isBusy = true
        failure = nil
        Task {
            let result = await model.updateNote(
                id: note.id, body: trimmed == note.body ? nil : trimmed, visibility: visibility == note.visibility ? nil : visibility
            )
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}
