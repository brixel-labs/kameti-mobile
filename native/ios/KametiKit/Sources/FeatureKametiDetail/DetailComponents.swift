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

/// The state of a month's collection and payout, as icon plus text.
struct CollectionStatePill: View {
    let state: MonthCollectionState

    var body: some View {
        let style = Self.style(for: state)
        KPill(style.label, symbol: style.symbol, foreground: style.foreground, background: style.background)
    }

    nonisolated static func style(for state: MonthCollectionState) -> (label: String, symbol: String, foreground: Color, background: Color) {
        switch state {
        case .upcoming: (String(localized: "Upcoming", bundle: .module), "ellipsis", KColors.textSecondary, KColors.surfaceSunken)
        case .collecting, .partiallyPaidOut: (String(localized: "Collecting", bundle: .module), "circle.lefthalf.filled", KColors.warning, KColors.warningSubtle)
        case .fullyCollected: (String(localized: "Collected", bundle: .module), "checkmark", KColors.positive, KColors.positiveSubtle)
        case .paidOut: (String(localized: "Paid out", bundle: .module), "checkmark.circle.fill", KColors.positive, KColors.positiveSubtle)
        case .paidOutShort: (String(localized: "Paid out short", bundle: .module), "exclamationmark.circle", KColors.warning, KColors.warningSubtle)
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

/// One payment: who, when, how much; a voided one is struck through.
struct PaymentRow: View {
    let payment: Payment
    let member: Member?
    let members: [Member]
    var showsMember = true
    var showsDivider = true

    var body: some View {
        let subtitle = DetailLogic.paymentSubtitle(payment, methodLabel: payment.method.label) {
            String(localized: "paid by \($0)", bundle: .module)
        }
        let title = showsMember ? (member?.name ?? "") : payment.receivedOn.formatted(Date.FormatStyle(timeZone: .gmt).day().month(.abbreviated).year())
        let dated = showsMember
            ? payment.receivedOn.formatted(Date.FormatStyle(timeZone: .gmt).day().month(.abbreviated)) + " · " + subtitle
            : subtitle
        DetailRow(title: title, subtitle: dated, showsDivider: showsDivider) {
            if showsMember, let member {
                KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: members), size: .medium)
            } else {
                Image(systemName: "banknote").foregroundStyle(KColors.textSecondary).frame(width: 36)
            }
        } trailing: {
            VStack(alignment: .trailing, spacing: 2) {
                KMoneyText(payment.amount, tone: payment.voidedAt == nil ? .neutral : .negative)
                    .strikethrough(payment.voidedAt != nil)
                if payment.voidedAt != nil {
                    Text("Voided", bundle: .module).kText(KTextToken.caption, color: KColors.negative)
                }
            }
        }
        .opacity(payment.voidedAt == nil ? 1 : 0.7)
    }
}

/// The payout month grid with a details card for the selected month (FR-62).
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
            LazyVGrid(columns: columns, spacing: KSpace.sm) {
                ForEach(1...max(kameti.monthsN, 1), id: \.self) { month in
                    let recipients = DetailLogic.recipients(kameti: kameti, monthIndex: month, slots: data.slots, shares: data.shares, members: data.members)
                    MonthTile(
                        monthStart: DetailLogic.monthStart(of: kameti, monthIndex: month),
                        isPaidOut: byMonth[month].map { CollectionStatePill.isPaidOut($0.state) } ?? false,
                        isNow: month == currentIndex,
                        isYourTurn: recipients.contains { $0.member.id == myId },
                        isSelected: month == chosen
                    )
                    .onTapGesture { selected = month }
                }
            }
            if let chosen {
                MonthDetails(data: data, monthIndex: chosen, row: byMonth[chosen])
            } else {
                Text("Pick a month to see who receives the pot.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
            }
        }
    }
}

private struct MonthTile: View {
    let monthStart: Date
    let isPaidOut: Bool
    let isNow: Bool
    let isYourTurn: Bool
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(monthStart.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)))
                .kText(KTextToken.bodyStrong, color: isYourTurn ? KColors.onYourTurn : KColors.textPrimary)
            Text(monthStart.formatted(Date.FormatStyle(timeZone: .gmt).year(.twoDigits)))
                .kText(KTextToken.caption, color: isYourTurn ? KColors.onYourTurn : KColors.textSecondary)
            Image(systemName: isPaidOut ? "checkmark.circle.fill" : (isNow ? "circle.inset.filled" : "circle"))
                .imageScale(.small)
                .foregroundStyle(isPaidOut ? KColors.positive : (isNow ? KColors.brand : KColors.textTertiary))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(isYourTurn ? KColors.yourTurn : KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
        .overlay(
            RoundedRectangle(cornerRadius: KRadius.input)
                .stroke(isSelected ? KColors.brand : (isYourTurn ? KColors.yourTurnBorder : KColors.border), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct MonthDetails: View {
    let data: KametiDetailData
    let monthIndex: Int
    let row: MonthCollectionRow?

    var body: some View {
        let recipients = DetailLogic.recipients(kameti: data.kameti, monthIndex: monthIndex, slots: data.slots, shares: data.shares, members: data.members)
        let month = DetailLogic.monthTitle(DetailLogic.monthStart(of: data.kameti, monthIndex: monthIndex))
        KCard {
            VStack(alignment: .leading, spacing: KSpace.sm) {
                HStack {
                    Text("\(month) · month \(monthIndex)", bundle: .module).kText(KTextToken.bodyStrong)
                    Spacer()
                    if let row { CollectionStatePill(state: row.state) }
                }
                if recipients.isEmpty {
                    Text("No one is paid out this month yet.", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                } else {
                    ForEach(Array(recipients.enumerated()), id: \.element.id) { index, recipient in
                        DetailRow(
                            member: recipient.member, in: data.members,
                            title: recipient.member.id == data.me?.id ? String(localized: "You", bundle: .module) : nil,
                            showsDivider: index < recipients.count - 1
                        ) { KMoneyText(recipient.payout) }
                    }
                }
            }
        }
    }
}
