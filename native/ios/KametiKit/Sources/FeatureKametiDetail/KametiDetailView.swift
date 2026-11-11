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

    public init(model: KametiDetailViewModel, onResumeDraft: ((String) -> Void)? = nil) {
        self.model = model
        self.onResumeDraft = onResumeDraft
    }

    public var body: some View {
        Group {
            switch model.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let failure):
                ContentUnavailableView {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button(String(localized: "Try again", bundle: .module)) { Task { await model.load() } }
                }
            case .loaded(let data):
                loaded(data)
            }
        }
        .background(KColors.background)
        .navigationTitle(title)
        .navigationSubtitle(subtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
