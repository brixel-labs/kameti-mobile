import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

/// Add member (board AM-1a): pick one of my saved people, or type a new
/// person's name, email and phone.
struct AddMemberSheet: View {
    enum Mode { case fromPeople, newPerson }

    let data: KametiDetailData
    let model: KametiDetailViewModel
    let onDone: () -> Void

    @State private var mode = Mode.newPerson
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var submitted = false
    @State private var isBusy = false
    @State private var failure: Failure?

    private var people: [Contact] { MemberLogic.availableContacts(in: data) }
    private var nameError: String? {
        submitted && !MemberLogic.isValidName(name) ? String(localized: "Enter a name.", bundle: .module) : nil
    }
    private var emailError: String? {
        submitted && !MemberLogic.isValidEmail(email) ? String(localized: "Enter a valid email, or leave it empty.", bundle: .module) : nil
    }
    private var phoneError: String? {
        submitted && !MemberLogic.isValidPhone(phone) ? String(localized: "Enter a valid phone number, or leave it empty.", bundle: .module) : nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                HStack(spacing: KSpace.md) {
                    modeButton(.fromPeople, title: String(localized: "From my people", bundle: .module), symbol: "person.2")
                    modeButton(.newPerson, title: String(localized: "New person", bundle: .module), symbol: "person.badge.plus")
                }
                switch mode {
                case .newPerson: newPersonForm
                case .fromPeople: peopleList
                }
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                        .kText(KTextToken.bodySm, color: KColors.negative)
                }
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
            .animation(.smooth(duration: 0.25), value: mode)
        }
        .kDismissesKeyboard()
    }

    private func modeButton(_ target: Mode, title: String, symbol: String) -> some View {
        let isOn = mode == target
        return Button {
            kDismissKeyboard()
            failure = nil
            mode = target
        } label: {
            Label(title, systemImage: symbol)
                .kText(KTextToken.bodyStrong, color: isOn ? KColors.onBrandSubtle : KColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isOn ? KColors.brandSubtle : KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isOn ? KColors.brand : KColors.border, lineWidth: isOn ? 1.5 : 1))
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: New person

    private var newPersonForm: some View {
        VStack(alignment: .leading, spacing: KSpace.lg) {
            MemberField(title: String(localized: "Name", bundle: .module), text: $name, error: nameError, capitalization: .words)
            MemberField(
                title: String(localized: "Email (for the app invite)", bundle: .module), text: $email,
                prompt: "name@example.com", error: emailError, keyboard: .emailAddress, capitalization: .never
            )
            MemberField(
                title: String(localized: "Phone (optional)", bundle: .module), text: $phone,
                prompt: "0300 1234567", error: phoneError, keyboard: .phonePad, capitalization: .never
            )
            infoNote(MemberLogic.isValidName(name)
                ? String(localized: "\(MemberLogic.firstName(name)) owes nothing until you give them a share of a slot.", bundle: .module)
                : String(localized: "A new member owes nothing until you give them a share of a slot.", bundle: .module))
            PrimaryButton(
                title: MemberLogic.isValidName(name)
                    ? String(localized: "Add \(MemberLogic.firstName(name))", bundle: .module)
                    : String(localized: "Add member", bundle: .module),
                isBusy: isBusy, action: addNew
            )
        }
    }

    private func infoNote(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .kText(KTextToken.bodySm, color: KColors.info)
            .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KColors.infoSubtle, in: RoundedRectangle(cornerRadius: 12))
    }

    private func addNew() {
        submitted = true
        guard MemberLogic.isValidName(name), MemberLogic.isValidEmail(email), MemberLogic.isValidPhone(phone) else { return }
        let email = MemberLogic.trimmed(email), phone = MemberLogic.trimmed(phone)
        submit(NewMember(name: MemberLogic.trimmed(name), email: email.isEmpty ? nil : email, phone: phone.isEmpty ? nil : phone))
    }

    private func submit(_ new: NewMember) {
        kDismissKeyboard()
        isBusy = true
        failure = nil
        Task {
            let result = await model.addMember(new)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }

    // MARK: From my people

    @ViewBuilder private var peopleList: some View {
        if people.isEmpty {
            VStack(spacing: KSpace.sm) {
                Text(data.contacts.isEmpty
                     ? String(localized: "No saved people yet", bundle: .module)
                     : String(localized: "Everyone is already in", bundle: .module))
                    .kText(KTextToken.bodyStrong)
                Text(data.contacts.isEmpty
                     ? String(localized: "People you add to a kameti are saved here, so next time you can pick them.", bundle: .module)
                     : String(localized: "All your saved people are in this kameti. Add someone new instead.", bundle: .module))
                    .kText(KTextToken.subtitle, color: KColors.textSubtitle)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, KSpace.lg)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(people.enumerated()), id: \.element.id) { index, contact in
                    Button { submit(NewMember(contactId: contact.id)) } label: {
                        HStack(spacing: KSpace.md) {
                            KAvatar(name: contact.name, colorIndex: contact.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 6, size: .medium)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name).kText(KTextToken.bodyStrong)
                                Text(contact.email ?? contact.phone ?? String(localized: "No email", bundle: .module))
                                    .kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(KColors.brand)
                        }
                        .padding(.vertical, KSpace.sm + 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isBusy)
                    if index < people.count - 1 { Divider() }
                }
            }
        }
    }
}

/// Edit member (board AM-1b): name, email and phone, and removing the member
/// when nothing ties them to the ledger; otherwise the reason is shown.
struct EditMemberSheet: View {
    let data: KametiDetailData
    let model: KametiDetailViewModel
    let member: Member
    let onDone: () -> Void

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var submitted = false
    @State private var isBusy = false
    @State private var confirmingRemove = false
    @State private var isRemoving = false
    @State private var failure: Failure?

    init(data: KametiDetailData, model: KametiDetailViewModel, member: Member, onDone: @escaping () -> Void) {
        self.data = data
        self.model = model
        self.member = member
        self.onDone = onDone
        let contact = MemberLogic.contact(of: member, in: data)
        _name = State(initialValue: member.name)
        _email = State(initialValue: contact?.email ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
    }

    private var contact: Contact? { MemberLogic.contact(of: member, in: data) }
    /// The member as loaded now, so invite changes show while the sheet is open.
    private var currentMember: Member { data.members.first { $0.id == member.id } ?? member }
    private var changes: MemberChanges? {
        MemberLogic.changes(name: name, email: email, phone: phone, from: member, contact: contact)
    }
    private var block: MemberLogic.RemovalBlock? { MemberLogic.removalBlock(for: member, in: data) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KSpace.lg) {
                identity
                AppAccessCard(data: data, model: model, member: currentMember)
                MemberField(
                    title: String(localized: "Name", bundle: .module), text: $name,
                    error: submitted && !MemberLogic.isValidName(name) ? String(localized: "Enter a name.", bundle: .module) : nil,
                    capitalization: .words
                )
                MemberField(
                    title: String(localized: "Email", bundle: .module), text: $email, prompt: "name@example.com",
                    error: submitted && !MemberLogic.isValidEmail(email) ? String(localized: "Enter a valid email, or leave it empty.", bundle: .module) : nil,
                    keyboard: .emailAddress, capitalization: .never
                )
                MemberField(
                    title: String(localized: "Phone", bundle: .module), text: $phone, prompt: "0300 1234567",
                    error: submitted && !MemberLogic.isValidPhone(phone) ? String(localized: "Enter a valid phone number, or leave it empty.", bundle: .module) : nil,
                    keyboard: .phonePad, capitalization: .never
                )
                if let failure {
                    Label(failure.userMessage, systemImage: "exclamationmark.triangle")
                        .kText(KTextToken.bodySm, color: KColors.negative)
                }
                PrimaryButton(title: String(localized: "Save changes", bundle: .module), isBusy: isBusy, action: save)
                    .disabled(changes == nil || isRemoving)
                removeSection
            }
            .padding(.horizontal, KSpace.xl)
            .padding(.top, KSpace.xxs)
            .padding(.bottom, KSpace.xl)
        }
        .kDismissesKeyboard()
        .alert(
            String(localized: "Remove \(member.name)?", bundle: .module), isPresented: $confirmingRemove
        ) {
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Remove", bundle: .module), role: .destructive, action: remove)
        } message: {
            Text("They have no shares or payments, so nothing on the ledger changes. This can't be undone.", bundle: .module)
        }
    }

    private var identity: some View {
        let slots = DetailLogic.slotCount(of: member, shares: data.shares)
        let due = data.balances.first { $0.memberId == member.id }?.monthlyDue
        return HStack(spacing: KSpace.md) {
            KAvatar(name: member.name, colorIndex: DetailRow<KAvatar, EmptyView>.colorIndex(of: member, in: data.members), size: .medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).kText(KTextToken.title)
                Text(summary(slots: slots, due: due)).kText(KTextToken.subtitleSmall, color: KColors.textSubtitle)
            }
            Spacer(minLength: 0)
        }
    }

    private func summary(slots: Int, due: Money?) -> String {
        let slotText = switch slots {
        case 0: String(localized: "No slot yet", bundle: .module)
        case 1: String(localized: "1 slot", bundle: .module)
        default: String(localized: "\(slots) slots", bundle: .module)
        }
        let status = switch member.joinStatus {
        case .joined: String(localized: "Joined", bundle: .module)
        case .invited: String(localized: "Invited", bundle: .module)
        case .pendingApproval: String(localized: "Needs approval", bundle: .module)
        case .notInvited: String(localized: "Not invited", bundle: .module)
        case .declined: String(localized: "Declined", bundle: .module)
        }
        if let due, due.isPositive { return "\(slotText) · \(String(localized: "\(due.format())/mo", bundle: .module)) · \(status)" }
        return "\(slotText) · \(status)"
    }

    private var removeSection: some View {
        VStack(spacing: KSpace.sm) {
            Divider()
            Button { confirmingRemove = true } label: {
                ZStack {
                    Label(String(localized: "Remove from kameti", bundle: .module), systemImage: "trash").opacity(isRemoving ? 0 : 1)
                    if isRemoving { ProgressView().controlSize(.small) }
                }
                .kText(KTextToken.bodyStrong, color: block == nil ? KColors.negative : KColors.textTertiary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(block != nil || isBusy || isRemoving)
            if let block {
                Label(blockMessage(block), systemImage: "exclamationmark.triangle")
                    .kText(KTextToken.bodySm, color: KColors.warning)
                    .padding(.horizontal, KSpace.md).padding(.vertical, KSpace.sm + 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func blockMessage(_ block: MemberLogic.RemovalBlock) -> String {
        let first = MemberLogic.firstName(member.name)
        let slots = block.slots == 1
            ? String(localized: "1 slot share", bundle: .module)
            : String(localized: "\(block.slots) slot shares", bundle: .module)
        let payments = block.payments == 1
            ? String(localized: "1 payment", bundle: .module)
            : String(localized: "\(block.payments) payments", bundle: .module)
        if block.payments == 0 {
            return String(localized: "\(first) can't be removed while holding \(slots). Move the shares to someone else in Schedule first.", bundle: .module)
        }
        if block.slots == 0 {
            return String(localized: "\(first) can't be removed: \(payments) on the ledger stay with them so the record is complete.", bundle: .module)
        }
        return String(localized: "\(first) can't be removed: they hold \(slots) and have \(payments) on the ledger.", bundle: .module)
    }

    private func save() {
        submitted = true
        guard MemberLogic.isValidName(name), MemberLogic.isValidEmail(email), MemberLogic.isValidPhone(phone),
              let changes else { return }
        kDismissKeyboard()
        isBusy = true
        failure = nil
        Task {
            let result = await model.updateMember(id: member.id, changes: changes)
            isBusy = false
            if let result { failure = result } else { onDone() }
        }
    }

    private func remove() {
        isRemoving = true
        failure = nil
        Task {
            let result = await model.removeMember(id: member.id)
            isRemoving = false
            if let result { failure = result } else { onDone() }
        }
    }
}

// MARK: - Pieces

/// A label above a bordered input (boards AM-1a/1b).
private struct MemberField: View {
    let title: String
    @Binding var text: String
    var prompt = ""
    var error: String?
    var keyboard = UIKeyboardType.default
    var capitalization = TextInputAutocapitalization.sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            TextField(prompt, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: 48)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(error == nil ? KColors.border : KColors.negative))
            if let error { Text(error).kText(KTextToken.caption, color: KColors.negative) }
        }
    }
}

private struct PrimaryButton: View {
    let title: String
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isBusy ? 0 : 1)
                if isBusy { ProgressView().controlSize(.small).tint(KColors.textOnBrand) }
            }
            .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(KColors.brand)
        .controlSize(.large)
        .allowsHitTesting(!isBusy)
    }
}
