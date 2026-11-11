import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// One kameti: the owner's tabs or the member's read-only view. Owner or
/// member is decided once, from the loaded kameti; the member branch builds
/// no write controls at all.
public struct KametiDetailView: View {
    private let model: KametiDetailViewModel
    private let onResumeDraft: ((String) -> Void)?
    private let onOpenActivity: ((String) -> Void)?
    @State private var editing = false
    @State private var confirmingArchive = false
    @State private var confirmingDuplicate = false
    @State private var duplicating = false
    @State private var archiveFailure: Failure?

    public init(model: KametiDetailViewModel, onResumeDraft: ((String) -> Void)? = nil, onOpenActivity: ((String) -> Void)? = nil) {
        self.model = model
        self.onResumeDraft = onResumeDraft
        self.onOpenActivity = onOpenActivity
    }

    public var body: some View {
        Group {
            switch model.state {
            case .loading:
                ScrollView {
                    VStack(spacing: KSpace.md) { KSkeletonRows(rows: 2); KSkeletonRows(rows: 4) }
                        .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            case .failed(let failure):
                ScrollView {
                    KMessageCard(
                        String(localized: "Couldn't load this kameti", bundle: .module), message: failure.helpMessage,
                        actionTitle: String(localized: "Try again", bundle: .module)
                    ) { Task { await model.load() } }
                    .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            case .loaded(let data):
                loaded(data)
                    // Offline: the last loaded data stays, with a note on how old it is.
                    .safeAreaInset(edge: .top, spacing: 0) {
                        if !KConnectivity.shared.isOnline {
                            KOfflineBanner(since: model.loadedAt)
                                .padding(.horizontal, KSpace.xl).padding(.vertical, KSpace.sm)
                                .background(KColors.background)
                        }
                    }
            }
        }
        .background(KColors.background)
        .navigationTitle(title)
        .navigationSubtitle(subtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The owner's ••• menu (board AE-2): Edit, Activity, Archive / Restore.
            if case .loaded(let data) = model.state, data.kameti.status != .draft, data.isOwner || onOpenActivity != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if data.isOwner, data.kameti.status == .active {
                            Button { editing = true } label: {
                                Label(String(localized: "Edit kameti", bundle: .module), systemImage: "pencil")
                            }
                        }
                        if let onOpenActivity {
                            Button { onOpenActivity(data.kameti.id) } label: {
                                Label(data.isOwner ? String(localized: "Activity", bundle: .module) : String(localized: "Your activity", bundle: .module), systemImage: "clock.arrow.circlepath")
                            }
                        }
                        if data.isOwner, onResumeDraft != nil {
                            Button { confirmingDuplicate = true } label: {
                                Label(String(localized: "Duplicate kameti", bundle: .module), systemImage: "plus.square.on.square")
                            }
                            .disabled(duplicating)
                        }
                        if data.isOwner {
                            if data.kameti.status == .archived {
                                Button { restore() } label: {
                                    Label(String(localized: "Restore kameti", bundle: .module), systemImage: "arrow.uturn.backward")
                                }
                            } else {
                                Divider()
                                Button(role: .destructive) { confirmingArchive = true } label: {
                                    Label(String(localized: "Archive kameti", bundle: .module), systemImage: "archivebox")
                                }
                                // The app tint would keep the icon green; match the red title.
                                .tint(KColors.negative)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel(Text("More", bundle: .module))
                }
            }
            if case .loaded(let data) = model.state, !data.isOwner {
                // A label, not a button: the same "View only" pill as the Home
                // card, without the toolbar's glass button behind it.
                ToolbarItem(placement: .topBarTrailing) {
                    KPill(String(localized: "View only", bundle: .module), foreground: KColors.textSecondary, background: KColors.surfaceSunken)
                        .accessibilityLabel(Text("View only: only the owner can make changes", bundle: .module))
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
        .task { await model.load() }
        .alert(
            String(localized: "Archive \(title)?", bundle: .module),
            isPresented: $confirmingArchive
        ) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Archive", bundle: .module), role: .destructive) { archive() }
        } message: {
            Text("It becomes read-only for you and every member and moves to Archived, at the end of Past on Home. You can restore it any time.", bundle: .module)
        }
        .alert(
            String(localized: "Duplicate \(title)?", bundle: .module),
            isPresented: $confirmingDuplicate
        ) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Duplicate", bundle: .module)) { duplicate() }
        } message: {
            Text("A new draft with the same members, shares and payout order, and no payments. You can change the name and dates before you start it.", bundle: .module)
        }
        .alert(
            String(localized: "Couldn't change this kameti", bundle: .module),
            isPresented: Binding(get: { archiveFailure != nil }, set: { if !$0 { archiveFailure = nil } })
        ) {
            Button(String(localized: "OK", bundle: .module)) {}
        } message: {
            Text(archiveFailure.map { Self.message(for: $0) } ?? "")
        }
        .kBottomSheet(isPresented: $editing, title: String(localized: "Edit kameti", bundle: .module), detents: [.large]) {
            if case .loaded(let data) = model.state {
                EditKametiView(data: data, model: model) { editing = false }
            }
        }
    }

    private func archive() {
        Task { archiveFailure = await model.archive() }
    }

    private func duplicate() {
        duplicating = true
        Task {
            defer { duplicating = false }
            switch await model.duplicate() {
            case .success(let id): onResumeDraft?(id)
            case .failure(let failure): archiveFailure = failure
            }
        }
    }

    private func restore() {
        Task { archiveFailure = await model.restore() }
    }

    nonisolated static func message(for failure: Failure) -> String {
        if case .server(let code, _) = failure, code == "kameti_name_taken" {
            return String(localized: "You already have a running kameti with this name. Rename that one first, then restore this.", bundle: .module)
        }
        return failure.userMessage
    }

    /// The kameti to name the screen after: the loaded one, else what Home passed.
    private var known: Kameti? {
        if case .loaded(let data) = model.state { return data.kameti }
        return model.preview
    }

    private var subtitle: String {
        guard let kameti = known else { return "" }
        return String(localized: "\(kameti.monthsN) months · \(kameti.slotAmountC.format()) per slot", bundle: .module)
    }

    private var title: String {
        known?.name ?? String(localized: "Kameti", bundle: .module)
    }

    @ViewBuilder
    private func loaded(_ data: KametiDetailData) -> some View {
        // Pull to refresh sits on the page content only: on the whole screen
        // it would also attach to the owner's sideways tab row.
        if !data.isOwner {
            MemberView(data: data)
                .refreshable { await model.load() }
        } else if data.kameti.status == .draft {
            ContentUnavailableView {
                Label(String(localized: "This kameti is a draft", bundle: .module), systemImage: "pencil.and.list.clipboard")
            } description: {
                Text("Finish setting it up to start collecting.", bundle: .module)
            } actions: {
                if let onResumeDraft {
                    Button(String(localized: "Continue setting up", bundle: .module)) { onResumeDraft(data.kameti.id) }
                        .buttonStyle(.glassProminent)
                        .tint(KColors.brand)
                }
            }
        } else {
            OwnerTabs(data: data, model: model)
        }
    }
}
