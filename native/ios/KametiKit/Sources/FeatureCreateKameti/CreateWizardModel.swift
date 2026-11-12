import Foundation
import KametiCore
import KametiDomain
import Observation

/// The six steps of the create wizard (FR-10).
public enum WizardStep: Int, CaseIterable, Sendable {
    case basics, dates, members, slots, order, review
}

/// Shortest and longest kameti in months, and the slots-per-person ceiling (REQUIREMENTS §3.2).
public enum WizardLimits {
    public static let minMonths = 2
    public static let maxMonths = 60
    public static let maxSlotsPerMember = 6
    public static let nameLength = 3...40
    public static let dueDays = 1...28
}

/// Drives the create wizard (boards AC-1 to AC-6, FR-10 to FR-12).
///
/// Step 1 creates the draft on the server; later saves update it. Members,
/// slots and shares live on the server once the draft exists, and are
/// re-read after each write. Every write sets `failure` on error.
@MainActor
@Observable
public final class CreateWizardModel {
    public private(set) var step = WizardStep.basics
    public var editingSlotId: String?

    // Step 1 and 2 fields, kept so Back and Next keep what was typed.
    public var name = ""
    public var amountText = ""
    public var months = 12
    public var startMonth: Date
    public var dueDay = 10
    public var reminderDays: [Int] = [1, 5, 8, 10]
    public var maxSlotsPerMember = 4

    public private(set) var kametiId: String?
    public private(set) var members: [Member] = []
    public private(set) var slots: [Slot] = []
    public private(set) var shares: [Share] = []
    /// Emails typed for members added here (display only).
    public private(set) var emails: [String: String] = [:]

    /// The owner's saved people ("My people"), for picking into the kameti.
    public private(set) var contacts: [Contact] = []
    public private(set) var contactsLoaded = false
    /// The owner's first name, for the reminder preview.
    public private(set) var ownerName: String?
    /// The owner's full name, for their own row before the server confirms it.
    private var ownerFullName: String?

    public private(set) var isBusy = false
    public private(set) var failure: Failure?
    /// True while a saved draft is being read back in.
    public private(set) var isLoadingDraft = false
    /// Set when the wizard reopened a saved draft (not a new kameti).
    public private(set) var isResumed = false

    private let userId: String
    private let dependencies: KametiDependencies

    public init(userId: String, dependencies: KametiDependencies) {
        self.userId = userId
        self.dependencies = dependencies
        startMonth = dependencies.clock.currentMonth()
    }

    // MARK: Derived

    public var slotAmount: Money? { Money(parsing: amountText) }
    public var nameValid: Bool { WizardLimits.nameLength.contains(name.trimmingCharacters(in: .whitespaces).count) }
    public var slotAmountValid: Bool {
        slotAmount.map { $0.rupees >= 1_000 && $0.rupees % 1_000 == 0 } ?? false
    }
    public var pot: Money { (slotAmount ?? .zero) * months }
    public var selfMember: Member? { members.first { $0.profileId == userId } }
    public var checks: PlanChecks {
        PlanChecks.evaluate(
            slotAmount: slotAmount ?? .zero, maxSlotsPerMember: maxSlotsPerMember,
            members: members, slots: slots, shares: shares
        )
    }

    public func loadOwner() async {
        guard ownerName == nil else { return }
        if let profile = try? await dependencies.profiles.myProfile(userId: userId) {
            ownerName = profile.displayName.split(separator: " ").first.map(String.init)
            ownerFullName = profile.displayName
        }
    }

    public func loadContacts() async {
        guard !contactsLoaded else { return }
        if let list = try? await dependencies.contacts.contacts() { contacts = list }
        contactsLoaded = true
    }

    /// Saved people not yet in this kameti.
    public var availableContacts: [Contact] {
        let used = Set(members.compactMap(\.contactId))
        return contacts.filter { !used.contains($0.id) }
    }

    // MARK: Local edits

    public func setMonths(_ value: Int) {
        months = min(max(value, WizardLimits.minMonths), WizardLimits.maxMonths)
    }

    /// Also drops reminder days after the new due day.
    public func setDueDay(_ day: Int) {
        dueDay = day
        reminderDays = reminderDays.filter { $0 <= day }
    }

    public func toggleReminder(_ day: Int) {
        if reminderDays.contains(day) {
            reminderDays.removeAll { $0 == day }
        } else {
            reminderDays = (reminderDays + [day]).sorted()
        }
    }

    public func setMaxSlots(_ value: Int) {
        maxSlotsPerMember = min(max(value, 1), WizardLimits.maxSlotsPerMember)
    }

    public func clearFailure() { failure = nil }

    public func goTo(_ target: WizardStep) {
        step = target
        editingSlotId = nil
    }

    /// Closes the split editor first, then steps back.
    public func back() {
        if editingSlotId != nil {
            editingSlotId = nil
        } else if let previous = WizardStep(rawValue: step.rawValue - 1) {
            goTo(previous)
        }
    }

    public var isAtStart: Bool { step == .basics && editingSlotId == nil }

    /// Where a reopened draft continues: members first, then filling every
    /// slot, then the review (order is optional, so it isn't forced).
    public nonisolated static func resumeStep(members: [Member], slots: [Slot], shares: [Share]) -> WizardStep {
        if members.isEmpty { return .members }
        let filled = Set(shares.map(\.slotId))
        if slots.isEmpty || slots.contains(where: { !filled.contains($0.id) }) { return .slots }
        return .review
    }

    /// Reopens a saved draft: fills every step from the server and continues
    /// at the first unfinished one (FR-10, drafts are kept on the server).
    public func resume(draftId: String) async {
        isLoadingDraft = true
        defer { isLoadingDraft = false }
        do throws(Failure) {
            let kameti = try await dependencies.kametis.kameti(id: draftId)
            kametiId = kameti.id
            name = kameti.name
            amountText = String(kameti.slotAmountC.rupees)
            months = kameti.monthsN
            startMonth = kameti.startMonth
            dueDay = kameti.dueDay
            reminderDays = kameti.reminderDays
            maxSlotsPerMember = kameti.maxSlotsPerMember
            try await reload()
            await loadContacts()
            for member in members {
                if let email = member.contactId.flatMap({ id in contacts.first { $0.id == id }?.email }) { emails[member.id] = email }
            }
            isResumed = true
            step = Self.resumeStep(members: members, slots: slots, shares: shares)
        } catch {
            failure = error
        }
    }

    // MARK: Server writes

    /// Step 1: creates the draft, or updates it when it already exists.
    public func saveBasics() async {
        guard nameValid, slotAmountValid, let amount = slotAmount else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        await write { () async throws(Failure) in
            if let id = self.kametiId {
                _ = try await self.dependencies.kametis.updateKameti(
                    id: id, changes: KametiChanges(name: trimmed, startMonth: self.startMonth, months: self.months, slotAmount: amount)
                )
            } else {
                let created = try await self.dependencies.kametis.createKameti(NewKameti(
                    name: trimmed, startMonth: self.startMonth, months: self.months, slotAmount: amount,
                    dueDay: self.dueDay, reminderDays: self.reminderDays, maxSlotsPerMember: self.maxSlotsPerMember
                ))
                self.kametiId = created.id
            }
            try await self.reload()
            self.step = .dates
        }
    }

    /// Step 2: due day, reminder days and the slot limit.
    public func saveDates() async {
        guard let id = kametiId else { return }
        await write { () async throws(Failure) in
            _ = try await self.dependencies.kametis.updateKameti(
                id: id, changes: KametiChanges(dueDay: self.dueDay, reminderDays: self.reminderDays, maxSlotsPerMember: self.maxSlotsPerMember)
            )
            self.step = .members
        }
    }

    // Member changes are optimistic: the row appears or disappears at once and
    // the server call runs behind it, so the step never freezes. A row the
    // server hasn't confirmed yet has a temporary id; a failure undoes the
    // change and shows the error.

    /// Rows added here that the server hasn't confirmed yet.
    public private(set) var pendingMemberIds: Set<String> = []
    /// Member saves still running; "Next" waits for them.
    public private(set) var memberSavesInFlight = 0
    public var isSavingMembers: Bool { memberSavesInFlight > 0 }
    public func isPending(_ member: Member) -> Bool { pendingMemberIds.contains(member.id) }
    /// Saved id → the temporary id its row was first shown with, so the row
    /// keeps one identity and doesn't animate out and back in when it saves.
    private var rowKeys: [String: String] = [:]
    public func rowKey(_ member: Member) -> String { rowKeys[member.id] ?? member.id }

    public func addMember(name: String, email: String?, phone: String? = nil) async {
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        let cleanEmail = email?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        let cleanPhone = phone?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        await addOptimistic(name: cleanName, email: cleanEmail, new: NewMember(name: cleanName, email: cleanEmail, phone: cleanPhone))
    }

    /// Adds a saved person from "My people".
    public func addMember(from contact: Contact) async {
        await addOptimistic(name: contact.name, email: contact.email, contactId: contact.id, new: NewMember(contactId: contact.id))
    }

    /// Adds several saved people at once ("Select all").
    public func addMembers(from contacts: [Contact]) async {
        // Show every row at once, in order, then save them together.
        let staged = contacts.compactMap { contact in
            stageAdd(name: contact.name, email: contact.email, contactId: contact.id).map { ($0, NewMember(contactId: contact.id)) }
        }
        await withTaskGroup(of: Void.self) { group in
            for (tempId, new) in staged { group.addTask { await self.commitAdd(tempId: tempId, new: new) } }
        }
    }

    /// "I'm also a member": adds or removes the owner's own member row.
    public func setSelfMember(included: Bool) async {
        if included, selfMember == nil {
            await addOptimistic(name: ownerFullName ?? ownerName ?? "", email: nil, profileId: userId, new: NewMember(isSelf: true))
        } else if !included, let me = selfMember, !isPending(me) {
            await removeMember(me.id)
        }
    }

    public func removeMember(_ memberId: String) async {
        guard !pendingMemberIds.contains(memberId), let index = members.firstIndex(where: { $0.id == memberId }) else { return }
        let removed = members[index]
        let removedShares = shares.filter { $0.memberId == memberId }
        let email = emails[memberId]
        members.remove(at: index)
        shares.removeAll { $0.memberId == memberId }
        emails[memberId] = nil
        await saveMembers { () async throws(Failure) in
            try await self.dependencies.kametis.removeMember(id: memberId)
        } undo: {
            self.members.insert(removed, at: min(index, self.members.count))
            self.shares.append(contentsOf: removedShares)
            self.emails[memberId] = email
        }
    }

    private func addOptimistic(name: String, email: String?, contactId: String? = nil, profileId: String? = nil, new: NewMember) async {
        guard let tempId = stageAdd(name: name, email: email, contactId: contactId, profileId: profileId) else { return }
        await commitAdd(tempId: tempId, new: new)
    }

    /// Shows a not-yet-saved row at once; returns its temporary id.
    private func stageAdd(name: String, email: String?, contactId: String? = nil, profileId: String? = nil) -> String? {
        guard let id = kametiId else { return nil }
        let tempId = "pending-\(UUID().uuidString)"
        members.append(Member(id: tempId, kametiId: id, name: name, joinStatus: .notInvited, contactId: contactId, profileId: profileId))
        pendingMemberIds.insert(tempId)
        if let email { emails[tempId] = email }
        return tempId
    }

    /// Saves a staged row and swaps in the server's member, or undoes it.
    private func commitAdd(tempId: String, new: NewMember) async {
        guard let id = kametiId else { return }
        let email = emails[tempId]
        await saveMembers { () async throws(Failure) in
            let saved = try await self.dependencies.kametis.addMember(kametiId: id, new)
            self.rowKeys[saved.id] = tempId
            if let i = self.members.firstIndex(where: { $0.id == tempId }) { self.members[i] = saved }
            self.pendingMemberIds.remove(tempId)
            self.emails[tempId] = nil
            if let email { self.emails[saved.id] = email }
        } undo: {
            self.members.removeAll { $0.id == tempId }
            self.pendingMemberIds.remove(tempId)
            self.emails[tempId] = nil
        }
    }

    private func saveMembers(_ body: () async throws(Failure) -> Void, undo: () -> Void) async {
        memberSavesInFlight += 1
        failure = nil
        defer { memberSavesInFlight -= 1 }
        do throws(Failure) { try await body() } catch {
            undo()
            failure = error
        }
    }

    /// Adds one month (one slot) to a draft, for a person who isn't in any
    /// slot yet. The slot amount stays the same; the pot grows by one slot.
    public var canAddSlot: Bool { months < WizardLimits.maxMonths }

    public func addSlot() async {
        guard let id = kametiId, canAddSlot else { return }
        let next = months + 1
        await write { () async throws(Failure) in
            _ = try await self.dependencies.kametis.updateKameti(id: id, changes: KametiChanges(months: next))
            self.months = next
            try await self.reload()
        }
    }

    /// Saves one slot's split and closes the split editor.
    public func saveSlotShares(slotId: String, shares inputs: [ShareInput]) async {
        await write { () async throws(Failure) in
            _ = try await self.dependencies.kametis.setSlotShares(slotId: slotId, shares: inputs)
            self.editingSlotId = nil
            try await self.reload()
        }
    }

    /// Step 5: saves the payout order (only when it changed) and moves on.
    public func saveOrder(_ orderedSlotIds: [String]) async {
        guard let id = kametiId else { return }
        let original = slots.sorted { $0.payoutMonthIndex < $1.payoutMonthIndex }.map(\.id)
        if original == orderedSlotIds { goTo(.review); return }
        await write { () async throws(Failure) in
            _ = try await self.dependencies.kametis.reorderSlots(kametiId: id, slotIdsInOrder: orderedSlotIds)
            try await self.reload()
            self.step = .review
        }
    }

    /// Step 6: asks the server to start (it re-checks FR-12). Returns the id on success.
    public func start() async -> String? {
        guard let id = kametiId else { return nil }
        var started: String?
        await write { () async throws(Failure) in
            started = try await self.dependencies.kametis.startKameti(id: id).id
        }
        return started
    }

    // MARK: Private

    private func reload() async throws(Failure) {
        guard let id = kametiId else { return }
        members = try await dependencies.kametis.members(kametiId: id)
        slots = try await dependencies.kametis.slots(kametiId: id)
        shares = try await dependencies.kametis.shares(kametiId: id)
    }

    private func write(_ body: () async throws(Failure) -> Void) async {
        guard !isBusy else { return }
        isBusy = true
        failure = nil
        defer { isBusy = false }
        do throws(Failure) { try await body() } catch { failure = error }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
