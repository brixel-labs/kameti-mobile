import KametiCore
import SwiftUI

/// The hours reminders can go out at (06:00 to 22:00, Pakistan time) as a list of rows with a
/// tick on the chosen one. The whole row is the button. Shown in a sheet, in the create wizard
/// and in Edit kameti.
public struct KReminderTimeList: View {
    private let selection: Int
    private let onPick: (Int) -> Void

    public init(selection: Int, onPick: @escaping (Int) -> Void) {
        self.selection = selection
        self.onPick = onPick
    }

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(ReminderTime.hours), id: \.self) { hour in
                    Button { onPick(hour) } label: {
                        HStack {
                            Text(ReminderTime.label(hour)).kText(KTextToken.body)
                            Spacer()
                            if selection == hour { Image(systemName: "checkmark").foregroundStyle(KColors.brand) }
                        }
                        .padding(.horizontal, KSpace.xl)
                        .padding(.vertical, KSpace.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selection == hour ? .isSelected : [])
                    Divider().padding(.leading, KSpace.xl)
                }
            }
        }
    }
}
