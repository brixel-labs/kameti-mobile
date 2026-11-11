import Foundation
import KametiCore
import KametiDomain
import KametiUI
import Observation
import SwiftUI

/// Loads a kameti's activity (FR-90). Row-level security decides what comes
/// back: everything for the owner, only the entries about them for a member.
@MainActor
@Observable
public final class ActivityViewModel {
    public enum State: Equatable, Sendable {
        case loading
        case loaded
        case failed(Failure)
    }

    public private(set) var state = State.loading
    private(set) var items: [ActivityItem] = []
    public private(set) var kametiName: String?
    public private(set) var isOwner = false

    private let kametiId: String
    private let userId: String
    private let dependencies: KametiDependencies

    public init(kametiId: String, userId: String, dependencies: KametiDependencies) {
        self.kametiId = kametiId
        self.userId = userId
        self.dependencies = dependencies
    }

    public func load() async {
        do throws(Failure) {
            let kameti = try await dependencies.kametis.kameti(id: kametiId)
            let members = try await dependencies.kametis.members(kametiId: kametiId)
            let slots = (try? await dependencies.kametis.slots(kametiId: kametiId)) ?? []
            let entries = try await dependencies.audit.audit(kametiId: kametiId, limit: 300)
            kametiName = kameti.name
            isOwner = kameti.isOwned(by: userId)
            items = ActivityLogic.items(entries, ActivityLogic.Context(members: members, slots: slots, kameti: kameti))
            state = .loaded
        } catch {
            if state != .loaded { state = .failed(error) }
        }
    }

    /// "Today" for the day headers, from the app clock (fixed in the demo).
    var today: Date { DetailLogic.pakistanToday(dependencies.clock.now()) }
}

/// Activity (board AL-1 with AL-2's before → after lines): filter chips and
/// rows grouped by day.
public struct ActivityView: View {
    private let model: ActivityViewModel
    @State private var filter = ActivityLogic.Filter.all

    public init(model: ActivityViewModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            switch model.state {
            case .loading:
                ScrollView { KSkeletonRows(rows: 5).padding(.horizontal, KSpace.xl).padding(.top, KSpace.md) }
            case .failed(let failure):
                ScrollView {
                    KMessageCard(
                        String(localized: "Couldn't load the activity", bundle: .module), message: failure.helpMessage,
                        actionTitle: String(localized: "Try again", bundle: .module)
                    ) { Task { await model.load() } }
                    .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            case .loaded:
                list
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Activity", bundle: .module))
        .navigationSubtitle(model.kametiName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
    }

    private var list: some View {
        let shown = ActivityLogic.filtered(model.items, filter)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                HStack(spacing: KSpace.sm) {
                    chip(.all, String(localized: "All", bundle: .module))
                    chip(.money, String(localized: "Money", bundle: .module))
                    chip(.members, String(localized: "Members", bundle: .module))
                    chip(.changes, String(localized: "Changes", bundle: .module))
                }
                .padding(.bottom, KSpace.sm)
                if shown.isEmpty {
                    ContentUnavailableView(
                        String(localized: "Nothing here yet", bundle: .module), systemImage: "clock",
                        description: Text(model.isOwner
                            ? String(localized: "Payments, payouts, member changes and edits show up here.", bundle: .module)
                            : String(localized: "Payments and changes that involve you show up here.", bundle: .module))
                    )
                    .padding(.top, KSpace.xl)
                } else {
                    ForEach(ActivityLogic.byDay(shown), id: \.day) { group in
                        Text(dayTitle(group.day))
                            .kText(KTextToken.label, color: KColors.textSecondary)
                            .textCase(.uppercase)
                            .padding(.top, KSpace.lg)
                            .padding(.bottom, KSpace.xs)
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                            ActivityRow(item: item, showsDivider: index < group.items.count - 1)
                        }
                    }
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.md)
            .padding(.bottom, KSpace.xl)
            .animation(.smooth(duration: 0.25), value: filter)
        }
        .refreshable { await model.load() }
    }

    private func chip(_ value: ActivityLogic.Filter, _ title: String) -> some View {
        KChip(title, isOn: filter == value) { filter = value }
    }

    private func dayTitle(_ day: Date) -> String {
        if day == model.today { return String(localized: "Today", bundle: .module) }
        if day.addingTimeInterval(86_400) == model.today { return String(localized: "Yesterday", bundle: .module) }
        return DetailLogic.dayMonth(day)
    }
}

/// One activity row: a coloured icon, what happened, a summary, any
/// before → after lines, and the time.
struct ActivityRow: View {
    let item: ActivityItem
    let showsDivider: Bool

    private var colors: (Color, Color) {
        switch item.tone {
        case .positive: (KColors.positive, KColors.positiveSubtle)
        case .negative: (KColors.negative, KColors.negativeSubtle)
        case .info: (KColors.info, KColors.infoSubtle)
        case .warning: (KColors.warning, KColors.warningSubtle)
        case .brand: (KColors.brand, KColors.brandSubtle)
        case .neutral: (KColors.textSecondary, KColors.surfaceSunken)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: KSpace.md) {
                Image(systemName: item.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(colors.0)
                    .frame(width: 38, height: 38)
                    .background(colors.1, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title).kText(KTextToken.bodyStrong)
                    if let detail = item.detail, !detail.isEmpty {
                        Text(detail).kText(KTextToken.bodySm, color: KColors.textSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(item.changes, id: \.label) { change in
                        HStack(spacing: KSpace.xs) {
                            Text(change.label).kText(KTextToken.caption, color: KColors.textSecondary)
                            Text(change.before).kText(KTextToken.caption, color: KColors.textSecondary).strikethrough()
                            Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold)).foregroundStyle(KColors.textTertiary)
                            Text(change.after).kText(KTextStyle(size: 12, weight: .semibold))
                        }
                        .lineLimit(1)
                        .padding(.horizontal, KSpace.sm).padding(.vertical, 5)
                        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 2)
                    }
                }
                Spacer(minLength: KSpace.sm)
                Text(ActivityLogic.time(item.at)).kText(KTextToken.caption, color: KColors.textSecondary).lineLimit(1)
            }
            .padding(.vertical, KSpace.md)
            if showsDivider { Divider() }
        }
        .accessibilityElement(children: .combine)
    }
}
