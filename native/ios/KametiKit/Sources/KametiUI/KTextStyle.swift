import SwiftUI

/// A text style from the design tokens. The size is the base size at the
/// default Dynamic Type setting and scales with the user's text size.
public struct KTextStyle: Sendable {
    public let size: CGFloat
    public let weight: Font.Weight
    public let tracking: CGFloat
    /// Fixed-width digits, so amounts line up in columns.
    public let tabular: Bool

    public init(size: CGFloat, weight: Font.Weight, tracking: CGFloat = 0, tabular: Bool = false) {
        self.size = size; self.weight = weight; self.tracking = tracking; self.tabular = tabular
    }
}

private struct KTextModifier: ViewModifier {
    let style: KTextStyle
    let color: Color
    @ScaledMetric private var size: CGFloat

    init(style: KTextStyle, color: Color) {
        self.style = style
        self.color = color
        _size = ScaledMetric(wrappedValue: style.size, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        var font = Font.system(size: size, weight: style.weight)
        if style.tabular { font = font.monospacedDigit() }
        return content
            .font(font)
            .tracking(style.tracking)
            .foregroundStyle(color)
    }
}

extension View {
    /// Applies a design-token text style: `Text("Title").kText(KTextToken.title)`.
    public func kText(_ style: KTextStyle, color: Color = KColors.textPrimary) -> some View {
        modifier(KTextModifier(style: style, color: color))
    }
}
