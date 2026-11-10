import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// A list row: avatar or icon, title, optional subtitle and a trailing view.
struct DetailRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String?
    var showsDivider = true
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                leading
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).kText(KTextToken.bodyStrong)
                    if let subtitle {
                        Text(subtitle).kText(KTextToken.bodySm, color: KColors.textSecondary)
                    }
                }
                Spacer(minLength: KSpace.sm)
                trailing
            }
            .padding(.vertical, KSpace.md)
            if showsDivider { Divider() }
        }
    }
}

extension DetailRow where Leading == KAvatar {
    init(
        member: Member, in members: [Member], title: String? = nil, subtitle: String? = nil,
        showsDivider: Bool = true, @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            title: title ?? member.name, subtitle: subtitle, showsDivider: showsDivider,
            leading: { KAvatar(name: member.name, colorIndex: Self.colorIndex(of: member, in: members), size: .medium) },
            trailing: trailing
        )
    }

    /// The member's stored colour index, else their position in the list.
    nonisolated static func colorIndex(of member: Member, in members: [Member]) -> Int {
        Int(member.color ?? "") ?? max(members.firstIndex(of: member) ?? 0, 0)
    }
}

/// The state of a month's collection and payout, as a plain coloured pill.
struct CollectionStatePill: View {
    let state: MonthCollectionState

    var body: some View {
        let style = Self.style(for: state)
        KPill(style.label, foreground: style.foreground, background: style.background)
    }

    nonisolated static func style(for state: MonthCollectionState) -> (label: String, foreground: Color, background: Color) {
        switch state {
        case .upcoming: (String(localized: "Upcoming", bundle: .module), KColors.textSecondary, KColors.surfaceSunken)
        case .collecting, .partiallyPaidOut: (String(localized: "Collecting", bundle: .module), KColors.info, KColors.infoSubtle)
        case .fullyCollected: (String(localized: "Collected", bundle: .module), KColors.positive, KColors.positiveSubtle)
        case .paidOut: (String(localized: "Paid out", bundle: .module), KColors.positive, KColors.positiveSubtle)
        case .paidOutShort: (String(localized: "Paid out short", bundle: .module), KColors.warning, KColors.warningSubtle)
        }
    }

    nonisolated static func isPaidOut(_ state: MonthCollectionState) -> Bool {
        state == .paidOut || state == .paidOutShort
    }
}

/// A member's join status as icon plus text.
struct JoinStatusPill: View {
    let status: JoinStatus

    var body: some View {
        let style = Self.style(for: status)
        KPill(style.label, symbol: style.symbol, foreground: style.foreground, background: style.background)
    }

    nonisolated static func style(for status: JoinStatus) -> (label: String, symbol: String, foreground: Color, background: Color) {
        switch status {
        case .joined: (String(localized: "Joined", bundle: .module), "checkmark", KColors.positive, KColors.positiveSubtle)
        case .invited: (String(localized: "Invited", bundle: .module), "paperplane", KColors.info, KColors.infoSubtle)
        case .pendingApproval: (String(localized: "Waiting for approval", bundle: .module), "hourglass", KColors.warning, KColors.warningSubtle)
        case .notInvited: (String(localized: "Not invited", bundle: .module), "person.badge.plus", KColors.textSecondary, KColors.surfaceSunken)
        case .declined: (String(localized: "Declined", bundle: .module), "xmark", KColors.negative, KColors.negativeSubtle)
        }
    }
}

extension MonthStatusCode {
    /// Chip status and label for a member's month.
    var chip: (status: KStatusChip.Status, label: String) {
        switch self {
        case .paid: (.paid, String(localized: "Paid", bundle: .module))
        case .partial: (.partial, String(localized: "Partial", bundle: .module))
        case .unpaid: (.unpaid, String(localized: "Unpaid", bundle: .module))
        case .overdue: (.overdue, String(localized: "Overdue", bundle: .module))
        case .advance: (.credit, String(localized: "Advance", bundle: .module))
        case .upcoming: (.upcoming, String(localized: "Upcoming", bundle: .module))
        }
    }
}

extension PaymentMethod {
    var label: String {
        switch self {
        case .cash: String(localized: "Cash", bundle: .module)
        case .bankTransfer: String(localized: "Bank", bundle: .module)
        case .other: String(localized: "Other", bundle: .module)
        }
    }
}

/// A first name for tight spaces ("Ali Raza" becomes "Ali").
func firstName(_ name: String) -> String { name.split(separator: " ").first.map(String.init) ?? name }

/// One payment or payout in the money list: a round icon, who and how, and the
/// amount. A voided one is greyed and struck through (board A v2 · Payments).
struct PaymentRow: View {
    enum Kind { case received, paidOut }

    let kind: Kind
    let title: String
    let subtitle: String
    let amount: Money
    var isVoided = false
    var showsDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                Image(systemName: isVoided ? "nosign" : (kind == .received ? "arrow.down" : "arrow.up"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isVoided ? KColors.textSecondary : (kind == .received ? KColors.positive : KColors.warning))
                    .frame(width: 36, height: 36)
                    .background(isVoided ? KColors.surfaceSunken : (kind == .received ? KColors.positiveSubtle : KColors.warningSubtle), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).kText(KTextToken.bodyStrong, color: isVoided ? KColors.textSecondary : KColors.textPrimary)
                    Text(subtitle).kText(KTextToken.caption, color: KColors.textSecondary)
                }
                Spacer(minLength: KSpace.sm)
                KMoneyText(amount, style: .title, tone: .neutral)
                    .strikethrough(isVoided)
                    .opacity(isVoided ? 0.6 : 1)
            }
            .padding(.vertical, KSpace.sm + 2)
            if showsDivider { Divider() }
        }
    }
}

/// The payout month grid with a legend and a details card for the selected
/// month (board A v2 · Schedule, FR-62).
struct ScheduleSection: View {
    let data: KametiDetailData
    @State private var selected: Int?

    private var currentIndex: Int? { data.current?.monthIndex }

    var body: some View {
        let kameti = data.kameti
        let byMonth = Dictionary(data.collections.map { ($0.monthIndex, $0) }, uniquingKeysWith: { first, _ in first })
        let myId = data.me?.id
        let columns = Array(repeating: GridItem(.flexible(), spacing: KSpace.sm), count: 4)
        let chosen = selected ?? currentIndex

        VStack(alignment: .leading, spacing: KSpace.lg) {
            legend
            LazyVGrid(columns: columns, spacing: KSpace.sm) {
                ForEach(1...max(kameti.monthsN, 1), id: \.self) { month in
                    let recipients = DetailLogic.recipients(kameti: kameti, monthIndex: month, slots: data.slots, shares: data.shares, members: data.members)
                    let paidOut = byMonth[month].map { CollectionStatePill.isPaidOut($0.state) } ?? false
                    let names = recipients.map { $0.member.id == myId ? String(localized: "You", bundle: .module) : firstName($0.member.name) }.joined(separator: " + ")
                    MonthTile(
                        monthStart: DetailLogic.monthStart(of: kameti, monthIndex: month),
                        names: paidOut ? names + " ✓" : names,
                        isPaidOut: paidOut,
                        isNow: month == currentIndex,
                        isYourTurn: recipients.contains { $0.member.id == myId },
                        isSelected: month == chosen
                    )
                    .onTapGesture { withAnimation(.smooth(duration: 0.2)) { selected = month } }
                }
            }
            if let chosen {
                MonthDetails(data: data, monthIndex: chosen, row: byMonth[chosen])
                    .id(chosen)
                    .transition(.opacity)
            } else {
                Text("Pick a month to see who receives the pot.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: KSpace.md) {
            legendItem(String(localized: "Paid out", bundle: .module)) { RoundedRectangle(cornerRadius: 3).fill(KColors.brand) }
            legendItem(String(localized: "Now", bundle: .module)) { RoundedRectangle(cornerRadius: 3).stroke(KColors.info, lineWidth: 2) }
            legendItem(String(localized: "Your turn", bundle: .module)) {
                RoundedRectangle(cornerRadius: 3).fill(KColors.warningSubtle).overlay(RoundedRectangle(cornerRadius: 3).stroke(KColors.warning))
            }
        }
        .kText(KTextToken.caption, color: KColors.textSecondary)
    }

    private func legendItem<Mark: View>(_ title: String, @ViewBuilder mark: () -> Mark) -> some View {
        HStack(spacing: 6) { mark().frame(width: 12, height: 12); Text(title) }
    }
}

private struct MonthTile: View {
    let monthStart: Date
    let names: String
    let isPaidOut: Bool
    let isNow: Bool
    let isYourTurn: Bool
    let isSelected: Bool

    var body: some View {
        let label = monthStart.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated).year(.twoDigits)).uppercased()
        VStack(alignment: .leading, spacing: 0) {
            Text(isNow ? "\(label) · \(String(localized: "Now", bundle: .module).uppercased())" : label)
                .kText(KTextStyle(size: 12, weight: .bold), color: labelColor)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 2)
            Text(names)
                .kText(KTextStyle(size: 12, weight: .medium), color: isPaidOut ? KColors.textOnBrand : (isYourTurn ? KColors.warning : KColors.textPrimary))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
        .padding(KSpace.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .aspectRatio(1, contentMode: .fit)
        .background(background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(border, lineWidth: isNow || isSelected ? 2 : 1))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var labelColor: Color { isPaidOut ? KColors.textOnBrand.opacity(0.8) : (isNow ? KColors.info : (isYourTurn ? KColors.warning : KColors.textSecondary)) }
    private var background: Color { isPaidOut ? KColors.brand : (isYourTurn ? KColors.warningSubtle : KColors.surface) }
    private var border: Color { isNow ? KColors.info : (isSelected ? KColors.textPrimary : (isYourTurn ? KColors.warning : (isPaidOut ? KColors.brand : KColors.border))) }
}

private struct MonthDetails: View {
    let data: KametiDetailData
    let monthIndex: Int
    let row: MonthCollectionRow?

    var body: some View {
        let recipients = DetailLogic.recipients(kameti: data.kameti, monthIndex: monthIndex, slots: data.slots, shares: data.shares, members: data.members)
        let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: monthIndex))
        KCard {
            VStack(alignment: .leading, spacing: KSpace.sm + 2) {
                HStack {
                    Text("\(month) · month \(monthIndex)", bundle: .module).kText(KTextToken.bodyStrong)
                    Spacer()
                    if let row { CollectionStatePill(state: row.state) }
                }
                if recipients.isEmpty {
                    Text("No one is paid out this month yet.", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                } else {
                    ForEach(recipients) { recipient in
                        HStack {
                            Text(recipient.member.id == data.me?.id ? String(localized: "You", bundle: .module) : recipient.member.name).kText(KTextToken.body)
                            Spacer()
                            KMoneyText(recipient.payout, style: .title)
                        }
                    }
                }
            }
        }
    }
}
