# Money and ledger rules (app and backend)

The source of truth is `docs/REQUIREMENTS.md` §3 and §6.5–6.6. These rules are not negotiable, because a wrong number destroys trust in a money app.

1. **Integer rupees only.** Swift `Money` wraps an `Int`; Postgres uses `bigint`. Never `double`, `num` or `numeric` with decimals for amounts.
2. **Definitions:** N = months = slots. C = slot amount per month. Pot = N × C. A slot's shares add up to exactly C, with each share ≥ Rs 1,000 and a multiple of Rs 1,000. At most 4 sharers per slot. Slots per member: per-kameti limit, default 4, max 6.
3. **Due** per member per month = the sum of their active shares in that kameti. **Payout** per sharer = share × N.
4. **Payments are applied oldest due first.** The balance is cumulative: total due through the current month minus valid payments. A negative balance is **credit**. Month statuses (paid / partial / unpaid / overdue / advance) come from that allocation.
   - A month has two totals. **Received** is the cash recorded in that month (payment date, Pakistan time); the payout and its shortfall use it. **Covered** is how much of that month's dues the oldest-due-first allocation covers; member statuses and "N of M paid" use it. Example: October received 49,70,000 (short 30,000) but covered 48,45,000, because Naveed's extra 1,25,000 counts toward November.
5. **Balances and statuses are calculated, never stored.** There is one implementation in the backend (SQL views). The app reads balances and statuses from those views; where it must work something out itself (previews, Home cards), the logic lives in KametiKit with unit tests that match the backend.
6. **Append-only:** payments and payouts are never deleted or edited in place for amounts. A correction is a void plus a new entry, and both are audited.
7. **Formatting:** only via `Money.format()` / `KMoneyText`, in the lakh/crore style (`Rs 24,00,000`, compact `24 L`, `2.4 Cr`).
8. **Reference fixture:** the backend's pgTAP test `supabase/tests/reference_sheet_oct26.test.sql` encodes the Oct 2026 – May 2028 kameti:
   - N = 20, C = 2,50,000, 15 members;
   - October's recorded payments total 49,70,000;
   - Naveed has 1,25,000 credit after October;
   - Osama has a 1,80,000 advance against December.

   Any change to ledger code must keep this fixture passing. It uses **names only**: no emails or phones.
9. Any PR touching ledger maths needs a test for each of these: partial payment, overpayment → credit, advance, void, shared slot payout, and payout with a shortfall.
