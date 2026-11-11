import Auth
import Foundation
import KametiCore
import KametiDomain
import PostgREST
import Testing
@testable import KametiData

@Suite("RPC parameters")
struct ParamsTests {
    @Test func createKametiSendsBackendNamesAndWholeRupees() {
        let p = Params.createKameti(NewKameti(
            name: "Office Kameti", startMonth: DateOnly.make(year: 2026, month: 10),
            months: 20, slotAmount: Money(250_000)
        ))
        #expect(p["p_name"] == .string("Office Kameti"))
        #expect(p["p_start_month"] == .string("2026-10-01"))
        #expect(p["p_months_n"] == .int(20))
        #expect(p["p_slot_amount_c"] == .int(250_000))
        #expect(p["p_reminder_days"] == .array([.int(1), .int(5), .int(8), .int(10)]))
        #expect(p["p_description"] == .null)
    }

    @Test func updateLeavesUnchangedFieldsNull() {
        let p = Params.updateKameti(id: "k1", KametiChanges(name: "New name", dueDay: 12))
        #expect(p["p_kameti_id"] == .string("k1"))
        #expect(p["p_name"] == .string("New name"))
        #expect(p["p_due_day"] == .int(12))
        #expect(p["p_months_n"] == .null)
        #expect(p["p_slot_amount_c"] == .null)
        #expect(p["p_start_month"] == .null)
        #expect(p["p_reminder_days"] == .null)
    }

    @Test func noteCalls() {
        let kametiWide = Params.addNote(kametiId: "k1", NewNote(body: "Pay by the 10th", visibility: .shared, targetType: .kameti, targetId: "ignored"))
        #expect(kametiWide["p_kameti_id"] == .string("k1"))
        #expect(kametiWide["p_body"] == .string("Pay by the 10th"))
        #expect(kametiWide["p_visibility"] == .string("shared"))
        #expect(kametiWide["p_target_type"] == .string("kameti"))
        #expect(kametiWide["p_target_id"] == .null) // a kameti note never sends a target id
        let onMember = Params.addNote(kametiId: "k1", NewNote(body: "x", targetType: .member, targetId: "m1"))
        #expect(onMember["p_visibility"] == .string("private"))
        #expect(onMember["p_target_id"] == .string("m1"))
        let update = Params.updateNote(id: "n1", body: nil, visibility: .shared)
        #expect(update["p_note_id"] == .string("n1"))
        #expect(update["p_body"] == .null)
        #expect(update["p_visibility"] == .string("shared"))
    }

    @Test func memberCalls() {
        let add = Params.addMember(kametiId: "k1", NewMember(name: "Ali", email: "a@b.co", isSelf: false))
        #expect(add["p_name"] == .string("Ali"))
        #expect(add["p_email"] == .string("a@b.co"))
        #expect(add["p_contact_id"] == .null)
        #expect(add["p_is_self"] == .bool(false))

        // An empty string clears a field on the backend; nil leaves it.
        let update = Params.updateMember(id: "m1", MemberChanges(nickname: ""))
        #expect(update["p_nickname"] == .string(""))
        #expect(update["p_name"] == .null)
    }

    @Test func sharesAreWholeRupeeObjects() {
        let p = Params.setSlotShares(slotId: "s1", [ShareInput(memberId: "m1", monthlyAmount: Money(125_000))])
        #expect(p["p_shares"] == .array([.object(["member_id": .string("m1"), "monthly_amount": .int(125_000)])]))
    }

    @Test func paymentAndBatch() {
        let day = DateOnly.make(year: 2026, month: 11, day: 9)
        let single = Params.recordPayment(NewPayment(
            memberId: "m1", amount: Money(50_000), receivedOn: day, idempotencyKey: "key-1",
            method: .bankTransfer, paidByName: "Hassan"
        ))
        #expect(single["p_received_on"] == .string("2026-11-09"))
        #expect(single["p_method"] == .string("bank_transfer"))
        #expect(single["p_paid_by_name"] == .string("Hassan"))
        #expect(single["p_reference"] == .null)

        // Batch lines leave optional fields out instead of sending null.
        let item = Params.batchItem(BatchPaymentItem(memberId: "m1", amount: Money(50_000), idempotencyKey: "key-1"))
        #expect(item == .object([
            "member_id": .string("m1"), "amount": .int(50_000), "idempotency_key": .string("key-1"),
        ]))
    }

    @Test func inviteLookupSendsExactlyOneSide() {
        let byToken = Params.inviteLookup(token: "K7Q2MX", inviteId: nil)
        #expect(byToken["p_token"] == .string("K7Q2MX"))
        #expect(byToken["p_invite_id"] == .null)
        let byId = Params.inviteLookup(token: nil, inviteId: "i1")
        #expect(byId["p_invite_id"] == .string("i1"))
    }

    @Test func paramsEncodeToPlainJSON() throws {
        let data = try JSONEncoder().encode(Params.setSlotShares(slotId: "s1", []))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["p_slot_id"] as? String == "s1")
        #expect((object["p_shares"] as? [Any])?.isEmpty == true)
    }
}

@Suite("Failure mapping")
struct FailureMappingTests {
    @Test func rpcErrorKeepsItsStableKey() {
        let error = PostgrestError(
            details: "Shares add up to 200000, not 250000.", code: "22023",
            message: "shares_must_sum_to_slot_amount"
        )
        #expect(Failure(mapping: error) == .server(
            code: "shares_must_sum_to_slot_amount", detail: "Shares add up to 200000, not 250000."
        ))
    }

    @Test func networkErrorsBecomeNetwork() {
        for code in [URLError.Code.notConnectedToInternet, .timedOut, .networkConnectionLost, .cannotFindHost] {
            #expect(Failure(mapping: URLError(code)) == .network)
        }
        guard case .unknown = Failure(mapping: URLError(.badURL)) else {
            Issue.record("a bad URL is not a network outage")
            return
        }
    }

    @Test func failuresPassThroughUntouched() {
        #expect(Failure(mapping: Failure.auth(message: "x")) == .auth(message: "x"))
    }

    @Test func signInErrorsExplainThemselves() {
        // A refused token is a sign-in problem, not "your session ended".
        guard case .signIn(.rejected, _) = SupabaseAuthRepository.signInFailure(AuthError.sessionMissing) else {
            Issue.record("expected a rejected sign-in")
            return
        }
        #expect(SupabaseAuthRepository.signInFailure(URLError(.notConnectedToInternet)) == .network)
    }
}

@Suite("Apple nonce")
struct AppleNonceTests {
    @Test func hashIsTheSHA256OfTheRawValue() {
        // SHA-256("abc"), the standard test vector.
        #expect(AppleNonce(raw: "abc").hashed == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    @Test func eachNonceIsFreshAndUrlSafe() {
        let a = AppleNonce.make(), b = AppleNonce.make()
        #expect(a != b)
        #expect(a.raw.count >= 40)
        #expect(a.raw.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
        #expect(a.hashed == AppleNonce(raw: a.raw).hashed)
    }
}
