import SwiftUI

/// Two buttons side by side, the first a third of the width and the second
/// two thirds (the designs' "Decline | Join" rows). Unlike an HStack with a
/// layout priority, the first button can never be squeezed away.
struct SplitRow: Layout {
    var spacing: CGFloat = 12
    /// The first column's share of the width (a third by default; 0.5 = equal).
    var firstShare: CGFloat = 1.0 / 3

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let widths = split(width)
        let height = zip(subviews, widths).map { $0.sizeThatFits(ProposedViewSize(width: $1, height: proposal.height)).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, width) in zip(subviews, split(bounds.width)) {
            subview.place(at: CGPoint(x: x, y: bounds.midY), anchor: .leading, proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func split(_ width: CGFloat) -> [CGFloat] {
        let usable = max(width - spacing, 0)
        return [usable * firstShare, usable * (1 - firstShare)]
    }
}
