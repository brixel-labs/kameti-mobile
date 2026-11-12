import KametiCore
import SwiftUI

/// The shape behind status chips and balance pills: an icon, a label and a
/// tinted background. Status is always icon plus text, never colour alone.
public struct KPill: View {
    private let label: String
    private let symbol: String?
    private let foreground: Color
    private let background: Color

    public init(_ label: String, symbol: String? = nil, foreground: Color, background: Color) {
        self.label = label; self.symbol = symbol
        self.foreground = foreground; self.background = background
    }

    public var body: some View {
        HStack(spacing: KSpace.xs) {
            if let symbol { Image(systemName: symbol).imageScale(.small).accessibilityHidden(true) }
            Text(label).monospacedDigit()
        }
        .kText(KTextStyle(size: 12, weight: .semibold), color: foreground)
        .padding(.horizontal, KSpace.sm)
        .padding(.vertical, KSpace.xs)
        .background(background, in: Capsule())
    }
}

/// A member's payment status for a month: paid, partial, unpaid, overdue,
/// credit (advance) or upcoming.
public struct KStatusChip: View {
    public enum Status: Sendable { case paid, partial, unpaid, overdue, credit, upcoming }

    private let status: Status
    private let label: String

    public init(_ status: Status, label: String) {
        self.status = status; self.label = label
    }

    public var body: some View {
        let style = Self.style(for: status)
        KPill(label, symbol: style.symbol, foreground: style.foreground, background: style.background)
    }

    nonisolated static func style(for status: Status) -> (symbol: String, foreground: Color, background: Color) {
        switch status {
        case .paid: ("checkmark", KColors.positive, KColors.positiveSubtle)
        case .partial: ("circle.lefthalf.filled", KColors.warning, KColors.warningSubtle)
        case .unpaid: ("circle", KColors.negative, KColors.negativeSubtle)
        case .overdue: ("clock", KColors.negative, KColors.negativeSubtle)
        case .credit: ("plus.circle", KColors.info, KColors.infoSubtle)
        case .upcoming: ("ellipsis", KColors.textSecondary, KColors.surfaceSunken)
        }
    }
}

/// A member's running balance as a pill. A positive balance is money owed
/// ("Owes Rs 4,50,000"), zero is "Settled", a negative balance is credit.
public struct KBalancePill: View {
    /// What a balance means, independent of how it is drawn.
    public enum State: Equatable, Sendable {
        case owes(Money), settled, credit(Money)

        public init(balance: Money) {
            if balance.isPositive { self = .owes(balance) }
            else if balance.isZero { self = .settled }
            else { self = .credit(balance.abs()) }
        }
    }

    private let state: State

    public init(balance: Money) { state = State(balance: balance) }

    public var body: some View {
        switch state {
        case .owes(let amount):
            KPill(String(localized: "Owes \(amount.format())", bundle: .module),
                  symbol: "arrow.up", foreground: KColors.negative, background: KColors.negativeSubtle)
        case .settled:
            KPill(String(localized: "Settled", bundle: .module),
                  symbol: "checkmark", foreground: KColors.positive, background: KColors.positiveSubtle)
        case .credit(let amount):
            KPill(String(localized: "Credit \(amount.format())", bundle: .module),
                  symbol: "plus", foreground: KColors.info, background: KColors.infoSubtle)
        }
    }
}
