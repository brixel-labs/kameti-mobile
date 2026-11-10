import KametiCore
import KametiDomain
import KametiUI
import SwiftUI

private func colorIndex(_ member: Member, _ members: [Member]) -> Int {
    Int(member.color ?? "") ?? max(members.firstIndex(of: member) ?? 0, 0)
}

/// Step 3 (AC-3): who is in. Pick from "My people" (the owner's saved
/// contacts) or add someone new; anyone added is saved to My people for next
/// time. Invites go out after the kameti starts.
struct MembersStep: View {
    enum Mode { case fromPeople, newPerson }

    @Bindable var model: CreateWizardModel
    @State private var mode = Mode.newPerson
    @State private var chosenMode = false
    @State private var newName = ""
    @State private var newEmail = ""
    @State private var search = ""
    @State private var submitted = false
    @State private var removing: Member?

    private var emailValid: Bool {
        let trimmed = newEmail.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty || (trimmed.contains("@") && trimmed.contains(".") && !trimmed.contains(" "))
    }
    private var nameValid: Bool { !newName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Who's in?", bundle: .module),
                        subtitle: String(localized: "Add everyone who pays. Invites go out after you start.", bundle: .module)
                    )
                    modeSwitch
                    Group {
                        switch mode {
                        case .newPerson: newPersonCard
                        case .fromPeople: peopleCard
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                    summaryRow
                    memberList
                }
                .padding(KSpace.xl)
                .animation(.smooth(duration: 0.3), value: mode)
                .animation(.smooth(duration: 0.3), value: model.members)
            }
            WizardFooter(
                primaryTitle: String(localized: "Next: slots", bundle: .module), isEnabled: !model.members.isEmpty,
                onBack: { model.back() }
            ) { model.goTo(.slots) }
        }
        .task {
            await model.loadContacts()
            // Start on My people only when there is someone saved to pick.
            if !chosenMode, !model.availableContacts.isEmpty { mode = .fromPeople }
        }
        .alert(
            String(localized: "Remove this person?", bundle: .module), isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
            presenting: removing
        ) { member in
            Button(String(localized: "Cancel", bundle: .module), role: .cancel) {}
            Button(String(localized: "Remove", bundle: .module), role: .destructive) { Task { await model.removeMember(member.id) } }
        } message: { member in
            Text("\(member.name) will be taken out of this kameti. Slots they were in will need filling again.", bundle: .module)
        }
    }

    // MARK: Mode switch

    private var modeSwitch: some View {
        HStack(spacing: KSpace.md) {
            modeButton(.fromPeople, title: String(localized: "From my people", bundle: .module), symbol: "person.2")
            modeButton(.newPerson, title: String(localized: "Add new person", bundle: .module), symbol: "person.badge.plus")
        }
    }

    private func modeButton(_ target: Mode, title: String, symbol: String) -> some View {
        let isOn = mode == target
        return Button {
            chosenMode = true
            mode = target
        } label: {
            Label(title, systemImage: symbol)
                .kText(KTextToken.bodyStrong, color: isOn ? KColors.onBrandSubtle : KColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isOn ? KColors.brandSubtle : KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(isOn ? KColors.brand : KColors.border, lineWidth: isOn ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: Add new person

    private var newPersonCard: some View {
        VStack(alignment: .leading, spacing: KSpace.md) {
            Text("New person", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            PlainField(
                prompt: String(localized: "Name", bundle: .module), text: $newName,
                error: submitted && !nameValid ? String(localized: "Enter a name.", bundle: .module) : nil,
                capitalization: .words
            )
            PlainField(
                prompt: String(localized: "Email for the invite (optional)", bundle: .module), text: $newEmail,
                error: submitted && !emailValid ? String(localized: "Enter a valid email, or leave it empty.", bundle: .module) : nil,
                keyboard: .emailAddress, capitalization: .never
            )
            Button(action: add) {
                Text(nameValid ? String(localized: "Add \(firstName)", bundle: .module) : String(localized: "Add person", bundle: .module))
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
            .disabled(model.isBusy)
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.brand, lineWidth: 1.5))
    }

    private var firstName: String {
        newName.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? ""
    }

    // MARK: From my people

    private var peopleCard: some View {
        let list = model.availableContacts.filter {
            search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
        }
        return VStack(alignment: .leading, spacing: KSpace.md) {
            Text("My people", bundle: .module).kText(KTextToken.bodyStrong, color: KColors.textSecondary)
            if model.contacts.isEmpty {
                emptyPeople(
                    title: String(localized: "No saved people yet", bundle: .module),
                    message: String(localized: "People you add to a kameti are saved here, so next time you can pick them.", bundle: .module)
                )
            } else if model.availableContacts.isEmpty {
                emptyPeople(
                    title: String(localized: "Everyone is already in", bundle: .module),
                    message: String(localized: "All your saved people are in this kameti. Add someone new instead.", bundle: .module)
                )
            } else {
                PlainField(prompt: String(localized: "Search", bundle: .module), text: $search, capitalization: .words)
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { index, contact in
                        Button { Task { await model.addMember(from: contact) } } label: {
                            HStack(spacing: KSpace.md) {
                                KAvatar(name: contact.name, colorIndex: contact.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 6, size: .medium)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.name).kText(KTextToken.bodyStrong)
                                    Text(contact.email ?? String(localized: "No email", bundle: .module))
                                        .kText(KTextToken.caption, color: KColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundStyle(KColors.brand)
                            }
                            .padding(.vertical, KSpace.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isBusy)
                        if index < list.count - 1 { Divider() }
                    }
                }
            }
        }
        .padding(KSpace.lg)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.brand, lineWidth: 1.5))
    }

    private func emptyPeople(title: String, message: String) -> some View {
        VStack(spacing: KSpace.sm) {
            Text(title).kText(KTextToken.bodyStrong)
            Text(message).kText(KTextToken.bodySm, color: KColors.textSecondary).multilineTextAlignment(.center)
            Button { chosenMode = true; mode = .newPerson } label: {
                Label(String(localized: "Add new person", bundle: .module), systemImage: "person.badge.plus")
                    .kText(KTextToken.bodyStrong, color: KColors.textOnBrand)
                    .padding(.horizontal, KSpace.md)
            }
            .buttonStyle(.glassProminent)
            .tint(KColors.brand)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KSpace.md)
    }

    // MARK: Added members

    private var summaryRow: some View {
        HStack {
            Text("\(model.members.count) added", bundle: .module)
                .kText(KTextToken.bodyStrong, color: KColors.textSecondary)
                .contentTransition(.numericText(value: Double(model.members.count)))
            Spacer()
            Toggle(isOn: Binding(
                get: { model.selfMember != nil },
                set: { included in Task { await model.setSelfMember(included: included) } }
            )) {
                Text("I'm also a member", bundle: .module).kText(KTextToken.body)
            }
            .toggleStyle(KCheckboxStyle())
            .fixedSize()
            .disabled(model.isBusy)
        }
    }

    @ViewBuilder private var memberList: some View {
        if model.members.isEmpty {
            Text("Add the people who pay into this kameti.", bundle: .module)
                .kText(KTextToken.bodySm, color: KColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KSpace.lg)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(model.members.enumerated()), id: \.element.id) { index, member in
                    memberRow(member, divider: index < model.members.count - 1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func memberRow(_ member: Member, divider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: KSpace.md) {
                KAvatar(name: member.name, colorIndex: colorIndex(member, model.members), size: .medium)
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.profileId != nil ? String(localized: "You (\(member.name))", bundle: .module) : member.name)
                        .kText(KTextToken.bodyStrong)
                    if member.profileId != nil {
                        Text("Owner", bundle: .module).kText(KTextToken.caption, color: KColors.textSecondary)
                    } else if let email = model.emails[member.id] {
                        Text(email).kText(KTextToken.caption, color: KColors.textSecondary)
                    } else {
                        Text("No email · can't get the app invite", bundle: .module).kText(KTextToken.caption, color: KColors.warning)
                    }
                }
                Spacer()
                if member.profileId == nil {
                    Button { removing = member } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(KColors.textSecondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Remove", bundle: .module))
                }
            }
            .padding(.vertical, KSpace.md)
            if divider { Divider() }
        }
    }

    private func add() {
        submitted = true
        guard nameValid, emailValid else { return }
        let name = newName, email = newEmail
        newName = ""; newEmail = ""; submitted = false
        Task { await model.addMember(name: name, email: email) }
    }
}

/// A bordered input with only a placeholder, for use inside a card.
struct PlainField: View {
    let prompt: String
    @Binding var text: String
    var error: String?
    var keyboard = UIKeyboardType.default
    var capitalization = TextInputAutocapitalization.sentences

    var body: some View {
        VStack(alignment: .leading, spacing: KSpace.xs) {
            TextField(prompt, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled()
                .padding(.horizontal, KSpace.md)
                .frame(minHeight: KSize.fieldHeight)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.input))
                .overlay(RoundedRectangle(cornerRadius: KRadius.input).stroke(error == nil ? KColors.border : KColors.negative))
            if let error { Text(error).kText(KTextToken.caption, color: KColors.negative) }
        }
    }
}

/// Step 4 (AC-4): fill every slot, whole or split between up to four people.
struct SlotsStep: View {
    @Bindable var model: CreateWizardModel

    var body: some View {
        list
            .kBottomSheet(
                isPresented: Binding(get: { model.editingSlotId != nil }, set: { if !$0 { model.editingSlotId = nil } }),
                title: sheetTitle, detents: [.large]
            ) {
                if let slotId = model.editingSlotId, let slot = model.slots.first(where: { $0.id == slotId }) {
                    SlotSplitView(model: model, slot: slot)
                }
            }
    }

    private var sheetTitle: String {
        guard let slotId = model.editingSlotId, let slot = model.slots.first(where: { $0.id == slotId }) else { return "" }
        return String(localized: "Slot \(slot.payoutMonthIndex) · \(monthLabel(addingMonths(slot.payoutMonthIndex - 1, to: model.startMonth)))", bundle: .module)
    }

    private var list: some View {
        let checks = model.checks
        let slots = model.slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }
        let amount = model.slotAmount ?? .zero
        let ready = slots.count - checks.emptySlots.count - checks.badSlots.count
        let byId = Dictionary(model.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Fill the \(slots.count) slots", bundle: .module),
                        subtitle: String(localized: "Each slot is \(amount.format()) a month. Give it to one person or share it between up to 4.", bundle: .module)
                    )
                    VStack(spacing: KSpace.sm) {
                        HStack {
                            Text("Slots ready", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                            Spacer()
                            Text("\(ready) of \(slots.count)", bundle: .module)
                                .kText(KTextToken.bodyStrong)
                                .contentTransition(.numericText(value: Double(ready)))
                        }
                        GeometryReader { proxy in
                            Capsule().fill(KColors.border)
                                .overlay(alignment: .leading) {
                                    Capsule().fill(KColors.brand)
                                        .frame(width: slots.isEmpty ? 0 : proxy.size.width * CGFloat(ready) / CGFloat(slots.count))
                                }
                        }
                        .frame(height: 6)
                    }
                    .animation(.smooth, value: ready)
                    if !checks.unassigned.isEmpty {
                        let names = checks.unassigned.map(\.name).formatted(.list(type: .and))
                        Label {
                            Text(checks.unassigned.count == 1
                                 ? String(localized: "\(names) isn't in any slot yet.", bundle: .module)
                                 : String(localized: "\(names) aren't in any slot yet.", bundle: .module))
                        } icon: { Image(systemName: "exclamationmark.circle") }
                        .kText(KTextToken.bodySm, color: KColors.warning)
                        .padding(KSpace.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(KColors.warningSubtle, in: RoundedRectangle(cornerRadius: KRadius.input))
                    }
                    VStack(spacing: KSpace.sm) {
                        ForEach(slots) { slot in
                            Button { model.editingSlotId = slot.id } label: { slotRow(slot, amount: amount, byId: byId) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(KSpace.xl)
            }
            WizardFooter(primaryTitle: String(localized: "Next: payout order", bundle: .module), isEnabled: checks.slotsFilled && checks.slotsAddUp, onBack: { model.back() }) {
                model.goTo(.order)
            }
        }
    }

    /// One slot: its number, who is in it and a status mark (design AC-4).
    private func slotRow(_ slot: Slot, amount: Money, byId: [String: Member]) -> some View {
        let active = PlanChecks.activeShares(of: slot.id, in: model.shares)
        let amounts = active.map(\.monthlyAmount)
        let valid = PlanChecks.isValidSplit(amounts, slotAmount: amount)
        let partial = !active.isEmpty && !valid
        let title = active.isEmpty ? String(localized: "Empty", bundle: .module)
            : active.map { byId[$0.memberId]?.name ?? "" }.joined(separator: " + ")
        return HStack(spacing: KSpace.md) {
            Text("\(slot.payoutMonthIndex)")
                .kText(KTextToken.bodyStrong, color: partial ? KColors.warning : KColors.textPrimary)
                .monospacedDigit()
                .frame(width: 36, height: 36)
                .background(partial ? KColors.warningSubtle : KColors.surfaceSunken, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).kText(KTextToken.bodyStrong).lineLimit(1)
                if active.isEmpty {
                    Text("Tap to add people", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                } else if partial {
                    Text("\(PlanChecks.remaining(amounts, slotAmount: amount).format()) still to assign", bundle: .module)
                        .kText(KTextToken.bodySm, color: KColors.warning)
                } else if active.count == 1 {
                    Text("Whole slot · \(amount.format())", bundle: .module).kText(KTextToken.bodySm, color: KColors.textSecondary)
                } else {
                    Text(amounts.map { $0.format(symbol: false) }.joined(separator: " + "))
                        .kText(KTextToken.bodySm, color: KColors.textSecondary)
                }
            }
            Spacer(minLength: KSpace.sm)
            if valid {
                Image(systemName: "checkmark").font(.system(size: 16, weight: .semibold)).foregroundStyle(KColors.positive)
            } else if active.isEmpty {
                Image(systemName: "plus").font(.system(size: 16, weight: .semibold)).foregroundStyle(KColors.brand)
            } else {
                Image(systemName: "chevron.right").foregroundStyle(partial ? KColors.warning : KColors.textTertiary)
            }
        }
        .padding(KSpace.md)
        .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
        .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(partial ? KColors.warning : KColors.border, lineWidth: partial ? 2 : 1))
        .contentShape(Rectangle())
    }
}

/// The split editor for one slot (design AC-4 final): a progress card, the
/// chosen people with amount controls, and everyone else to add. Splitting is
/// optional: one person gets the whole slot.
struct SlotSplitView: View {
    @Bindable var model: CreateWizardModel
    let slot: Slot

    @State private var split: SlotSplit
    @State private var activeId: String?

    init(model: CreateWizardModel, slot: Slot) {
        self.model = model
        self.slot = slot
        let existing = PlanChecks.activeShares(of: slot.id, in: model.shares)
            .map { SlotSplit.Line(id: $0.memberId, amount: $0.monthlyAmount) }
        _split = State(initialValue: SlotSplit(total: model.slotAmount ?? .zero, lines: existing))
        _activeId = State(initialValue: existing.first?.id)
    }

    private static let segmentColors = [KColors.warning, KColors.brand, KColors.info, KColors.onBrandSubtle]
    private var byId: [String: Member] { Dictionary(model.members.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }) }
    private var month: Date { addingMonths(slot.payoutMonthIndex - 1, to: model.startMonth) }

    private func otherSlotCount(of member: Member) -> Int {
        Set(model.shares.filter { $0.memberId == member.id && $0.slotId != slot.id && $0.effectiveToMonth == nil }.map(\.slotId)).count
    }

    var body: some View {
        let remaining = split.remaining
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: KSpace.lg) {
                    WizardHeading(
                        title: String(localized: "Who pays what each month?", bundle: .module),
                        subtitle: String(localized: "This slot needs \(split.total.format()) a month. Up to 4 people.", bundle: .module)
                    )
                    progressCard(remaining: remaining)
                    ForEach(Array(split.lines.enumerated()), id: \.element.id) { index, line in
                        if let member = byId[line.id] {
                            personCard(member: member, line: line, color: Self.segmentColors[index % Self.segmentColors.count])
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    if !split.isFull { addSection }
                }
                .padding(KSpace.xl)
                .animation(.smooth(duration: 0.3), value: split)
                .animation(.smooth(duration: 0.3), value: activeId)
            }
            WizardFooter(
                primaryTitle: footerTitle(remaining), isEnabled: split.isValid, isLoading: model.isBusy,
                onBack: hasSavedPeople ? { Task { await model.saveSlotShares(slotId: slot.id, shares: []) } } : nil,
                backTitle: String(localized: "Empty slot", bundle: .module), backIsDestructive: true
            ) {
                let inputs = split.lines.map { ShareInput(memberId: $0.id, monthlyAmount: $0.amount) }
                Task { await model.saveSlotShares(slotId: slot.id, shares: inputs) }
            }
        }
    }

    private var hasSavedPeople: Bool { !PlanChecks.activeShares(of: slot.id, in: model.shares).isEmpty }

    private func footerTitle(_ remaining: Money) -> String {
        if split.lines.isEmpty { return String(localized: "Add someone", bundle: .module) }
        if split.isValid { return String(localized: "Save slot", bundle: .module) }
        return remaining.isNegative
            ? String(localized: "Over by \(Money(-remaining.rupees).format())", bundle: .module)
            : String(localized: "\(remaining.format()) left", bundle: .module)
    }

    // MARK: Progress

    private func progressCard(remaining: Money) -> some View {
        KCard {
            VStack(alignment: .leading, spacing: KSpace.sm) {
                HStack {
                    Text("Assigned", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                    Spacer()
                    Text("\(split.assigned.format()) of \(split.total.format())", bundle: .module).kText(KTextToken.bodyStrong)
                }
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(Array(split.lines.enumerated()), id: \.element.id) { index, line in
                            let fraction = split.total.rupees > 0 ? CGFloat(line.amount.rupees) / CGFloat(split.total.rupees) : 0
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Self.segmentColors[index % Self.segmentColors.count])
                                .frame(width: max(proxy.size.width * fraction - 2, 0))
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KColors.border, in: Capsule())
                    .clipShape(Capsule())
                }
                .frame(height: 10)
                HStack {
                    Group {
                        if split.lines.isEmpty {
                            Text("Add someone below.", bundle: .module).foregroundStyle(KColors.textSecondary)
                        } else if remaining.isZero {
                            Label(String(localized: "Adds up", bundle: .module), systemImage: "checkmark.circle").foregroundStyle(KColors.positive)
                        } else if remaining.isNegative {
                            Text("Over by \(Money(-remaining.rupees).format())", bundle: .module).foregroundStyle(KColors.negative)
                        } else {
                            Text("\(remaining.format()) left to assign", bundle: .module).foregroundStyle(KColors.warning)
                        }
                    }
                    .kText(KTextToken.bodyStrong)
                    Spacer()
                    if split.lines.count > 1 {
                        Button(String(localized: "Split evenly", bundle: .module)) { split.splitEvenly() }
                            .buttonStyle(.glass)
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: People

    @ViewBuilder
    private func personCard(member: Member, line: SlotSplit.Line, color: Color) -> some View {
        let payout = line.amount * model.months
        let isOpen = split.lines.count > 1 && activeId == line.id
        let single = split.lines.count == 1
        if isOpen || single {
            VStack(alignment: .leading, spacing: KSpace.md) {
                HStack(spacing: KSpace.md) {
                    identity(member: member, payout: payout, size: .large)
                    trashButton(member)
                }
                if single {
                    HStack {
                        Text("Whole slot", bundle: .module).kText(KTextToken.body, color: KColors.textSecondary)
                        Spacer()
                        KMoneyText(line.amount, style: .title)
                    }
                } else {
                    amountControls(line: line)
                }
            }
            .padding(KSpace.lg)
            .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
            .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.textPrimary, lineWidth: 2))
        } else {
            Button { activeId = line.id } label: {
                HStack(spacing: KSpace.md) {
                    identity(member: member, payout: payout, size: .medium)
                    KMoneyText(line.amount, style: .title)
                    trashButton(member)
                }
                .padding(.horizontal, KSpace.md)
                .padding(.vertical, KSpace.sm + 2)
                .background(KColors.surface, in: RoundedRectangle(cornerRadius: KRadius.card))
                .overlay(RoundedRectangle(cornerRadius: KRadius.card).stroke(KColors.border))
            }
            .buttonStyle(.plain)
        }
    }

    private func identity(member: Member, payout: Money, size: KAvatar.Size) -> some View {
        HStack(spacing: KSpace.md) {
            KAvatar(name: member.name, colorIndex: Int(member.color ?? "") ?? max(model.members.firstIndex(of: member) ?? 0, 0), size: size)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.profileId != nil ? String(localized: "You (\(member.name))", bundle: .module) : member.name).kText(KTextToken.bodyStrong)
                Text("Gets \(payout.format()) in \(monthLabel(month).split(separator: " ").first.map(String.init) ?? "")", bundle: .module)
                    .kText(KTextToken.caption, color: KColors.textSecondary)
            }
            Spacer(minLength: KSpace.sm)
        }
    }

    private func trashButton(_ member: Member) -> some View {
        Group {
            Button {
                withAnimation(.smooth(duration: 0.3)) {
                    split.remove(member.id)
                    if activeId == member.id { activeId = split.lines.first?.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KColors.negative)
                    .frame(width: 36, height: 36)
                    .background(KColors.negativeSubtle, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Remove \(member.name) from this slot", bundle: .module))
        }
    }

    private func amountControls(line: SlotSplit.Line) -> some View {
        VStack(spacing: KSpace.md) {
            HStack {
                roundButton("minus", label: String(localized: "Less", bundle: .module)) { split.nudge(line.id, by: -1) }
                Spacer()
                VStack(spacing: 2) {
                    KMoneyText(line.amount, style: .display)
                    Text("a month · steps of \(Money(SlotSplit.step(for: split.total)).formatCompact())", bundle: .module)
                        .kText(KTextToken.caption, color: KColors.textSecondary)
                }
                Spacer()
                roundButton("plus", label: String(localized: "More", bundle: .module)) { split.nudge(line.id, by: 1) }
            }
            KFlowLayout {
                ForEach(SlotSplit.presets(for: split.total), id: \.self) { preset in
                    KChip(preset.formatCompact(), isOn: line.amount == preset) { split.set(line.id, to: preset) }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func roundButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(KColors.onBrandSubtle)
                .frame(width: 48, height: 48)
                .background(KColors.brandSubtle, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: Add

    private var addSection: some View {
        let candidates = model.members.filter { member in !split.lines.contains { $0.id == member.id } }
        return VStack(alignment: .leading, spacing: KSpace.sm) {
            HStack {
                Text("Add someone".uppercased()).kText(KTextToken.label, color: KColors.textSecondary)
                Spacer()
                Text("\(split.lines.count) of \(SlotSplit.maxPeople) spots used", bundle: .module)
                    .kText(KTextToken.caption, color: KColors.textSecondary)
            }
            if candidates.isEmpty {
                Text("Everyone is already in this slot. Add more people in step 3.", bundle: .module)
                    .kText(KTextToken.bodySm, color: KColors.textSecondary)
            } else {
                KFlowLayout {
                    ForEach(candidates) { member in
                        let count = otherSlotCount(of: member)
                        let atLimit = count >= model.maxSlotsPerMember
                        Button {
                            withAnimation(.smooth(duration: 0.3)) {
                                split.add(member.id)
                                if split.lines.count > 1 { activeId = member.id }
                            }
                        } label: {
                            HStack(spacing: KSpace.sm) {
                                KAvatar(name: member.name, colorIndex: Int(member.color ?? "") ?? max(model.members.firstIndex(of: member) ?? 0, 0), size: .small)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(member.profileId != nil ? String(localized: "You", bundle: .module) : member.name).kText(KTextToken.bodyStrong)
                                    if atLimit {
                                        Text("In \(count) slots · limit", bundle: .module).kText(KTextToken.caption, color: KColors.warning)
                                    }
                                }
                                if !atLimit { Image(systemName: "plus").foregroundStyle(KColors.brand) }
                            }
                            .padding(.leading, KSpace.xs)
                            .padding(.trailing, KSpace.md)
                            .padding(.vertical, KSpace.xs)
                            .background(KColors.surface, in: Capsule())
                            .overlay(Capsule().stroke(KColors.border))
                            .opacity(atLimit ? 0.5 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(atLimit)
                    }
                }
            }
        }
    }
}
