import SwiftUI

/// The first-time Home picture: a dashed circle, three people-dots and a green
/// tile with a plus (board AF · Home first time).
public struct KEmptyIllustration: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 120, size.height / 96)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: (size.width - 120 * scale) / 2 + x * scale, y: (size.height - 96 * scale) / 2 + y * scale)
            }
            let ring = Path(ellipseIn: CGRect(origin: point(28, 16), size: CGSize(width: 64 * scale, height: 64 * scale)))
            context.stroke(ring, with: .color(KColors.brandSubtle), style: StrokeStyle(lineWidth: 3 * scale, dash: [6 * scale, 6 * scale]))
            for (x, y) in [(60.0, 16.0), (88.0, 62.0), (32.0, 62.0)] {
                let dot = Path(ellipseIn: CGRect(origin: point(CGFloat(x) - 9, CGFloat(y) - 9), size: CGSize(width: 18 * scale, height: 18 * scale)))
                context.fill(dot, with: .color(KColors.brandSubtle))
                context.stroke(dot, with: .color(KColors.brand), lineWidth: 2 * scale)
            }
            let tile = Path(roundedRect: CGRect(origin: point(48, 38), size: CGSize(width: 24 * scale, height: 20 * scale)), cornerRadius: 5 * scale)
            context.fill(tile, with: .color(KColors.brand))
            var plus = Path()
            plus.move(to: point(54, 48)); plus.addLine(to: point(66, 48))
            plus.move(to: point(60, 42)); plus.addLine(to: point(60, 54))
            context.stroke(plus, with: .color(KColors.textOnBrand), style: StrokeStyle(lineWidth: 2.4 * scale, lineCap: .round))
        }
        .frame(width: 120, height: 96)
        .accessibilityHidden(true)
    }
}
