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
    @State private var tab = Tab.overview

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
                    Button {} label: {
                        Label(String(localized: "Record payment", bundle: .module), systemImage: "plus")
                            .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                            .padding(.horizontal, KSpace.lg)
                            .frame(minHeight: 52)
                            .background(KColors.brand, in: RoundedRectangle(cornerRadius: KRadius.card))
                            .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(KSpace.xl)
                    .transition(.opacity)
                }
            }
        }
        .animation(.smooth(duration: 0.2), value: tab)
    }

    @ViewBuilder
    private func content(for tab: Tab) -> some View {
        switch tab {
        case .overview: OverviewTab(data: data)
        case .members: MembersTab(data: data)
        case .schedule: ScheduleSection(data: data)
        case .payments: PaymentsTab(data: data)
        }
    }
}

/// This month's pot, who has paid, the recipients and every member's status
/// (board A · Kameti overview).
struct OverviewTab: View {
    let data: KametiDetailData

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
                    if !recipients.isEmpty { recipientsBox(recipients) }
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
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                } else {
                    Text("Receives \(recipients[0].payout.format())", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
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
        case .joined: Text("Joined", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
        case .invited: Text("Invited", bundle: .module).kText(KTextStyle(size: 12, weight: .semibold), color: KColors.warning)
        case .pendingApproval: Text("Needs approval", bundle: .module).kText(KTextStyle(size: 12, weight: .semibold), color: KColors.info)
        case .notInvited: Text("Not invited", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
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
                    amount: payment.amount, isVoided: payment.voidedAt != nil
                )
            }
            : payouts.map { payout in
                Entry(
                    id: payout.id, date: payout.paidOn, kind: .paidOut,
                    title: byId[payout.memberId]?.name ?? "",
                    subtitle: payout.voidedAt != nil
                        ? String(localized: "Voided · \(payout.voidReason ?? "")", bundle: .module)
                        : [payout.method.label, payout.reference].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
                    amount: payout.amount, isVoided: payout.voidedAt != nil
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
                        PaymentRow(
                            kind: entry.kind == .received ? .received : .paidOut, title: entry.title, subtitle: entry.subtitle,
                            amount: entry.amount, isVoided: entry.isVoided, showsDivider: index < group.entries.count - 1
                        )
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
            Text(title).kText(KTextToken.caption, color: KColors.textSecondary)
            KMoneyText(amount, style: .title, tone: tone)
            Text(note).kText(KTextToken.caption, color: KColors.textSecondary)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(KColors.border))
    }
}
