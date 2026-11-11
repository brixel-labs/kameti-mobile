import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// The owner's view of a running kameti (boards A-Overview, A2-*-Tab):
/// Overview, Members, Schedule and Payments. Recording actions arrive with
/// the payments slice.
struct OwnerTabs: View {
    enum Tab: Hashable, CaseIterable { case overview, members, schedule, payments }

    let data: KametiDetailData
    let model: KametiDetailViewModel
    @State private var tab = Tab.overview
    @State private var recording: RecordTarget?
    @State private var collecting = false
    @State private var voiding: VoidTarget?
    @State private var payingOut: Int?

    struct RecordTarget: Identifiable {
        let id = UUID()
        let memberId: String?
    }

    private var payingOutMonthName: String {
        guard let month = payingOut else { return "" }
        return DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: month)).split(separator: " ").first.map(String.init) ?? ""
    }

    /// A payout can be recorded once the month has recipients and isn't paid out.
    private func canPayOut(_ row: MonthCollectionRow) -> Bool {
        !CollectionStatePill.isPaidOut(row.state)
            && !DetailLogic.recipients(kameti: data.kameti, monthIndex: row.monthIndex, slots: data.slots, shares: data.shares, members: data.members).isEmpty
    }

    private var monthName: String {
        data.current.map { DetailLogic.monthTitle($0.monthStart).split(separator: " ").first.map(String.init) ?? "" } ?? ""
    }

    private var titles: [(tab: Tab, title: String)] {
        [
            (.overview, String(localized: "Overview", bundle: .module)),
            (.members, String(localized: "Members", bundle: .module)),
            (.schedule, String(localized: "Schedule", bundle: .module)),
            (.payments, String(localized: "Payments", bundle: .module)),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            KUnderlineTabs(titles, selection: $tab, inset: KSpace.xl)
                .background(KColors.background)
            // The system paging view: swipe left or right between the tabs, or
            // tap a tab; the page moves the way you'd expect.
            TabView(selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { page in
                    ScrollView {
                        VStack(alignment: .leading, spacing: KSpace.lg) {
                            content(for: page)
                        }
                        .padding(.horizontal, KSpace.xl)
                        .padding(.top, KSpace.lg)
                        .padding(.bottom, KSpace.xl)
                    }
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth(duration: 0.28), value: tab)
            .overlay(alignment: .bottomTrailing) {
                if tab == .overview, data.current != nil {
                    Menu {
                        if let current = data.current, canPayOut(current) {
                            Button { payingOut = current.monthIndex } label: {
                                Label(String(localized: "Pay out \(monthName)", bundle: .module), systemImage: "arrow.up.right")
                            }
                        }
                        Button { recording = RecordTarget(memberId: nil) } label: {
                            Label(String(localized: "Record one payment", bundle: .module), systemImage: "plus")
                        }
                        Button { collecting = true } label: {
                            Label(String(localized: "Collect \(monthName) (tap to settle)", bundle: .module), systemImage: "checklist")
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
                    .transition(.opacity)
                }
            }
        }
        .animation(.smooth(duration: 0.2), value: tab)
        .task { await startPendingAction() }
        .kBottomSheet(
            isPresented: Binding(get: { recording != nil }, set: { if !$0 { recording = nil } }),
            title: String(localized: "Record payment", bundle: .module), detents: [.large]
        ) {
            if let target = recording {
                RecordPaymentSheet(data: data, model: model, preselected: target.memberId) { recording = nil }
                    .id(target.id)
            }
        }
        .kBottomSheet(isPresented: $collecting, title: String(localized: "Collect \(monthName) Kameti", bundle: .module), detents: [.large]) {
            // No condition here: the sheet is only built while it is presented.
            CollectMonthSheet(data: data, model: model) { collecting = false }
        }
        .kBottomSheet(
            isPresented: Binding(get: { voiding != nil }, set: { if !$0 { voiding = nil } }),
            title: voiding?.isPayout == true ? String(localized: "Void payout", bundle: .module) : String(localized: "Void payment", bundle: .module),
            detents: [.medium]
        ) {
            if let target = voiding { VoidSheet(target: target, model: model) { voiding = nil } }
        }
        .kBottomSheet(
            isPresented: Binding(get: { payingOut != nil }, set: { if !$0 { payingOut = nil } }),
            title: String(localized: "Pay out \(payingOutMonthName) Kameti", bundle: .module), detents: [.large]
        ) {
            if let month = payingOut { PayoutSheet(data: data, model: model, monthIndex: month) { payingOut = nil }.id(month) }
        }
    }

    /// Home's Record payment opens the kameti and starts the chosen action.
    private func startPendingAction() async {
        guard let action = model.pendingAction else { return }
        model.pendingAction = nil
        try? await Task.sleep(for: .milliseconds(450))
        switch action {
        case .payOut: if let current = data.current, canPayOut(current) { payingOut = current.monthIndex }
        case .recordOne: recording = RecordTarget(memberId: nil)
        case .collect: collecting = true
        }
    }

    @ViewBuilder
    private func content(for tab: Tab) -> some View {
        switch tab {
        case .overview: OverviewTab(data: data) { recording = RecordTarget(memberId: $0) }
        case .members: MembersTab(data: data)
        case .schedule: ScheduleSection(data: data) { payingOut = $0 }
        case .payments: PaymentsTab(data: data) { voiding = $0 }
        }
    }
}

/// This month's pot, who has paid, the recipients and every member's status
/// (board A · Kameti overview).
struct OverviewTab: View {
    let data: KametiDetailData
    let onRecord: (String) -> Void

    var body: some View {
        if let current = data.current {
            let recipients = DetailLogic.recipients(
                kameti: data.kameti, monthIndex: current.monthIndex, slots: data.slots, shares: data.shares, members: data.members
            )
            let counts = DetailLogic.statusCounts(data.months, monthIndex: current.monthIndex)
            let rows = data.months.filter { $0.monthIndex == current.monthIndex }
            let owing = DetailLogic.owing(data.months, monthIndex: current.monthIndex)
            let byId = Dictionary(data.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let toGo = current.target - current.received

            KCard {
                VStack(alignment: .leading, spacing: KSpace.md) {
                    HStack {
                        Text("\(DetailLogic.monthTitle(current.monthStart)) · month \(current.monthIndex)".uppercased())
                            .kText(KTextToken.label, color: KColors.textSecondary)
                        Spacer()
                        CollectionStatePill(state: current.state)
                    }
                    // Received (cash this month) drives the pot and payout; covered
                    // drives member statuses.
                    KPotProgress(
                        collected: current.received, target: current.target,
                        caption: toGo.isPositive
                            ? String(localized: "collected of \(current.target.format()) · \(toGo.format()) to go", bundle: .module)
                            : String(localized: "collected of \(current.target.format())", bundle: .module),
                        headline: .none, captionAboveBar: true
                    )
                    KFlowLayout {
                        KStatusChip(.paid, label: String(localized: "\(counts.paid) paid", bundle: .module))
                        KStatusChip(.partial, label: String(localized: "\(counts.partial) partial", bundle: .module))
                        KStatusChip(.unpaid, label: String(localized: "\(counts.unpaid) unpaid", bundle: .module))
                    }
                    if !recipients.isEmpty {
                        if CollectionStatePill.isPaidOut(current.state) {
                            paidOutStrip(current, recipients)
                        } else {
                            recipientsBox(recipients)
                        }
                    }
                }
            }

            if !owing.isEmpty {
                Button {} label: {
                    Label(String(localized: "Remind \(owing.count) members who owe", bundle: .module), systemImage: "bell")
                        .kText(KTextToken.bodyStrong, color: KColors.brand)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay(Capsule().stroke(KColors.brand, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }

            KSectionHeader(String(localized: "This month", bundle: .module))
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.memberId) { index, row in
                    if let member = byId[row.memberId] {
                        let owes = row.remaining.isPositive
                        Button { if owes { onRecord(member.id) } } label: {
                        DetailRow(
                            member: member, in: data.members,
                            subtitle: row.status == .advance
                                ? String(localized: "Covered by credit", bundle: .module)
                                : String(localized: "\(row.allocated.format()) of \(row.due.format(symbol: false))", bundle: .module),
                            showsDivider: index < rows.count - 1
                        ) {
                            StatusTextPill(status: row.status)
                        }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            // Room for the floating action.
            Color.clear.frame(height: 56)
        } else {
            ContentUnavailableView(
                String(localized: "Not started yet", bundle: .module), systemImage: "hourglass",
                description: Text("Collections begin when the kameti starts.", bundle: .module)
            )
        }
    }

    private func colorIndex(_ member: Member) -> Int {
        Int(member.color ?? "") ?? max(data.members.firstIndex(of: member) ?? 0, 0)
    }

    private func paidOutStrip(_ current: MonthCollectionRow, _ recipients: [DetailLogic.Recipient]) -> some View {
        let short = current.state == .paidOutShort && current.paidOutShortBy.isPositive
        let names = recipients.map { $0.member.id == data.me?.id ? String(localized: "You", bundle: .module) : $0.member.name }.joined(separator: " + ")
        let slotIds = Set(data.slots.filter { $0.payoutMonthIndex == current.monthIndex }.map(\.id))
        let paidOn = data.payouts.filter { $0.voidedAt == nil && slotIds.contains($0.slotId) }.map(\.paidOn).max()
        return KPaidOutStrip(
            people: recipients.map { ($0.member.name, colorIndex($0.member)) },
            title: short
                ? String(localized: "Paid out · \(current.paidOut.format()) · short \(current.paidOutShortBy.format())", bundle: .module)
                : String(localized: "Paid out · \(current.paidOut.format())", bundle: .module),
            subtitle: paidOn.map { "\(names) · \(DetailLogic.dayMonth($0))" } ?? names,
            isShort: short
        )
    }

    private func recipientsBox(_ recipients: [DetailLogic.Recipient]) -> some View {
        let same = Set(recipients.map(\.payout)).count == 1
        return HStack(spacing: KSpace.md) {
            KAvatarStack(recipients.map { recipient in
                (recipient.member.name, Int(recipient.member.color ?? "") ?? max(data.members.firstIndex(of: recipient.member) ?? 0, 0))
            })
            VStack(alignment: .leading, spacing: 2) {
                Text(recipients.map { $0.member.id == data.me?.id ? String(localized: "You", bundle: .module) : $0.member.name }.joined(separator: " + "))
                    .kText(KTextToken.bodyStrong)
                if recipients.count > 1 {
                    Text(same
                         ? String(localized: "\(recipients[0].payout.format()) each · shared slot", bundle: .module)
                         : String(localized: "Shared slot", bundle: .module))
                        .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                } else {
                    Text("Receives \(recipients[0].payout.format())", bundle: .module)
                        .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: KRadius.input))
    }
}

/// A month status as a plain coloured pill (no icon), as on the overview rows.
struct StatusTextPill: View {
    let status: MonthStatusCode

    var body: some View {
        let style = Self.style(for: status)
        KPill(status.chip.label, foreground: style.foreground, background: style.background)
    }

    nonisolated static func style(for status: MonthStatusCode) -> (foreground: Color, background: Color) {
        switch status {
        case .paid: (KColors.positive, KColors.positiveSubtle)
        case .partial: (KColors.warning, KColors.warningSubtle)
        case .unpaid, .overdue: (KColors.negative, KColors.negativeSubtle)
        case .advance: (KColors.info, KColors.infoSubtle)
        case .upcoming: (KColors.textSecondary, KColors.surfaceSunken)
        }
    }
}

/// Members (board A v2 · Members): search, a heads-up for people who haven't
/// joined, and one row per member with slots, balance and join state.
struct MembersTab: View {
    let data: KametiDetailData
    @State private var search = ""

    var body: some View {
        let balances = Dictionary(data.balances.map { ($0.memberId, $0) }, uniquingKeysWith: { first, _ in first })
        let notJoined = data.members.filter { $0.joinStatus != .joined && $0.profileId == nil }.count
        let list = data.members.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
        if data.members.isEmpty {
            ContentUnavailableView(
                String(localized: "No members yet", bundle: .module), systemImage: "person.2",
                description: Text("Members you add will show here.", bundle: .module)
            )
        } else {
            HStack(spacing: KSpace.sm) {
                Image(systemName: "magnifyingglass").foregroundStyle(KColors.textSecondary)
                TextField(String(localized: "Search \(data.members.count) members", bundle: .module), text: $search)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, KSpace.md)
            .frame(minHeight: 44)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.border))

            if notJoined > 0 {
                HStack(spacing: KSpace.sm + 2) {
                    Image(systemName: "envelope").foregroundStyle(KColors.warning)
                    Text(notJoined == 1
                         ? String(localized: "1 person hasn't joined the app yet", bundle: .module)
                         : String(localized: "\(notJoined) people haven't joined the app yet", bundle: .module))
                        .kText(KTextToken.bodySm, color: KColors.warning)
                    Spacer(minLength: KSpace.sm)
                    // Sending invites arrives with the invites screens.
                    Button {} label: {
                        Text("Invite all", bundle: .module)
                            .kText(KTextStyle(size: 13, weight: .semibold), color: KColors.textOnBrand)
                            .padding(.horizontal, KSpace.md).frame(height: 32)
                            .background(KColors.warning, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(KSpace.md)
                .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.element.id) { index, member in
                    let balance = balances[member.id]
                    let slots = DetailLogic.slotCount(of: member, shares: data.shares)
                    DetailRow(
                        member: member, in: data.members,
                        subtitle: balance.map {
                            slots == 1
                                ? String(localized: "1 slot · \($0.monthlyDue.format())/mo", bundle: .module)
                                : String(localized: "\(slots) slots · \($0.monthlyDue.format())/mo", bundle: .module)
                        },
                        showsDivider: index < list.count - 1
                    ) {
                        VStack(alignment: .trailing, spacing: 4) {
                            if let balance { BalanceChip(balance: balance) }
                            joinCaption(member.joinStatus)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func joinCaption(_ status: JoinStatus) -> some View {
        switch status {
        case .joined: Text("Joined", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
        case .invited: Text("Invited", bundle: .module).kText(KTextStyle(size: 12, weight: .semibold), color: KColors.warning)
        case .pendingApproval: Text("Needs approval", bundle: .module).kText(KTextStyle(size: 12, weight: .semibold), color: KColors.info)
        case .notInvited: Text("Not invited", bundle: .module).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
        case .declined: Text("Declined", bundle: .module).kText(KTextToken.caption, color: KColors.negative)
        }
    }
}

/// "Owes Rs 4,50,000", "Settled" or "Credit Rs 1,25,000" as a small pill.
struct BalanceChip: View {
    let balance: MemberBalanceRow

    var body: some View {
        if balance.owes.isPositive {
            KPill(String(localized: "Owes \(balance.owes.format())", bundle: .module), foreground: KColors.negative, background: KColors.negativeSubtle)
        } else if balance.credit.isPositive {
            KPill(String(localized: "Credit \(balance.credit.format())", bundle: .module), foreground: KColors.info, background: KColors.infoSubtle)
        } else {
            KPill(String(localized: "Settled", bundle: .module), foreground: KColors.positive, background: KColors.positiveSubtle)
        }
    }
}

/// Payments (board A v2 · Payments): a month and Received / Paid out filter,
/// two summary cards, and the money list grouped by day.
struct PaymentsTab: View {
    enum Kind: Hashable { case received, paidOut }

    let data: KametiDetailData
    let onVoid: (VoidTarget) -> Void
    @State private var monthIndex: Int?
    @State private var kind = Kind.received
    @State private var pickingMonth = false

    private var month: Int {
        monthIndex ?? data.current?.monthIndex ?? DetailLogic.monthIndex(of: data.today, kameti: data.kameti) ?? 1
    }

    var body: some View {
        let kameti = data.kameti
        let start = DetailLogic.monthStart(of: kameti, monthIndex: month)
        let inMonth: (Date) -> Bool = { DetailLogic.monthIndex(of: $0, kameti: kameti) == month }
        let payments = DetailLogic.newestFirst(data.payments.filter { inMonth($0.receivedOn) })
        let payouts = data.payouts.filter { inMonth($0.paidOn) }.sorted { $0.paidOn > $1.paidOn }
        let row = data.collections.first { $0.monthIndex == month }
        let valid = payments.filter { $0.voidedAt == nil }.count
        let owing = DetailLogic.owing(data.months, monthIndex: month).count
        let stillDue = row.map { max($0.target.rupees - $0.received.rupees, 0) } ?? 0
        let byId = Dictionary(data.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        HStack(spacing: KSpace.sm) {
            Button { pickingMonth = true } label: {
                HStack(spacing: 6) {
                    Text(DetailLogic.monthTitle(start)).kText(KTextStyle(size: 13, weight: .semibold))
                    Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, KSpace.md).frame(height: 34)
                .background(KColors.surface, in: Capsule())
                .overlay(Capsule().stroke(KColors.border))
            }
            .buttonStyle(.plain)
            filterChip(String(localized: "Received", bundle: .module), .received)
            filterChip(String(localized: "Paid out", bundle: .module), .paidOut)
            Spacer(minLength: 0)
        }

        HStack(spacing: KSpace.md) {
            summaryCard(String(localized: "Received", bundle: .module), amount: row?.received ?? .zero,
                        note: String(localized: "\(valid) payments", bundle: .module), tone: .neutral)
            summaryCard(String(localized: "Still due", bundle: .module), amount: Money(stillDue),
                        note: String(localized: "\(owing) members", bundle: .module), tone: .negative)
        }

        let entries: [Entry] = kind == .received
            ? payments.map { payment in
                Entry(
                    id: payment.id, date: payment.receivedOn, kind: .received,
                    title: byId[payment.memberId]?.name ?? "",
                    subtitle: payment.voidedAt != nil
                        ? String(localized: "Voided · \(payment.voidReason ?? "")", bundle: .module)
                        : DetailLogic.paymentSubtitle(payment, methodLabel: payment.method.label) { String(localized: "paid by \($0)", bundle: .module) },
                    amount: payment.amount, methodLabel: payment.method.label, isVoided: payment.voidedAt != nil
                )
            }
            : payouts.map { payout in
                Entry(
                    id: payout.id, date: payout.paidOn, kind: .paidOut,
                    title: byId[payout.memberId]?.name ?? "",
                    subtitle: payout.voidedAt != nil
                        ? String(localized: "Voided · \(payout.voidReason ?? "")", bundle: .module)
                        : [payout.method.label, payout.reference].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                    amount: payout.amount, methodLabel: payout.method.label, isVoided: payout.voidedAt != nil
                )
            }

        if entries.isEmpty {
            ContentUnavailableView(
                kind == .received ? String(localized: "No payments yet", bundle: .module) : String(localized: "No payouts yet", bundle: .module),
                systemImage: "receipt",
                description: Text("Nothing recorded in \(DetailLogic.monthTitle(start)).", bundle: .module)
            )
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedByDay(entries), id: \.day) { group in
                    Text(dayTitle(group.day).uppercased())
                        .kText(KTextToken.label, color: KColors.textSecondary)
                        .padding(.top, KSpace.md).padding(.bottom, 2)
                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                        Button {
                            if !entry.isVoided {
                                onVoid(VoidTarget(id: entry.id, name: entry.title, amount: entry.amount, subtitle: "\(DetailLogic.dayMonth(entry.date)) · \(entry.methodLabel)", isPayout: entry.kind == .paidOut))
                            }
                        } label: {
                            PaymentRow(
                                kind: entry.kind == .received ? .received : .paidOut, title: entry.title, subtitle: entry.subtitle,
                                amount: entry.amount, isVoided: entry.isVoided, showsDivider: index < group.entries.count - 1
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: Pieces

    private struct Entry: Identifiable {
        let id: String
        let date: Date
        let kind: Kind
        let title: String
        let subtitle: String
        let amount: Money
        let methodLabel: String
        let isVoided: Bool
    }

    private func groupedByDay(_ entries: [Entry]) -> [(day: Date, entries: [Entry])] {
        var result: [(day: Date, entries: [Entry])] = []
        for entry in entries {
            if let last = result.indices.last, result[last].day == entry.date { result[last].entries.append(entry) }
            else { result.append((entry.date, [entry])) }
        }
        return result
    }

    private func dayTitle(_ day: Date) -> String {
        day == data.today
            ? String(localized: "Today · \(DetailLogic.dayMonth(day))", bundle: .module)
            : DetailLogic.dayMonth(day)
    }

    private func filterChip(_ title: String, _ value: Kind) -> some View {
        let isOn = kind == value
        return Button { withAnimation(.smooth(duration: 0.2)) { kind = value } } label: {
            Text(title)
                .kText(KTextStyle(size: 13, weight: isOn ? .semibold : .medium), color: isOn ? KColors.onBrandSubtle : KColors.textPrimary)
                .padding(.horizontal, KSpace.md).frame(height: 34)
                .background(isOn ? KColors.brandSubtle : KColors.surface, in: Capsule())
                .overlay(Capsule().stroke(isOn ? KColors.brand : KColors.border))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func summaryCard(_ title: String, amount: Money, note: String, tone: KMoneyText.Tone) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
            KMoneyText(amount, style: .title, tone: tone)
            Text(note).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(KColors.border))
    }
}
