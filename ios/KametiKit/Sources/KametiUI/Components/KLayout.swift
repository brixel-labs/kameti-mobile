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
    private let showsChevron: Bool

    /// `showsChevron` adds a trailing chevron so the action reads as a link.
    public init(_ title: String, actionTitle: String? = nil, showsChevron: Bool = false, action: (() -> Void)? = nil) {
        self.title = title; self.actionTitle = actionTitle; self.action = action; self.showsChevron = showsChevron
    }

    public var body: some View {
        HStack {
            Text(title.uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        if showsChevron { Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)) }
                    }
                    .kText(KTextToken.bodyStrong, color: KColors.brand)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
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

/// Overlapping avatars, for "who receives this month". With `showsCheck`, each
/// avatar gets a small green tick (already paid out).
public struct KAvatarStack: View {
    private let people: [(name: String, colorIndex: Int)]
    private let showsCheck: Bool
    private let limit: Int
    private let showsOverflow: Bool
    private let size: KAvatar.Size

    /// Up to `limit` faces. With `showsOverflow`, the rest show as a "+N" bubble.
    public init(
        _ people: [(name: String, colorIndex: Int)], showsCheck: Bool = false,
        limit: Int = 3, showsOverflow: Bool = false, size: KAvatar.Size = .medium
    ) {
        self.people = people; self.showsCheck = showsCheck
        self.limit = limit; self.showsOverflow = showsOverflow; self.size = size
    }

    public var body: some View {
        let overflow = showsOverflow ? max(people.count - limit, 0) : 0
        HStack(spacing: -10) {
            ForEach(Array(people.prefix(limit).enumerated()), id: \.offset) { index, person in
                KAvatar(name: person.name, colorIndex: person.colorIndex, size: size)
                    .overlay(Circle().stroke(KColors.surface, lineWidth: 2))
                    .overlay(alignment: .bottomTrailing) {
                        if showsCheck {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundStyle(KColors.textOnBrand)
                                .frame(width: 16, height: 16)
                                .background(KColors.brand, in: Circle())
                                .overlay(Circle().stroke(KColors.surface, lineWidth: 2))
                                .offset(x: 2, y: 2)
                        }
                    }
                    .zIndex(Double(-index))
            }
            if overflow > 0 {
                Text(verbatim: "+\(overflow)")
                    .kText(KTextStyle(size: size.dimension * 0.33, weight: .semibold), color: KColors.textSecondary)
                    .frame(width: size.dimension, height: size.dimension)
                    .background(KColors.surfaceSunken, in: Circle())
                    .overlay(Circle().stroke(KColors.surface, lineWidth: 2))
                    .zIndex(Double(-limit))
            }
        }
        .accessibilityHidden(true)
    }
}
