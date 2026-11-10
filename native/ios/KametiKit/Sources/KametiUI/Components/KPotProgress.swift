import KametiCore
import SwiftUI

/// This month's pot: "Rs 23,50,000 of 50,00,000 · 47%" over a bar.
///
/// `marked` is money marked in a tap-to-settle session but not saved yet; it
/// is added to the headline and drawn as a lighter segment after `collected`.
/// Past the target the bar is full and an "Over by Rs X" line flags it.
public struct KPotProgress: View {
    private let collected: Money
    private let target: Money
    private let marked: Money
    private let caption: String?

    public init(collected: Money, target: Money, marked: Money = .zero, caption: String? = nil) {
        self.collected = collected; self.target = target
        self.marked = marked; self.caption = caption
    }

    /// Whole percent of `target` covered by `amount` (may pass 100).
    public nonisolated static func percent(of amount: Money, target: Money) -> Int {
        target.rupees <= 0 ? 0 : (amount.rupees * 100) / target.rupees
    }

    /// Bar segments in permille of the target (integer maths, no Double).
    nonisolated static func segments(collected: Money, marked: Money, target: Money) -> (collected: Int, marked: Int, rest: Int) {
        func permille(_ m: Money) -> Int {
            target.rupees <= 0 ? 0 : min(max((m.rupees * 1000) / target.rupees, 0), 1000)
        }
        let c = permille(collected)
        let m = permille(collected + marked) - c
        return (c, m, 1000 - c - m)
    }

    public var body: some View {
        let total = collected + marked
        let percent = Self.percent(of: total, target: target)
        let over = total - target
        let bar = Self.segments(collected: collected, marked: marked, target: target)

        VStack(alignment: .leading, spacing: KSpace.sm) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline) {
                    KMoneyText(total, style: .display)
                    Spacer(minLength: KSpace.sm)
                    ofTarget(percent)
                }
                VStack(alignment: .leading, spacing: KSpace.xs) {
                    KMoneyText(total, style: .display)
                    ofTarget(percent)
                }
            }
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    segment(KColors.brand, bar.collected, geometry.size.width)
                    segment(KColors.brand.opacity(0.5), bar.marked, geometry.size.width)
                    Spacer(minLength: 0)
                }
                .background(KColors.surfaceSunken)
                .clipShape(Capsule())
            }
            .frame(height: KSpace.sm)
            if over.isPositive {
                Label(String(localized: "Over by \(over.format())", bundle: .module), systemImage: "info.circle")
                    .kText(KTextToken.caption, color: KColors.info)
            }
            if let caption {
                Text(caption).kText(KTextToken.caption, color: KColors.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(total.format()) collected of \(target.format()), \(percent) percent"))
    }

    private func ofTarget(_ percent: Int) -> some View {
        Text("of \(target.format(symbol: false)) · \(percent)%", bundle: .module)
            .kText(KTextToken.bodySm, color: KColors.textSecondary)
            .monospacedDigit()
    }

    private func segment(_ color: Color, _ permille: Int, _ width: CGFloat) -> some View {
        Rectangle().fill(color).frame(width: width * CGFloat(permille) / 1000)
    }
}
