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

struct MembersTab: View {
    let data: KametiDetailData

    var body: some View {
        let waiting = data.members.filter { $0.joinStatus == .pendingApproval }.count
        let balances = Dictionary(data.balances.map { ($0.memberId, $0) }, uniquingKeysWith: { first, _ in first })
        if data.members.isEmpty {
            ContentUnavailableView(
                String(localized: "No members yet", bundle: .module), systemImage: "person.2",
                description: Text("Members you add will show here.", bundle: .module)
            )
        } else {
            if waiting > 0 {
                Label(String(localized: "\(waiting) waiting for your approval", bundle: .module), systemImage: "person.badge.clock")
                    .kText(KTextToken.bodySm, color: KColors.info)
                    .padding(KSpace.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KColors.infoSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
            }
            VStack(spacing: 0) {
                ForEach(Array(data.members.enumerated()), id: \.element.id) { index, member in
                    let balance = balances[member.id]
                    DetailRow(
                        member: member, in: data.members,
                        subtitle: balance.map { String(localized: "Due \($0.monthlyDue.format()) a month", bundle: .module) },
                        showsDivider: index < data.members.count - 1
                    ) {
                        VStack(alignment: .trailing, spacing: KSpace.xs) {
                            if let balance { KBalancePill(balance: balance.balance) }
                            JoinStatusPill(status: member.joinStatus)
                        }
                    }
                }
            }
        }
    }
}

struct PaymentsTab: View {
    let data: KametiDetailData

    var body: some View {
        let sorted = DetailLogic.newestFirst(data.payments)
        let valid = sorted.filter { $0.voidedAt == nil }.count
        if sorted.isEmpty {
            ContentUnavailableView(
                String(localized: "No payments yet", bundle: .module), systemImage: "receipt",
                description: Text("Recorded payments will show here.", bundle: .module)
            )
        } else {
            KCard {
                VStack(alignment: .leading, spacing: KSpace.sm) {
                    if let current = data.current {
                        HStack {
                            Text("Received this month", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                            Spacer()
                            KMoneyText(current.received, style: .title)
                        }
                    }
                    HStack {
                        Text("Payments", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                        Spacer()
                        Text("\(valid) recorded", bundle: .module).kText(KTextToken.bodyStrong)
                    }
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(sorted.enumerated()), id: \.element.id) { index, payment in
                    PaymentRow(
                        payment: payment, member: data.members.first { $0.id == payment.memberId },
                        members: data.members, showsDivider: index < sorted.count - 1
                    )
                }
            }
        }
    }
}
