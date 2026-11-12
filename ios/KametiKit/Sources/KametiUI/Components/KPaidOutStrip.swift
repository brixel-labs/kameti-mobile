import SwiftUI

/// The strip shown once a month is paid out: who was paid (avatars with a
/// check), how much, and when. Green, or amber when the payout fell short.
/// Used on the Home card and on the Overview tab.
public struct KPaidOutStrip: View {
    private let people: [(name: String, colorIndex: Int)]
    private let title: String
    private let subtitle: String
    private let isShort: Bool

    public init(people: [(name: String, colorIndex: Int)], title: String, subtitle: String, isShort: Bool = false) {
        self.people = people
        self.title = title
        self.subtitle = subtitle
        self.isShort = isShort
    }

    public var body: some View {
        HStack(spacing: KSpace.md) {
            KAvatarStack(people.map { ($0.name, $0.colorIndex) }, showsCheck: true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).kText(KTextToken.bodyStrong, color: isShort ? KColors.warning : KColors.positiveDeep)
                Text(subtitle).kText(KTextToken.subtitleSmall, color: isShort ? KColors.textSubtitle : KColors.positiveDeepSubtitle)
            }
            Spacer(minLength: 0)
        }
        .padding(KSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isShort ? KColors.warningSubtle : KColors.positiveSubtle, in: RoundedRectangle(cornerRadius: 12))
    }
}
