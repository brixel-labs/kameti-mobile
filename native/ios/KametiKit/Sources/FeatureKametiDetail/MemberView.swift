import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// A member's read-only view (board A · Member view; FR-60 to FR-64): my due
/// this month, my payout, this month's pot and my payments. It builds no write
/// controls; the backend enforces the same rule.
struct MemberView: View {
    let data: KametiDetailData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                if data.kameti.status == .draft {
                    // The owner took it back to setup ("Edit setup"): turns and dues may change.
                    KMessageCard(
                        String(localized: "Being updated by the owner", bundle: .module),
                        message: String(localized: "The owner is changing the setup. Your turn and dues may change; you'll get a notification when it starts again.", bundle: .module),
                        symbol: "pencil.and.list.clipboard", tint: KColors.info
                    )
                } else if let me = data.me {
                    content(for: me)
                } else {
                    ContentUnavailableView(
                        String(localized: "You're not a member of this kameti", bundle: .module), systemImage: "person.slash",
                        description: Text("Ask the owner to send you an invite.", bundle: .module)
                    )
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.sm)
            .padding(.bottom, KSpace.xl)
        }
    }

    @ViewBuilder
    private func content(for me: Member) -> some View {
        let balance = data.balances.first { $0.memberId == me.id }
        dueCard(balance: balance)
        if let turn = DetailLogic.nextTurn(for: me, kameti: data.kameti, from: data.current?.monthIndex ?? 1, slots: data.slots, shares: data.shares) {
            payoutCard(me: me, monthIndex: turn.monthIndex, payout: turn.payout)
        }
        if let current = data.current { potCard(current) }
        paymentsCard(me: me)
        // Shared notes from the owner that are about me or the whole kameti (FR-71).
        if !data.notes.isEmpty {
            card(title: String(localized: "Notes from the owner", bundle: .module)) {
                VStack(spacing: KSpace.sm) {
                    ForEach(data.notes) { NoteCard(note: $0, data: data) }
                }
            }
        }
    }

    // MARK: Your due

    private func dueCard(balance: MemberBalanceRow?) -> some View {
        let owes = balance?.owes ?? .zero
        let current = data.current
        // Before the kameti starts there's no current month: name its first month.
        let notStarted = current == nil && data.today < data.kameti.startMonth
        let shownMonth = current?.monthStart ?? (notStarted ? data.kameti.startMonth : nil)
        let month = shownMonth.map { DetailLogic.monthTitle($0).split(separator: " ").first.map(String.init)?.uppercased() ?? "" } ?? ""
        return VStack(alignment: .leading, spacing: KSpace.md) {
            Text(month.isEmpty
                 ? String(localized: "YOUR DUE", bundle: .module)
                 : (notStarted ? String(localized: "STARTS \(month) · FIRST DUE", bundle: .module) : String(localized: "\(month) · YOUR DUE", bundle: .module)))
                .kText(KTextToken.label, color: KColors.textOnBrand.opacity(0.85))
            if notStarted, let monthly = balance?.monthlyDue, monthly.isPositive {
                // Nothing is due before the first month: show the first payment.
                // Paid ahead of the start counts toward it (credit shows as a negative balance).
                let firstDue = monthly + owes
                if firstDue.isPositive {
                    KMoneyText(firstDue, style: .displayLg, tone: .onBrand)
                    dueChip(DetailLogic.dueDate(of: data.kameti, monthIndex: 1))
                } else {
                    Text("Paid in advance", bundle: .module).kText(KTextToken.displayLg, color: KColors.textOnBrand)
                }
            } else if owes.isPositive {
                KMoneyText(owes, style: .displayLg, tone: .onBrand)
            } else if balance?.monthlyDue.isPositive == false {
                Text("No share yet", bundle: .module).kText(KTextToken.displayLg, color: KColors.textOnBrand)
                Text("You'll owe something once the owner gives you a share of a slot.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textOnBrand.opacity(0.85))
            } else {
                Text("Paid up", bundle: .module).kText(KTextToken.displayLg, color: KColors.textOnBrand)
            }
            if let current, owes.isPositive {
                dueChip(DetailLogic.dueDate(of: data.kameti, monthIndex: current.monthIndex))
            }
        }
        .padding(KSpace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KColors.brand, in: RoundedRectangle(cornerRadius: 20))
    }

    private func dueChip(_ due: Date) -> some View {
        Label {
            Text("\(dueLabel(due)) · pay the owner by cash or bank", bundle: .module)
        } icon: { Image(systemName: "clock") }
            .kText(KTextToken.bodySm, color: KColors.textOnBrand)
            .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
    }

    private func dueLabel(_ due: Date) -> String {
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: data.today, to: due).day ?? 0
        switch days {
        case 0: return String(localized: "Due today", bundle: .module)
        case 1: return String(localized: "Due tomorrow, \(DetailLogic.dayMonth(due))", bundle: .module)
        default: return String(localized: "Due \(DetailLogic.dayMonth(due))", bundle: .module)
        }
    }

    // MARK: Your payout

    private func payoutCard(me: Member, monthIndex: Int, payout: Money) -> some View {
        let start = DetailLogic.monthStart(of: data.kameti, monthIndex: monthIndex)
        let others = DetailLogic.recipients(kameti: data.kameti, monthIndex: monthIndex, slots: data.slots, shares: data.shares, members: data.members)
            .filter { $0.member.id != me.id }.map(\.member.name)
        return card(title: String(localized: "Your payout", bundle: .module)) {
            HStack(spacing: KSpace.md + 2) {
                VStack(spacing: 0) {
                    Text(start.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)).uppercased())
                        .kText(KTextStyle(size: 11, weight: .semibold), color: KColors.onBrandSubtle)
                    Text(start.formatted(Date.FormatStyle(timeZone: .gmt).year()))
                        .kText(KTextStyle(size: 18, weight: .bold), color: KColors.onBrandSubtle).monospacedDigit()
                }
                .frame(width: 56, height: 56)
                .background(KColors.brandSubtle, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 2) {
                    KMoneyText(payout, style: .title)
                    Text(others.isEmpty
                         ? String(localized: "Whole slot · month \(monthIndex)", bundle: .module)
                         : String(localized: "Shared with \(others.formatted(.list(type: .and))) · month \(monthIndex)", bundle: .module))
                        .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                }
            }
        }
    }

    // MARK: This month's pot

    private func potCard(_ current: MonthCollectionRow) -> some View {
        let recipients = DetailLogic.recipients(kameti: data.kameti, monthIndex: current.monthIndex, slots: data.slots, shares: data.shares, members: data.members)
        let percent = KPotProgress.percent(of: current.received, target: current.target)
        // The whole card opens the schedule, not only the word in its corner.
        return NavigationLink {
            ScrollView { ScheduleSection(data: data).padding(KSpace.xl) }
                .background(KColors.background)
                .navigationTitle(String(localized: "Schedule", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
        } label: {
          card(title: String(localized: "This month's pot", bundle: .module), trailing: {
            HStack(spacing: 4) {
                Text("Schedule", bundle: .module)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
            }
            .kText(KTextToken.bodyStrong, color: KColors.brand)
        }) {
            HStack {
                Text(recipients.isEmpty
                     ? String(localized: "This month's pot", bundle: .module)
                     : String(localized: "To \(recipients.map { $0.member.id == data.me?.id ? "You" : $0.member.name }.joined(separator: " + "))", bundle: .module))
                    .kText(KTextToken.body)
                Spacer()
                Text("\(percent)%").kText(KTextToken.bodyStrong).monospacedDigit()
            }
            GeometryReader { proxy in
                Capsule().fill(KColors.surfaceSunken)
                    .overlay(alignment: .leading) {
                        Capsule().fill(KColors.brand).frame(width: proxy.size.width * CGFloat(min(max(percent, 0), 100)) / 100)
                    }
            }
            .frame(height: 8)
            Text("\(current.paidCount) of \(current.memberCount) members have paid", bundle: .module)
                .kText(KTextToken.subtitle, color: KColors.textSubtitle)
          }
          .contentShape(RoundedRectangle(cornerRadius: KRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the schedule", bundle: .module))
    }

    // MARK: Your payments

    private func paymentsCard(me: Member) -> some View {
        let mine = DetailLogic.newestFirst(data.payments.filter { $0.memberId == me.id && $0.voidedAt == nil })
        let upTo = data.current?.monthIndex ?? 0
        let rows = data.months.filter { $0.memberId == me.id && $0.monthIndex <= upTo }.sorted { $0.monthIndex < $1.monthIndex }
        return card(title: String(localized: "Your payments", bundle: .module)) {
            if rows.isEmpty {
                Text("You haven't made any payments yet.", bundle: .module).kText(KTextToken.subtitle, color: KColors.textSubtitle)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.monthIndex) { index, row in
                        let paid = mine.first { DetailLogic.monthIndex(of: $0.receivedOn, kameti: data.kameti) == row.monthIndex }
                        monthRow(row, payment: paid, showsDivider: index < rows.count - 1)
                    }
                }
            }
        }
    }

    private func monthRow(_ row: MemberMonthRow, payment: Payment?, showsDivider: Bool) -> some View {
        let settled = [.paid, .advance].contains(row.status)
        let tone = settled ? KColors.positive : (row.status == .partial ? KColors.warning : KColors.negative)
        let subtitle: String = {
            if settled, let payment {
                return String(localized: "Paid \(DetailLogic.dayMonth(payment.receivedOn)) · \(payment.method.label.lowercased())", bundle: .module)
            }
            if settled { return String(localized: "Paid", bundle: .module) }
            return row.status == .partial
                ? String(localized: "\(row.allocated.format()) paid so far", bundle: .module)
                : String(localized: "Not paid yet", bundle: .module)
        }()
        return VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                Image(systemName: settled ? "checkmark" : "circle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tone)
                    .frame(width: 32, height: 32)
                    .background(settled ? KColors.positiveSubtle : (row.status == .partial ? KColors.warningSubtle : KColors.negativeSubtle), in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(DetailLogic.monthTitle(row.monthStart).split(separator: " ").first.map(String.init) ?? "").kText(KTextToken.bodyStrong)
                    Text(subtitle).kText(KTextToken.caption, color: settled ? KColors.textSecondary : tone)
                }
                Spacer()
                KMoneyText(row.due, style: .title)
            }
            .padding(.vertical, KSpace.sm + 2)
            if showsDivider { Divider() }
        }
    }

    // MARK: Card shell

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        card(title: title, trailing: { EmptyView() }, content: content)
    }

    private func card<Trailing: View, Content: View>(
        title: String, @ViewBuilder trailing: () -> Trailing, @ViewBuilder content: () -> Content
    ) -> some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.md) {
                HStack {
                    Text(title.uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                    Spacer()
                    trailing()
                }
                content()
            }
        }
    }
}
