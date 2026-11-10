import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Home (boards Main, AF-Empty-Home, AD-Home): "Running by me", "I'm a
/// member" and "Past", or the first-time empty state.
public struct HomeView: View {
    private let model: HomeViewModel
    private let onOpen: (String) -> Void
    private let onCreate: () -> Void
    private let onJoin: (String) -> Void

    public init(
        model: HomeViewModel,
        onOpen: @escaping (String) -> Void,
        onCreate: @escaping () -> Void,
        onJoin: @escaping (String) -> Void
    ) {
        self.model = model
        self.onOpen = onOpen
        self.onCreate = onCreate
        self.onJoin = onJoin
    }

    public var body: some View {
        Group {
            if !model.hasLoaded {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let failure = model.failure, model.sections.isEmpty {
                ContentUnavailableView {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                } actions: {
                    Button(String(localized: "Try again", bundle: .module)) { Task { await model.load() } }
                }
            } else {
                list
            }
        }
        .background(KColors.background)
        .navigationTitle(String(localized: "Kameti", bundle: .module))
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: KSpace.md) {
                if model.sections.isEmpty {
                    KCard {
                        VStack(spacing: KSpace.md) {
                            Image(systemName: "circle.dashed")
                                .font(.system(size: 40)).foregroundStyle(KColors.textTertiary)
                                .accessibilityHidden(true)
                            Text("No kametis yet", bundle: .module).kText(KTextToken.title)
                            Text("Start one for your family, office or friends. Or join one you've been invited to.", bundle: .module)
                                .kText(KTextToken.body, color: KColors.textSecondary)
                                .multilineTextAlignment(.center)
                            startButton
                        }
                        .frame(maxWidth: .infinity)
                    }
                    InviteCodeCard(onJoin: onJoin)
                }
                // "New kameti" sits on the first group's header.
                let hasMine = !model.sections.mine.isEmpty
                group(String(localized: "Running by me", bundle: .module), model.sections.mine, showsNew: true)
                group(String(localized: "I'm a member", bundle: .module), model.sections.joined, showsNew: !hasMine)
                group(String(localized: "Past", bundle: .module), model.sections.past)
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
    }

    private var startButton: some View {
        Button(action: onCreate) {
            Label(String(localized: "Start a kameti", bundle: .module), systemImage: "plus")
                .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(KColors.brand)
        .controlSize(.large)
    }

    @ViewBuilder
    private func group(_ title: String, _ items: [HomeKametiSummary], showsNew: Bool = false) -> some View {
        if !items.isEmpty {
            KSectionHeader(
                title,
                actionTitle: showsNew ? String(localized: "New kameti", bundle: .module) : nil,
                action: showsNew ? onCreate : nil
            )
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { HomeKametiCard(item: item) }
                    .buttonStyle(.plain)
            }
        }
    }
}

/// A kameti on Home (FR-2): name, role, "Month 2 of 20", this month's pot
/// and, for a kameti I'm a member of, what I owe.
struct HomeKametiCard: View {
    let item: HomeKametiSummary

    var body: some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.md) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: KSpace.xs) {
                        Text(item.kameti.name).kText(KTextToken.title)
                        Text(subtitle).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    }
                    Spacer(minLength: KSpace.sm)
                    rolePill
                }
                if let month = item.currentMonth {
                    KPotProgress(
                        collected: month.received, target: month.target,
                        caption: String(localized: "\(month.paidCount) of \(month.memberCount) paid", bundle: .module)
                    )
                }
                if !item.isOwner, let owes = item.owes {
                    if owes.isPositive {
                        Label(String(localized: "You owe \(owes.format())", bundle: .module), systemImage: "clock")
                            .kText(KTextToken.bodySm, color: KColors.warning)
                    } else {
                        KStatusChip(.paid, label: String(localized: "Paid up", bundle: .module))
                    }
                }
            }
        }
    }

    private var subtitle: String {
        switch item.kameti.status {
        case .completed: String(localized: "Completed", bundle: .module)
        case .archived: String(localized: "Archived", bundle: .module)
        case .cancelled: String(localized: "Cancelled", bundle: .module)
        case .draft, .active:
            if let month = item.currentMonth {
                String(localized: "Month \(month.monthIndex) of \(item.kameti.monthsN)", bundle: .module)
            } else {
                String(localized: "Not started yet", bundle: .module)
            }
        }
    }

    @ViewBuilder private var rolePill: some View {
        if item.isOwner {
            KPill(String(localized: "Owner", bundle: .module), foreground: KColors.onBrandSubtle, background: KColors.brandSubtle)
        } else {
            KPill(String(localized: "View only", bundle: .module), symbol: "eye", foreground: KColors.textSecondary, background: KColors.surfaceSunken)
        }
    }
}

/// "Have an invite code?" (board AF-Empty-Home): the 6-character code from
/// the invite email, opened like the link.
struct InviteCodeCard: View {
    let onJoin: (String) -> Void
    @State private var code = ""

    var body: some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.md) {
                VStack(alignment: .leading, spacing: KSpace.xs) {
                    Text("Have an invite code?", bundle: .module).kText(KTextToken.bodyStrong)
                    Text("It's in the email from the person running your kameti.", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                }
                HStack(spacing: KSpace.sm) {
                    TextField(String(localized: "e.g. K7Q2MX", bundle: .module), text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(join)
                        .padding(KSpace.md)
                        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: KRadius.input))
                    Button(String(localized: "Join", bundle: .module), action: join)
                        .buttonStyle(.glass)
                        .controlSize(.large)
                        .disabled(trimmed.isEmpty)
                }
                Label(String(localized: "Invites sent to your email show up here automatically.", bundle: .module), systemImage: "info.circle")
                    .kText(KTextToken.bodySm, color: KColors.info)
                    .padding(KSpace.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KColors.infoSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
            }
        }
    }

    private var trimmed: String { code.trimmingCharacters(in: .whitespaces) }

    private func join() {
        guard !trimmed.isEmpty else { return }
        onJoin(trimmed)
    }
}
