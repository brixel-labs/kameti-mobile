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

    public private(set) var isBusy = false
    public private(set) var failure: Failure?

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

    public func addMember(name: String, email: String?) async {
        guard let id = kametiId else { return }
        let cleanEmail = email?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        await write { () async throws(Failure) in
            let member = try await self.dependencies.kametis.addMember(
                kametiId: id, NewMember(name: name.trimmingCharacters(in: .whitespaces), email: cleanEmail)
            )
            if let cleanEmail { self.emails[member.id] = cleanEmail }
            try await self.reload()
        }
    }

    /// Adds a saved person from "My people".
    public func addMember(from contact: Contact) async {
        guard let id = kametiId else { return }
        await write { () async throws(Failure) in
            let member = try await self.dependencies.kametis.addMember(kametiId: id, NewMember(contactId: contact.id))
            if let email = contact.email { self.emails[member.id] = email }
            try await self.reload()
        }
    }

    /// Adds several saved people at once ("Select all").
    public func addMembers(from contacts: [Contact]) async {
        guard let id = kametiId, !contacts.isEmpty else { return }
        await write { () async throws(Failure) in
            for contact in contacts {
                let member = try await self.dependencies.kametis.addMember(kametiId: id, NewMember(contactId: contact.id))
                if let email = contact.email { self.emails[member.id] = email }
            }
            try await self.reload()
        }
    }

    /// "I'm also a member": adds or removes the owner's own member row.
    public func setSelfMember(included: Bool) async {
        guard let id = kametiId else { return }
        if included, selfMember == nil {
            await write { () async throws(Failure) in
                _ = try await self.dependencies.kametis.addMember(kametiId: id, NewMember(isSelf: true))
                try await self.reload()
            }
        } else if !included, let me = selfMember {
            await removeMember(me.id)
        }
    }

    public func removeMember(_ memberId: String) async {
        await write { () async throws(Failure) in
            try await self.dependencies.kametis.removeMember(id: memberId)
            self.emails[memberId] = nil
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
