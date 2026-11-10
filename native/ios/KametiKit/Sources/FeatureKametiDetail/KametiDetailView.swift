import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// One kameti: the owner's tabs or the member's read-only view. Owner or
/// member is decided once, from the loaded kameti; the member branch builds
/// no write controls at all.
public struct KametiDetailView: View {
    private let model: KametiDetailViewModel

    public init(model: KametiDetailViewModel) {
        self.model = model
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
                ToolbarItem(placement: .topBarTrailing) {
                    Label(String(localized: "View only", bundle: .module), systemImage: "eye")
                        .kText(KTextStyle(size: 12, weight: .semibold), color: KColors.textSecondary)
                        .padding(.horizontal, KSpace.sm)
                }
            }
        }
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private var subtitle: String {
        guard case .loaded(let data) = model.state else { return "" }
        return String(localized: "\(data.kameti.monthsN) months · \(data.kameti.slotAmountC.format()) per slot", bundle: .module)
    }

    private var title: String {
        if case .loaded(let data) = model.state { return data.kameti.name }
        return String(localized: "Kameti", bundle: .module)
    }

    @ViewBuilder
    private func loaded(_ data: KametiDetailData) -> some View {
        if !data.isOwner {
            MemberView(data: data)
        } else if data.kameti.status == .draft {
            ContentUnavailableView(
                String(localized: "This kameti is a draft", bundle: .module), systemImage: "pencil.and.list.clipboard",
                description: Text("Finish setting it up to start collecting.", bundle: .module)
            )
        } else {
            OwnerTabs(data: data)
        }
    }
}
