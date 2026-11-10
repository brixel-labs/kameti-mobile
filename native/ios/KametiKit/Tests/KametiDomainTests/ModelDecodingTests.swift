import Foundation
import Testing
import KametiCore
@testable import KametiDomain

/// Rows shaped exactly as PostgREST returns them (snake_case, bigint as int,
/// dates as YYYY-MM-DD, timestamps as ISO-8601).
@Suite("Backend rows decode into models")
struct ModelDecodingTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try KametiJSON.makeDecoder().decode(T.self, from: Data(json.utf8))
    }

    @Test func kameti() throws {
        let k = try decode(Kameti.self, """
        {"id":"k1","owner_id":"u1","name":"Office Kameti 2026","description":null,
         "start_month":"2026-10-01","months_n":20,"slot_amount_c":250000,"due_day":10,
         "reminder_days":[1,5,8,10],"max_slots_per_member":6,"status":"active",
         "privacy_settings":{"show_amounts":true},
         "created_at":"2026-11-09T19:59:09.123+00:00","started_at":"2026-11-09T20:00:00+00:00"}
        """)
        #expect(k.slotAmountC == Money(250_000))
        #expect(k.pot == Money(5_000_000))
        #expect(k.startMonth == DateOnly.make(year: 2026, month: 10))
        #expect(k.status == .active)
        #expect(k.startedAt != nil)
        #expect(k.isOwned(by: "u1"))
        #expect(!k.isOwned(by: "u2"))
        #expect(!k.isOwned(by: nil))
    }

    @Test func memberAndShare() throws {
        let m = try decode(Member.self, """
        {"id":"m1","kameti_id":"k1","name":"Ali Raza","join_status":"pending_approval",
         "contact_id":null,"profile_id":null}
        """)
        #expect(m.joinStatus == .pendingApproval)

        let s = try decode(Share.self, """
        {"id":"s1","kameti_id":"k1","slot_id":"sl1","member_id":"m1",
         "monthly_amount":125000,"effective_from_month":1,"effective_to_month":null}
        """)
        #expect(s.monthlyAmount == Money(125_000))
        #expect(s.effectiveToMonth == nil)
    }

    @Test func paymentWithBankTransferAndVoid() throws {
        let p = try decode(Payment.self, """
        {"id":"p1","kameti_id":"k1","member_id":"m1","amount":450000,
         "received_on":"2026-11-09","method":"bank_transfer",
         "created_at":"2026-11-09T10:00:00+00:00",
         "voided_at":"2026-11-09T11:00:00+00:00","void_reason":"wrong member"}
        """)
        #expect(p.method == .bankTransfer)
        #expect(p.receivedOn == DateOnly.make(year: 2026, month: 11, day: 9))
        #expect(p.isVoided)
    }

    @Test func ledgerViewRows() throws {
        let c = try decode(MonthCollectionRow.self, """
        {"kameti_id":"k1","month_index":1,"month_start":"2026-10-01","is_current":false,
         "target":5000000,"received":4970000,"covered":4845000,"paid_count":11,
         "member_count":15,"payout_shortfall":30000,"paid_out":4970000,"recipients":1,
         "recipients_paid":1,"paid_out_short_by":30000,"state":"paid_out_short"}
        """)
        #expect(c.state == .paidOutShort)
        #expect(c.payoutShortfall == Money(30_000))
        // Received is the cash; covered is what the oldest-due-first allocation
        // covers (money-and-ledger rule 4).
        #expect(c.received != c.covered)

        let m = try decode(MemberMonthRow.self, """
        {"kameti_id":"k1","member_id":"m1","month_index":3,"month_start":"2026-12-01",
         "is_current":false,"due":375000,"allocated":180000,"remaining":195000,"status":"advance"}
        """)
        #expect(m.status == .advance)

        let b = try decode(MemberBalanceRow.self, """
        {"kameti_id":"k1","member_id":"m1","current_month_index":2,"monthly_due":125000,
         "due_to_date":250000,"total_paid":300000,"balance":-50000,"owes":0,"credit":50000}
        """)
        #expect(b.credit == Money(50_000))
        #expect(b.balance.isNegative)
    }

    @Test func timestampsWithAndWithoutFractionalSeconds() throws {
        let a = try decode(Payment.self, """
        {"id":"p","kameti_id":"k","member_id":"m","amount":1,"received_on":"2026-11-09",
         "method":"cash","created_at":"2026-11-09T19:59:09.123+00:00"}
        """)
        let b = try decode(Payment.self, """
        {"id":"p","kameti_id":"k","member_id":"m","amount":1,"received_on":"2026-11-09",
         "method":"cash","created_at":"2026-11-09T19:59:09+00:00"}
        """)
        #expect(abs(a.createdAt.timeIntervalSince(b.createdAt)) < 1)
    }

    @Test func inviteRows() throws {
        let preview = try decode(InvitePreview.self, """
        {"invite_id":"i1","status":"pending","expired":false,"expires_at":"2026-11-24T10:00:00+00:00",
         "email_matches":false,"kameti_name":"Office Kameti","owner_name":"Hassan",
         "member_name":"Ali Raza","shares":[{"payout_month_index":3,"monthly_amount":50000}]}
        """)
        #expect(preview.isOpen)
        #expect(preview.shares.first?.monthlyAmount == Money(50_000))

        let link = try decode(InviteLink.self, """
        {"invite_id":"i1","member_id":"m1","email":"a@b.co","token":"t","code":"K7Q2MX",
         "link":"https://www.fhbtechservices.com/kameti/join/t","expires_at":"2026-11-24T10:00:00+00:00"}
        """)
        #expect(link.code == "K7Q2MX")

        let invite = try decode(Invite.self, """
        {"id":"i1","kameti_id":"k1","member_id":"m1","status":"pending",
         "expires_at":"2026-11-24T10:00:00+00:00","send_count":1}
        """)
        let before = invite.expiresAt.addingTimeInterval(-60)
        let after = invite.expiresAt.addingTimeInterval(60)
        #expect(!invite.isExpired(at: before))
        #expect(invite.isExpired(at: after))
    }

    @Test func auditEntryKeepsFreeFormJSON() throws {
        let e = try decode(AuditEntry.self, """
        {"id":7,"kameti_id":"k1","member_id":"m1","actor_id":"u1","action":"payment.void",
         "entity":"payment","entity_id":"p1","before":null,
         "after":{"amount":100000,"void_reason":"typo"},"at":"2026-11-09T12:00:00+00:00"}
        """)
        #expect(e.after?["amount"]?.intValue == 100_000)
        #expect(e.after?["void_reason"]?.stringValue == "typo")
    }
}
