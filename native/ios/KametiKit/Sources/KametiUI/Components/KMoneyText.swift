import KametiCore
import SwiftUI

/// The only way to show an amount (`Rs 24,00,000`, compact `24 L`).
public struct KMoneyText: View {
    public enum Style: Sendable { case body, title, display, displayLg }
    public enum Tone: Sendable { case neutral, positive, negative }

    private let amount: Money
    private let style: Style
    private let tone: Tone
    private let compact: Bool

    public init(_ amount: Money, style: Style = .body, tone: Tone = .neutral, compact: Bool = false) {
        self.amount = amount; self.style = style; self.tone = tone; self.compact = compact
    }

    public var body: some View {
        Text(compact ? amount.formatCompact() : amount.format())
            .kText(textStyle, color: color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilityLabel(Text("\(amount.rupees) rupees"))
    }

    private var textStyle: KTextStyle {
        switch style {
        case .body: KTextToken.amount
        case .title: KTextStyle(size: 17, weight: .semibold, tabular: true)
        case .display: KTextToken.display
        case .displayLg: KTextToken.displayLg
        }
    }

    private var color: Color {
        switch tone {
        case .neutral: KColors.textPrimary
        case .positive: KColors.positive
        case .negative: KColors.negative
        }
    }
}
