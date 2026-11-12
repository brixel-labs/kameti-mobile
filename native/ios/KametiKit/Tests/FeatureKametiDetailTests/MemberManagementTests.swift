import Foundation
import KametiCore
import KametiDomain
import KametiTestSupport
import Testing
@testable import FeatureKametiDetail

/// Add, edit and remove against the demo store, which mirrors the backend's
/// `add_member`, `update_member` and `remove_member` rules.
@MainActor
@Suite("Member management")
struct MemberManagementTests {
    private func loaded(_ kametiId: String = "family") async -> (KametiDetailViewModel, () -> KametiDetailData?) {
        let model = KametiDetailViewModel(kametiId: kametiId, userId: SampleData.userId, dependencies: SampleData.dependencies())
        await model.load()
        return (model, {
            if case .loaded(let data) = model.state { return data }
            return nil
        })
    }

    @Test func addingANewPersonSavesThemToMyPeople() async throws {
        let (model, data) = await loaded()
        let before = try #require(data()).members.count
        #expect(await model.addMember(NewMember(name: "  Zara Ahmed ", email: "Zara.Ahmed@gmail.com")) == nil)
        let after = try #require(data())
        #expect(after.members.count == before + 1)
        let zara = try #require(after.members.first { $0.name == "Zara Ahmed" })
        #expect(zara.joinStatus == .notInvited)
        #expect(MemberLogic.contact(of: zara, in: after)?.email == "zara.ahmed@gmail.com")
        // Nothing ties a new member to the ledger yet.
        #expect(MemberLogic.removalBlock(for: zara, in: after) == nil)
    }

    @Test func theSamePersonCantBeAddedTwice() async throws {
        let (model, data) = await loaded()
        let start = try #require(data())
        let contact = try #require(MemberLogic.availableContacts(in: start).first)
        #expect(await model.addMember(NewMember(contactId: contact.id)) == nil)
        let added = try #require(data())
        #expect(!MemberLogic.availableContacts(in: added).contains(contact))
        let again = await model.addMember(NewMember(contactId: contact.id))
        #expect(again == .server(code: "contact_already_member", detail: nil))
    }

    @Test func aBlankNameIsRejected() async {
        let (model, _) = await loaded()
        #expect(await model.addMember(NewMember(name: "   ")) == .server(code: "invalid_name", detail: nil))
    }

    @Test func editingChangesNameAndContact() async throws {
        let (model, data) = await loaded()
        let ali = try #require(data()?.members.first { $0.id == "f1" })
        let changes = try #require(MemberLogic.changes(name: "Ali Raza Khan", email: "ali@x.com", phone: "", from: ali, contact: nil))
        #expect(changes.phone == nil)
        #expect(await model.updateMember(id: ali.id, changes: changes) == nil)
        let after = try #require(data())
        let updated = try #require(after.members.first { $0.id == "f1" })
        #expect(updated.name == "Ali Raza Khan")
        #expect(MemberLogic.contact(of: updated, in: after)?.email == "ali@x.com")
        // Clearing the email with an empty string.
        #expect(await model.updateMember(id: ali.id, changes: MemberChanges(email: "")) == nil)
        let cleared = try #require(data())
        let aliNow = try #require(cleared.members.first { $0.id == "f1" })
        #expect(MemberLogic.contact(of: aliNow, in: cleared)?.email == nil)
    }

    @Test func aMemberWithSharesOrPaymentsCantBeRemoved() async throws {
        let (model, data) = await loaded()
        let current = try #require(data())
        let ali = try #require(current.members.first { $0.id == "f1" })
        let block = try #require(MemberLogic.removalBlock(for: ali, in: current))
        #expect(block.slots == 2) // month 1 and half of month 2
        #expect(await model.removeMember(id: ali.id) == .server(code: "member_has_history", detail: nil))
        #expect(data()?.members.contains { $0.id == "f1" } == true)
    }

    @Test func aMemberWithNothingOnTheLedgerIsRemoved() async throws {
        let (model, data) = await loaded()
        #expect(await model.addMember(NewMember(name: "Temp Person")) == nil)
        let temp = try #require(data()?.members.first { $0.name == "Temp Person" })
        #expect(await model.removeMember(id: temp.id) == nil)
        #expect(data()?.members.contains { $0.id == temp.id } == false)
    }

    @Test func fieldChecks() {
        #expect(MemberLogic.isValidName("A"))
        #expect(!MemberLogic.isValidName("  "))
        #expect(!MemberLogic.isValidName(String(repeating: "a", count: 81)))
        #expect(MemberLogic.isValidEmail(""))
        #expect(MemberLogic.isValidEmail("a@b.co"))
        #expect(!MemberLogic.isValidEmail("a@b"))
        #expect(!MemberLogic.isValidEmail("a b@c.com"))
        #expect(MemberLogic.isValidPhone(""))
        #expect(MemberLogic.isValidPhone("+92 300-1234567"))
        #expect(!MemberLogic.isValidPhone("12"))
        #expect(!MemberLogic.isValidPhone("0300+123456"))
    }
}
