import SwiftUI

/// A flat card with a 1 pt border (direction A has no card shadows).
public struct KCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        content
            .padding(KSpace.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
    }
}

/// An upper-cased section label with an optional action on the trailing side.
public struct KSectionHeader: View {
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title; self.actionTitle = actionTitle; self.action = action
    }

    public var body: some View {
        HStack {
            Text(title.uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .kText(KTextToken.bodyStrong, color: KColors.brand)
            }
        }
        .padding(.vertical, KSpace.sm)
    }
}

/// A member's initials on their palette colour. Decorative unless a
/// `label` is given.
public struct KAvatar: View {
    public enum Size: Sendable {
        case small, medium, large
        var dimension: CGFloat { switch self { case .small: 30; case .medium: 36; case .large: 48 } }
    }

    private let name: String
    private let colorIndex: Int
    private let size: Size

    public init(name: String, colorIndex: Int, size: Size = .medium) {
        self.name = name; self.colorIndex = colorIndex; self.size = size
    }

    /// "Ali Raza" -> "AR", "Hassan" -> "H".
    public nonisolated static func initials(of name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let letters = words.count >= 2 ? [words.first!, words.last!] : Array(words.prefix(1))
        return letters.compactMap(\.first).map { String($0).uppercased() }.joined()
    }

    public var body: some View {
        let palette = KColors.avatar(colorIndex)
        Text(Self.initials(of: name))
            .kText(KTextStyle(size: size.dimension * 0.36, weight: .semibold), color: palette.foreground)
            .frame(width: size.dimension, height: size.dimension)
            .background(palette.background, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Overlapping avatars, for "who receives this month".
public struct KAvatarStack: View {
    private let people: [(name: String, colorIndex: Int)]

    public init(_ people: [(name: String, colorIndex: Int)]) { self.people = people }

    public var body: some View {
        HStack(spacing: -10) {
            ForEach(Array(people.prefix(3).enumerated()), id: \.offset) { index, person in
                KAvatar(name: person.name, colorIndex: person.colorIndex, size: .medium)
                    .overlay(Circle().stroke(KColors.surface, lineWidth: 2))
                    .zIndex(Double(-index))
            }
        }
    }
}
