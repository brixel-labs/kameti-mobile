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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                switch tab {
                case .overview: OverviewTab(data: data)
                case .members: MembersTab(data: data)
                case .schedule: ScheduleSection(data: data)
                case .payments: PaymentsTab(data: data)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.bottom, KSpace.xl)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("", selection: $tab) {
                Text("Overview", bundle: .module).tag(Tab.overview)
                Text("Members", bundle: .module).tag(Tab.members)
                Text("Schedule", bundle: .module).tag(Tab.schedule)
                Text("Payments", bundle: .module).tag(Tab.payments)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, KSpace.xl)
            .padding(.vertical, KSpace.sm)
            .background(KColors.background)
        }
    }
}

/// This month's pot, who has paid, the recipients and who still owes.
struct OverviewTab: View {
    let data: KametiDetailData

    var body: some View {
        if let current = data.current {
            let recipients = DetailLogic.recipients(
                kameti: data.kameti, monthIndex: current.monthIndex, slots: data.slots, shares: data.shares, members: data.members
            )
            let counts = DetailLogic.statusCounts(data.months, monthIndex: current.monthIndex)
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
                        caption: toGo.isPositive ? String(localized: "\(toGo.format()) to go", bundle: .module) : nil
                    )
                    HStack(spacing: KSpace.sm) {
                        KStatusChip(.paid, label: String(localized: "\(counts.paid) paid", bundle: .module))
                        KStatusChip(.partial, label: String(localized: "\(counts.partial) partial", bundle: .module))
                        KStatusChip(.unpaid, label: String(localized: "\(counts.unpaid) unpaid", bundle: .module))
                    }
                    Divider()
                    if recipients.isEmpty {
                        Text("No one is paid out this month yet.", bundle: .module)
                            .kText(KTextToken.bodySm, color: KColors.textSecondary)
                    } else {
                        ForEach(recipients) { recipient in
                            HStack {
                                KAvatar(name: recipient.member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: recipient.member, in: data.members), size: .medium)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recipient.member.id == data.me?.id ? String(localized: "You", bundle: .module) : recipient.member.name)
                                        .kText(KTextToken.bodyStrong)
                                    Text("Receives \(recipient.payout.format())", bundle: .module)
                                        .kText(KTextToken.caption, color: KColors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }

            KSectionHeader(String(localized: "Who still owes", bundle: .module))
            if owing.isEmpty {
                Label(String(localized: "Everyone has paid", bundle: .module), systemImage: "checkmark.circle")
                    .kText(KTextToken.body, color: KColors.positive)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(owing.enumerated()), id: \.element.memberId) { index, row in
                        if let member = byId[row.memberId] {
                            DetailRow(
                                member: member, in: data.members,
                                subtitle: String(localized: "\(row.allocated.format()) of \(row.due.format())", bundle: .module),
                                showsDivider: index < owing.count - 1
                            ) {
                                KStatusChip(row.status.chip.status, label: row.status.chip.label)
                            }
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                String(localized: "Not started yet", bundle: .module), systemImage: "hourglass",
                description: Text("Collections begin when the kameti starts.", bundle: .module)
            )
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
