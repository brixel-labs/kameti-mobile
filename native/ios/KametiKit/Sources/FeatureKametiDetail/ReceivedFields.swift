import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Today, yesterday or a day the owner picks.
enum DateChoice: Equatable {
    case today, yesterday, custom

    /// The day the money came in, as a date-only (UTC) value.
    func date(today: Date, custom: Date) -> Date {
        switch self {
        case .today: today
        case .yesterday: Self.adding(-1, to: today)
        case .custom: RecordPaymentSheet.utcDate(from: custom)
        }
    }

    static func adding(_ days: Int, to date: Date) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = .gmt
        return utc.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// "Today", "Yesterday" or "9 Nov".
    func label(today: Date, custom: Date) -> String {
        switch self {
        case .today: String(localized: "Today", bundle: .module)
        case .yesterday: String(localized: "Yesterday", bundle: .module)
        case .custom: DetailLogic.dayMonth(date(today: today, custom: custom))
        }
    }
}

/// "Date received": quick chips and a calendar sheet.
struct ReceivedDateChooser: View {
    @Binding var choice: DateChoice
    @Binding var custom: Date
    let today: Date
    /// The first day that can be picked: when the kameti started.
    let earliest: Date
    @State private var picking = false

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            Text("Date received", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            KFlowLayout {
                KChip(String(localized: "Today", bundle: .module), isOn: choice == .today, style: .outlined) { choice = .today }
                KChip(String(localized: "Yesterday", bundle: .module), isOn: choice == .yesterday, style: .outlined) { choice = .yesterday }
                KChip(
                    choice == .custom ? choice.label(today: today, custom: custom) : String(localized: "Pick a date", bundle: .module),
                    symbol: "calendar", isOn: choice == .custom, style: .outlined
                ) { kDismissKeyboard(); picking = true }
            }
        }
        .kBottomSheet(isPresented: $picking, title: String(localized: "Date received", bundle: .module), detents: [.medium]) {
            // Tap a day and the sheet closes.
            KCalendarPicker(selection: $custom, in: RecordPaymentSheet.pickableRange(from: earliest, to: today)) { _ in
                choice = .custom
                picking = false
            }
        }
    }
}

/// "Method": cash, bank transfer or other, with a reference for a bank transfer.
struct MethodChooser: View {
    @Binding var method: PaymentMethod
    @Binding var reference: String

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            Text("Method", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            KFlowLayout {
                KChip(String(localized: "Cash", bundle: .module), symbol: "banknote", isOn: method == .cash, style: .outlined) { withAnimation(.smooth(duration: 0.25)) { method = .cash } }
                KChip(String(localized: "Bank transfer", bundle: .module), symbol: "building.columns", isOn: method == .bankTransfer, style: .outlined) { withAnimation(.smooth(duration: 0.25)) { method = .bankTransfer } }
                KChip(String(localized: "Other", bundle: .module), isOn: method == .other, style: .outlined) { withAnimation(.smooth(duration: 0.25)) { method = .other } }
            }
            if method == .bankTransfer {
                TextField(String(localized: "Reference no. (optional)", bundle: .module), text: $reference)
                    .padding(.horizontal, KSpace.md)
                    .frame(minHeight: 48)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(KColors.border))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
