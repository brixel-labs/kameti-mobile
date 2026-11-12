import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// What the owner can change on a running kameti, and the rules for it
/// (FR-10, FR-34): name, description, due day and reminder days. The slot
/// amount, months, start month and slot limit are fixed once it starts.
struct EditKametiForm: Equatable {
    static let quickDays = [5, 10, 15]
    static let dueDays = 1...28

    var name: String
    var description: String
    var dueDay: Int
    var reminderDays: [Int]

    init(_ kameti: Kameti) {
        name = kameti.name
        description = kameti.description ?? ""
        dueDay = kameti.dueDay
        reminderDays = kameti.reminderDays.sorted()
    }

    private func trimmed(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var nameError: String? {
        (3...40).contains(trimmed(name).count) ? nil : String(localized: "The name must be 3 to 40 characters.", bundle: .module)
    }

    var descriptionError: String? {
        trimmed(description).count <= 500 ? nil : String(localized: "Keep the description under 500 characters.", bundle: .module)
    }

    var isValid: Bool { nameError == nil && descriptionError == nil && Self.dueDays.contains(dueDay) }

    /// A later due day keeps the reminders; an earlier one drops reminders
    /// after it (same as the create wizard).
    mutating func setDueDay(_ day: Int) {
        dueDay = day
        reminderDays = reminderDays.filter { $0 <= day }
    }

    mutating func toggleReminder(_ day: Int) {
        if reminderDays.contains(day) { reminderDays.removeAll { $0 == day } } else { reminderDays = (reminderDays + [day]).sorted() }
    }

    /// Only the fields that changed; `nil` when nothing did. An empty
    /// description clears it.
    func changes(from kameti: Kameti) -> KametiChanges? {
        var changes = KametiChanges()
        if trimmed(name) != kameti.name { changes.name = trimmed(name) }
        if trimmed(description) != (kameti.description ?? "") { changes.description = trimmed(description) }
        if dueDay != kameti.dueDay { changes.dueDay = dueDay }
        if reminderDays != kameti.reminderDays.sorted() { changes.reminderDays = reminderDays }
        let none = changes.name == nil && changes.description == nil && changes.dueDay == nil && changes.reminderDays == nil
        return none ? nil : changes
    }

    static func ordinal(_ day: Int) -> String {
        let suffix = switch (day % 100, day % 10) {
        case (11...13, _): "th"
        case (_, 1): "st"
        case (_, 2): "nd"
        case (_, 3): "rd"
        default: "th"
        }
        return "\(day)\(suffix)"
    }
}

/// Edit kameti (board AE-1), in the app's bottom sheet: one form, the values
/// that are fixed once started listed with the reason, and Save pinned at the
/// bottom.
struct EditKametiView: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let onDone: () -> Void

    @State private var form: EditKametiForm
    @State private var submitted = false
    @State private var isBusy = false
    @State private var failure: Failure?
    @State private var pickingDay = false

    init(data: KametiDetailData, model: KametiDetailViewModel, onDone: @escaping () -> Void) {
        self.data = data
        self.model = model
        self.onDone = onDone
        _form = State(initialValue: EditKametiForm(data.kameti))
    }

    private var changes: KametiChanges? { form.changes(from: data.kameti) }

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    field(String(localized: "Name", bundle: .module), text: $form.name, error: submitted ? form.nameError : nil, capitalization: .words)
                    field(
                        String(localized: "Description (optional)", bundle: .module), text: $form.description,
                        prompt: String(localized: "e.g. Cousins, Rs 2.5 lakh a month", bundle: .module),
                        error: submitted ? form.descriptionError : nil, capitalization: .sentences
                    )
                    dueDaySection
                    remindersSection
                    fixedCard
                    if let failure {
                        Label(failure.userMessage, systemImage: "exclamationmark.triangle").kText(KTextToken.bodySm, color: KColors.negative)
                    }
                }
                .padding(.horizontal, KSpace.xl)
                .padding(.top, KSpace.xxs)
                .padding(.bottom, KSpace.lg)
            }
            .kDismissesKeyboard()
            // Save stays at the bottom while the form scrolls.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button(action: save) {
                    ZStack {
                        Text("Save changes", bundle: .module).opacity(isBusy ? 0 : 1)
                        if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
                    }
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(KColors.brand)
                .controlSize(.large)
                .disabled(changes == nil)
                .allowsHitTesting(!isBusy)
                .padding(.horizontal, KSpace.xl)
                .padding(.top, KSpace.sm)
                .padding(.bottom, KSpace.md)
            }
    }

    // MARK: Sections

    private func label(_ text: String) -> some View {
        Text(text).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
    }

    private func field(
        _ title: String, text: Binding<String>, prompt: String = "", error: String?, capitalization: TextInputAutocapitalization
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            label(title)
            TextField(prompt, text: text)
                .textInputAutocapitalization(capitalization)
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: 48)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(error == nil ? KColors.border : KColors.negative))
            if let error { Text(error).kText(KTextToken.caption, color: KColors.negative) }
        }
    }

    private var dueDaySection: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Members pay by", bundle: .module))
            KFlowLayout {
                ForEach(EditKametiForm.quickDays, id: \.self) { day in
                    KChip(EditKametiForm.ordinal(day), isOn: form.dueDay == day, style: .outlined) {
                        withAnimation(.smooth(duration: 0.3)) { form.setDueDay(day) }
                    }
                }
                let custom = !EditKametiForm.quickDays.contains(form.dueDay)
                // "Other" opens a list of every day (same as the create wizard).
                KChip(custom ? EditKametiForm.ordinal(form.dueDay) : String(localized: "Other", bundle: .module), isOn: custom, style: .outlined) {
                    kDismissKeyboard()
                    pickingDay = true
                }
            }
        }
        .kBottomSheet(isPresented: $pickingDay, title: String(localized: "Pick the due day", bundle: .module), detents: [.medium, .large]) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(EditKametiForm.dueDays), id: \.self) { day in
                        Button {
                            withAnimation(.smooth(duration: 0.3)) { form.setDueDay(day) }
                            pickingDay = false
                        } label: {
                            HStack {
                                Text(EditKametiForm.ordinal(day)).kText(KTextToken.body)
                                Spacer()
                                if form.dueDay == day { Image(systemName: "checkmark").foregroundStyle(KColors.brand) }
                            }
                            .padding(.horizontal, KSpace.xl)
                            .padding(.vertical, KSpace.md)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, KSpace.xl)
                    }
                }
            }
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: KSpace.sm) {
            label(String(localized: "Remind on these days", bundle: .module))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: KSpace.sm), count: 5), spacing: KSpace.sm) {
                ForEach(1...form.dueDay, id: \.self) { day in
                    KDayTile("\(day)", isOn: form.reminderDays.contains(day)) { form.toggleReminder(day) }
                        .accessibilityLabel(Text("Remind on day \(day)", bundle: .module))
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            .animation(.smooth(duration: 0.3), value: form.dueDay)
            .animation(.smooth(duration: 0.2), value: form.reminderDays)
            Text(form.reminderDays.isEmpty
                 ? String(localized: "No reminders: members won't be nudged before the due day.", bundle: .module)
                 : String(localized: "Reminders go at 10:00 AM, Pakistan time. Paid members are never reminded.", bundle: .module))
                .kText(KTextToken.caption, color: KColors.textSecondary)
        }
    }

    private var fixedCard: some View {
        let kameti = data.kameti
        let last = DetailLogic.monthStart(of: kameti, monthIndex: kameti.monthsN)
        let short = Date.FormatStyle(timeZone: TimeZone(identifier: "UTC") ?? .gmt).month(.abbreviated).year()
        return VStack(alignment: .leading, spacing: 0) {
            Label(String(localized: "Fixed once started", bundle: .module), systemImage: "lock.fill")
                .kText(KTextStyle(size: 13, weight: .semibold), color: KColors.textSecondary)
                .padding(.vertical, KSpace.sm)
            fixedRow(String(localized: "Slot amount", bundle: .module), kameti.slotAmountC.format())
            fixedRow(
                String(localized: "Months", bundle: .module),
                "\(kameti.monthsN) · \(kameti.startMonth.formatted(short)) → \(last.formatted(short))"
            )
            fixedRow(String(localized: "Most slots per person", bundle: .module), "\(kameti.maxSlotsPerMember)", last: true)
            Text(SetupLogic.canEditSetup(data)
                 ? String(localized: "Changing these would change every payout. Until the first month, use Edit setup in the ⋯ menu to change them.", bundle: .module)
                 : String(localized: "Changing these would change every payout. To change them, end this kameti and start a new one.", bundle: .module))
                .kText(KTextToken.caption, color: KColors.textSecondary)
                .padding(.top, KSpace.xs)
        }
        .padding(.horizontal, KSpace.lg)
        .padding(.bottom, KSpace.md)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(KColors.border))
    }

    private func fixedRow(_ title: String, _ value: String, last: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).kText(KTextToken.body, color: KColors.textSecondary)
                Spacer()
                Text(value).kText(KTextToken.body).monospacedDigit()
            }
            .padding(.vertical, KSpace.sm + 2)
            if !last { Divider() }
        }
    }

    private func save() {
        submitted = true
        guard form.isValid, let changes else { return }
        kDismissKeyboard()
        isBusy = true
        failure = nil
        Task {
            let result = await model.updateKameti(changes)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }
}
