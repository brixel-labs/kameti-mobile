import FeatureInvites
import FeatureKametiDetail
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
    private let onRecord: (String, RecordAction) -> Void
    private let onOpenInvitation: (String) -> Void
    @State private var enteringCode = false
    /// The code card's measured height, so its sheet is only as tall as needed.
    @State private var codeCardHeight: CGFloat = 170
    @State private var declining: MyInvitation?
    @State private var declineFailure: Failure?

    public init(
        model: HomeViewModel,
        onOpen: @escaping (String) -> Void,
        onRecord: @escaping (String, RecordAction) -> Void = { _, _ in },
        onCreate: @escaping () -> Void,
        onJoin: @escaping (String) -> Void,
        onOpenInvitation: @escaping (String) -> Void = { _ in }
    ) {
        self.model = model
        self.onOpenInvitation = onOpenInvitation
        self.onOpen = onOpen
        self.onRecord = onRecord
        self.onCreate = onCreate
        self.onJoin = onJoin
    }

    public var body: some View {
        Group {
            if !model.hasLoaded {
                ScrollView {
                    VStack(spacing: KSpace.md) { KSkeletonRows(rows: 3); KSkeletonRows(rows: 2) }
                        .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            } else if let failure = model.failure, model.sections.isEmpty {
                ScrollView {
                    KMessageCard(
                        String(localized: "Couldn't load your kametis", bundle: .module), message: failure.helpMessage,
                        actionTitle: String(localized: "Try again", bundle: .module)
                    ) { Task { await model.load() } }
                    .padding(.horizontal, KSpace.xl).padding(.top, KSpace.md)
                }
            } else {
                list
            }
        }
        .background(KColors.background)
        .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) { recordButton }
        .navigationTitle(model.firstName ?? String(localized: "Kameti", bundle: .module))
        .task { await model.load() }
        .refreshable { await model.load() }
        // Sized to the card: the sheet's title row (~58 pt) plus the card and a margin.
        .kBottomSheet(
            isPresented: $enteringCode, title: String(localized: "Join with a code", bundle: .module),
            detents: [.height(codeCardHeight + 58 + KSpace.xl)]
        ) {
            ScrollView {
                InviteCodeCard { code in
                    enteringCode = false
                    onJoin(code)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { codeCardHeight = $0 }
                .padding(.horizontal, KSpace.xl)
                .padding(.top, KSpace.xxs)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .alert(
            String(localized: "Decline this invite?", bundle: .module),
            isPresented: Binding(get: { declining != nil }, set: { if !$0 { declining = nil } }), presenting: declining
        ) { invitation in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Decline", bundle: .module), role: .destructive) {
                Task { declineFailure = await model.decline(invitation) }
            }
        } message: { invitation in
            Text("\(invitation.ownerName) will see that you declined \(invitation.kametiName).", bundle: .module)
        }
        .alert(
            String(localized: "Couldn't decline", bundle: .module),
            isPresented: Binding(get: { declineFailure != nil }, set: { if !$0 { declineFailure = nil } }), presenting: declineFailure
        ) { _ in
            Button(String(localized: "OK", bundle: .module)) {}
        } message: { failure in
            Text(failure.userMessage)
        }
    }

    @ViewBuilder private var invitationsSection: some View {
        if !model.invitations.isEmpty {
            KSectionHeader(String(localized: "Invitations", bundle: .module))
            ForEach(model.invitations) { invitation in
                InvitationCard(
                    invitation: invitation, now: model.now,
                    onDecline: { declining = invitation },
                    onReview: { onOpenInvitation(invitation.inviteId) }
                )
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: KSpace.md) {
                if !KConnectivity.shared.isOnline { KOfflineBanner(since: model.loadedAt) }
                invitationsSection
                if model.sections.isEmpty {
                    KCard {
                        VStack(spacing: KSpace.md) {
                            KEmptyIllustration()
                            Text("No kametis yet", bundle: .module).kText(KTextToken.titleLg)
                            Text("Start one for your family, office or friends. Or join one you've been invited to.", bundle: .module)
                                .kText(KTextToken.body, color: KColors.textSecondary)
                                .multilineTextAlignment(.center)
                            startButton
                        }
                        .frame(maxWidth: .infinity)
                    }
                    InviteCodeCard(onJoin: onJoin)
                    Label(String(localized: "Invites sent to your email show up here automatically.", bundle: .module), systemImage: "info.circle")
                        .kText(KTextToken.bodySm, color: KColors.info)
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.infoSubtle, in: RoundedRectangle(cornerRadius: KRadius.card))
                }
                // "New kameti" sits on the first group's header.
                let hasMine = !model.sections.mine.isEmpty
                group(String(localized: "Running by me", bundle: .module), model.sections.mine, showsNew: true)
                group(String(localized: "I'm a member", bundle: .module), model.sections.joined, showsNew: !hasMine)
                group(String(localized: "Past", bundle: .module), model.sections.past)
                if !model.sections.isEmpty {
                    Button { enteringCode = true } label: {
                        Text("Have an invite code?", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.brand)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
    }

    /// Owner kametis that are collecting this month.
    private var recordable: [HomeKametiSummary] {
        model.sections.mine.filter { $0.currentMonth != nil }
    }

    /// Record payment: pick one of my kametis, then what to do on it.
    @ViewBuilder private var recordButton: some View {
        if !recordable.isEmpty {
            Menu {
                Section(String(localized: "Choose a kameti", bundle: .module)) {
                  ForEach(recordable) { item in
                    Menu(item.kameti.name) {
                        let month = item.currentMonth.map { DetailLogic.monthTitle($0.monthStart).split(separator: " ").first.map(String.init) ?? "" } ?? ""
                        if item.currentMonth != nil, !(item.currentMonth?.state == .paidOut || item.currentMonth?.state == .paidOutShort), !item.recipients.isEmpty {
                            Button { onRecord(item.id, .payOut) } label: {
                                Label(String(localized: "Pay out \(month)", bundle: .module), systemImage: "arrow.up.right")
                            }
                        }
                        Button { onRecord(item.id, .recordOne) } label: {
                            Label(String(localized: "Record one payment", bundle: .module), systemImage: "plus")
                        }
                        Button { onRecord(item.id, .collect) } label: {
                            Label(String(localized: "Collect \(month) (tap to settle)", bundle: .module), systemImage: "checklist")
                        }
                    }
                  }
                }
            } label: {
                Label(String(localized: "Record payment", bundle: .module), systemImage: "plus")
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .padding(.horizontal, KSpace.lg)
                    .frame(minHeight: 52)
                    .background(KColors.brand, in: RoundedRectangle(cornerRadius: KRadius.card))
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
            }
            .padding(KSpace.xl)
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
                actionTitle: showsNew ? String(localized: "+ New kameti", bundle: .module) : nil,
                action: showsNew ? onCreate : nil
            )
            ForEach(items) { item in
                Button { onOpen(item.id) } label: { HomeKametiCard(item: item) }
                    .buttonStyle(.plain)
            }
        }
    }
}

/// A kameti on Home (FR-2, board A · Home): name, role, month, this month's
/// pot and recipients, or for a kameti I'm a member of, what I owe and my turn.
struct HomeKametiCard: View {
    let item: HomeKametiSummary

    private var isPast: Bool { [.completed, .archived, .cancelled].contains(item.kameti.status) }

    var body: some View {
        KCard {
            if isPast {
                pastBody
            } else {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: KSpace.xs) {
                            Text(item.kameti.name).kText(KTextToken.titleLg)
                            Text(subtitle).kText(KTextToken.body, color: KColors.textSecondary)
                        }
                        Spacer(minLength: KSpace.sm)
                        rolePill
                    }
                    if item.isOwner { ownerBody } else { memberBody }
                }
            }
        }
    }

    // MARK: Owner

    private var isPaidOut: Bool {
        guard let state = item.currentMonth?.state else { return false }
        return state == .paidOut || state == .paidOutShort
    }

    @ViewBuilder private var ownerBody: some View {
        if let month = item.currentMonth {
            KPotProgress(
                collected: month.received, target: month.target,
                caption: String(localized: "\(month.paidCount) of \(month.memberCount) paid", bundle: .module),
                trailingCaption: item.dueDate.map { String(localized: "Due by \(DetailLogic.dayMonth($0))", bundle: .module) },
                headline: .ofTarget
            )
        }
        if isPaidOut, let month = item.currentMonth {
            paidOutStrip(month)
        } else if !item.recipients.isEmpty {
            Divider()
            HStack(spacing: KSpace.md) {
                KAvatarStack(item.recipients.map { ($0.name, $0.colorIndex) })
                (Text("This month: ", bundle: .module).foregroundStyle(KColors.textSecondary)
                    + Text(item.recipients.map(\.name).joined(separator: " + ")).fontWeight(.semibold))
                    .kText(KTextToken.body)
            }
        }
    }

    /// After a payout: a green strip (amber when short) with who was paid, how
    /// much and when.
    private func paidOutStrip(_ month: MonthCollectionRow) -> some View {
        let short = month.state == .paidOutShort && month.paidOutShortBy.isPositive
        let people = item.recipients.map(\.name).joined(separator: " + ")
        return KPaidOutStrip(
            people: item.recipients.map { ($0.name, $0.colorIndex) },
            title: short
                ? String(localized: "Paid out · \(month.paidOut.format()) · short \(month.paidOutShortBy.format())", bundle: .module)
                : String(localized: "Paid out · \(month.paidOut.format())", bundle: .module),
            subtitle: item.payoutDate.map { "\(people) · \(DetailLogic.dayMonth($0))" } ?? people,
            isShort: short
        )
    }

    // MARK: Member

    @ViewBuilder private var memberBody: some View {
        if let owes = item.owes {
            if owes.isPositive {
                HStack {
                    Label(String(localized: "You owe \(owes.format())", bundle: .module), systemImage: "clock")
                        .kText(KTextToken.bodyStrong, color: KColors.warning)
                    Spacer()
                    if let due = item.dueDate {
                        Text("Due \(DetailLogic.dayMonth(due))", bundle: .module).kText(KTextToken.body, color: KColors.warning)
                    }
                }
                .padding(KSpace.md)
                .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
            } else {
                KStatusChip(.paid, label: String(localized: "Paid up", bundle: .module))
            }
        }
        if let turn = item.nextTurn {
            (Text("Your turn: ", bundle: .module).foregroundStyle(KColors.textSecondary)
                + Text(DetailLogic.monthTitle(turn.month)).fontWeight(.semibold)
                + Text(" · \(turn.payout.format())").foregroundStyle(KColors.textSecondary))
                .kText(KTextToken.body)
        }
    }

    // MARK: Past

    private var pastBody: some View {
        HStack {
            VStack(alignment: .leading, spacing: KSpace.xs) {
                Text(item.kameti.name).kText(KTextToken.titleLg)
                Text("\(statusLabel) · \(DetailLogic.monthTitle(DetailLogic.monthStart(of: item.kameti, monthIndex: item.kameti.monthsN)))")
                    .kText(KTextToken.body, color: KColors.textSecondary)
            }
            Spacer()
            if item.kameti.status == .completed {
                Label(String(localized: "Settled", bundle: .module), systemImage: "checkmark")
                    .kText(KTextToken.bodyStrong, color: KColors.positive)
            }
        }
    }

    private var statusLabel: String {
        switch item.kameti.status {
        case .completed: String(localized: "Completed", bundle: .module)
        case .archived: String(localized: "Archived", bundle: .module)
        case .cancelled: String(localized: "Cancelled", bundle: .module)
        case .draft, .active: ""
        }
    }

    private var subtitle: String {
        if let month = item.currentMonth {
            String(localized: "Month \(month.monthIndex) of \(item.kameti.monthsN) · \(DetailLogic.monthTitle(month.monthStart).split(separator: " ").first.map(String.init) ?? "")", bundle: .module)
        } else {
            String(localized: "Not started yet", bundle: .module)
        }
    }

    @ViewBuilder private var rolePill: some View {
        if item.isOwner, isPaidOut {
            if item.currentMonth?.state == .paidOutShort {
                KPill(String(localized: "Paid out short", bundle: .module), foreground: KColors.warning, background: KColors.warningSubtle)
            } else {
                KPill(String(localized: "Paid out", bundle: .module), foreground: KColors.positive, background: KColors.positiveSubtle)
            }
        } else if item.isOwner {
            KPill(String(localized: "Owner", bundle: .module), foreground: KColors.onBrandSubtle, background: KColors.brandSubtle)
        } else {
            KPill(String(localized: "View only", bundle: .module), foreground: KColors.textSecondary, background: KColors.surfaceSunken)
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
                        .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                }
                HStack(spacing: KSpace.sm) {
                    TextField(String(localized: "e.g. K7Q2MX", bundle: .module), text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .tracking(2)
                        .submitLabel(.go)
                        .onSubmit(join)
                        .padding(.horizontal, KSpace.md)
                        .frame(minHeight: 48)
                        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                        .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.border))
                    Button(action: join) {
                        Text("Join", bundle: .module)
                            .kText(KTextToken.bodyStrong, color: KColors.brand)
                            .padding(.horizontal, KSpace.lg)
                            .frame(minHeight: 48)
                            .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(KColors.brand))
                    }
                    .buttonStyle(.plain)
                    .disabled(trimmed.isEmpty)
                    .opacity(trimmed.isEmpty ? 0.5 : 1)
                }
            }
        }
    }

    private var trimmed: String { code.trimmingCharacters(in: .whitespaces) }

    private func join() {
        guard !trimmed.isEmpty else { return }
        onJoin(trimmed)
    }
}
