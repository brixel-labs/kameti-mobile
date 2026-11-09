# Kameti — Product Requirements (v0.1 draft)

> Status: **Draft for review.** Once finalised, this document is the single source of truth for design, build and test.
> Date: 2026-11-09 · Platforms: iOS + Android

---

## 1. Product summary

Kameti is a **record-keeping and transparency app** for running a kameti (committee / ROSCA). An **owner** creates and runs a kameti; **members** sign in and get a read-only view of their dues, payment history, payout schedule and each month's pot status.

**No money moves through the app.** Members pay the owner by cash or bank transfer as they do today. The owner records each payment in the app.

The app answers three questions for everyone:
1. *What do I owe, and am I up to date?*
2. *Who has paid this month, and how full is the pot?*
3. *Whose turn is it, and when is mine?*

---

## 2. Glossary

| Term | Meaning |
|---|---|
| **Kameti** | One savings group with a fixed number of months, a start month and a slot amount. An owner can run many. |
| **Owner** | The user who created the kameti. The only person who can change it. |
| **Member** | A person taking part in a kameti. They may or may not have signed into the app yet. |
| **Slot** | One month's payout. *Number of slots = number of months.* Each slot has a payout month. |
| **Slot amount (C)** | What one full slot contributes **every month** (e.g. Rs 2,00,000). |
| **Pot / Kameti amount** | Total collected in a month = **N × C** (e.g. 12 × 2,00,000 = Rs 24,00,000). This is also what one slot receives in its payout month. |
| **Share** | A member's portion of a slot. A slot has 1–4 shares that add up to C. |
| **Due** | What a member owes per month = the sum of all their shares across all slots in that kameti. |
| **Payment** | Money a member paid to the owner, recorded by the owner. |
| **Payout** | The pot handed to the slot holder(s) in that slot's month. |

---

## 3. Core rules (the money maths)

Let **N** = number of slots (= months) and **C** = slot amount per month.

1. **Monthly pot** = N × C.
2. Each slot has **1–4 shares**. The shares' monthly amounts must **add up to exactly C**.
3. A member's **monthly due** in a kameti = the sum of their share amounts across every slot they hold in it.
4. **Every member pays their due every month for all N months.** That includes the month they receive the pot and the months after it.
5. In a slot's payout month, the pot is split **in proportion to the shares**. Each sharer receives `share_amount × N`.
   - Example: N = 12, C = 2,00,000, slot split 50k / 50k / 1L → payouts 6L / 6L / 12L.
6. Over the whole kameti, **each member receives exactly what they pay in**. There is no interest, fee or bidding.
7. All amounts are **whole Pakistani rupees** (no paisa), stored as integers.

### 3.1 How a slot is split (decided)

- Shares can be **any amount in steps of Rs 1,000**. Each share must be at least Rs 1,000, and the shares must add up to exactly C.
- The split is entered **by amount, not by fraction**. Each sharer has quick **amount chips** (e.g. 25K · 50K · 1L · 1.25L, generated from C) plus **Custom**.
- A **"Give the rest: Rs X"** button fills the last sharer with whatever is left.
- An "Assigned Rs X of C" bar shows progress. The slot can't be saved until it adds up exactly.
- Example: C = 2,00,000 split 50K + 50K + 1L.
- Why: free amounts cover real cases like 50k / 50k / 1L, and because shares are whole rupees, payouts (share × N) are always whole numbers too. No rounding drift.

### 3.2 Limits

| Limit | Value | Notes |
|---|---|---|
| Sharers per slot | **max 4** | |
| Slots per member (in one kameti) | per-kameti setting, **default 4, max 6** | Your current sheet needs 5 (Sameer) |
| Kameti length (N) | 2 – 60 months | |
| Members per kameti | up to N × 4 | follows from the limits above |
| Kametis per owner | unlimited | each kameti has fully separate records |

### 3.3 Worked example: your current sheet (Oct 2026 – May 2028)

- N = 20, C = Rs 2,50,000, pot = Rs 50,00,000 a month, 15 people.
- "Zeeshan" (Oct) is a full slot. "Ata + Sameer" (Nov) is one slot split 1.25L + 1.25L, so each receives Rs 25,00,000.
- Zeeshan holds 3 full slots, so his due is Rs 7,50,000 a month. Sameer holds 3 full and 2 half slots, so his due is Rs 10,00,000 a month.
- This dataset becomes an **acceptance test**: the app must reproduce every due and payout from the sheet.

---

## 4. Roles and permissions

| Action | Owner | Member |
|---|---|---|
| Create, edit or archive a kameti | ✅ | ❌ |
| Add, edit or remove members | ✅ | ❌ |
| Create slots, set shares, set payout order | ✅ | ❌ |
| Record, edit or void payments and payouts | ✅ | ❌ |
| Write notes | ✅ | ❌ (v1) |
| Send a reminder broadcast | ✅ | ❌ |
| View the kameti overview, schedule and month status | ✅ | ✅ |
| View own dues, payments and payouts | ✅ | ✅ |
| View other members' paid/unpaid status | ✅ | ✅ (owner can hide it per kameti: D3) |
| View other members' exact amounts | ✅ | configurable (D3) |

- The owner can also be a member of their own kameti. This is common.
- A person can be the owner of some kametis and a member of others at the same time. Both kinds appear on one home screen.
- **Server-side enforcement:** read-only access is enforced in the database (row-level security), not only by hiding buttons.

---

## 5. Sign-in, privacy between groups, and invites

### 5.1 Sign-in
- **Sign in with Google** and **Sign in with Apple** only. No phone OTP and no email/password.
  - Apple requires Sign in with Apple on iOS whenever Google sign-in is offered. Both are already planned.
- Anyone can sign in and **create their own kameti**. Every user can be an owner.

### 5.2 Each kameti is a private, closed group
- A kameti works like a **private group**. Only its owner and the members who have **accepted an invite to it** can see it.
- **Groups never see each other.** Members of kameti A never see that kameti B exists, who is in it or any of its data. This holds:
  - when A and B have different owners, and
  - when **the same owner** runs both.
- A person who is in both A and B sees both on their home screen, **each on its own**. Nothing is merged, and B's members are never shown inside A.
- **Inside a kameti**, members see each other's **names** and paid/unpaid status (D3). They **never** see another member's email or phone. Only the owner sees those.
- **Before a member accepts an invite they see nothing.** The kameti is entirely invisible to them until they join.
- **Enforcement:** the database's row-level security only returns a kameti's rows to its owner and its *joined* members. A user can't read another group by guessing IDs.

### 5.3 Owner's contacts ("My people")
- Each owner has a **private contact list**: name, email, optional phone and a note. Only that owner can see it.
- Creating a kameti, the owner either **picks existing contacts** (e.g. people from an earlier round) or **adds new people**. Anyone added is saved to the contacts list automatically.
- Contacts are **per owner**. Owner X never sees Owner Y's contacts, even when the same person is in both lists.
- Adding a contact to a kameti creates a **member record in that kameti**. The member's ledger always belongs to that kameti.

### 5.4 Invites by email (main flow)
1. The owner adds members to the kameti, each with a name and email.
2. The owner selects **one, several, or "all not invited"** and taps **Send invites**.
3. Each person gets an email from Kameti:
   - "*Hassan invited you to join 'Office Kameti 2026'*",
   - their slot, monthly amount and payout month,
   - a **Join** button with a **personal, single-use link** (`https://<domain>/join/<token>`),
   - a **6-character invite code** as a fallback.
4. **Opening the link:**
   - **App installed:** the link opens the app (iOS Universal Links / Android App Links).
   - **App not installed:** the link opens a simple web page with App Store and Play Store buttons and the invite code. After installing, the user signs in and the invite is found, either automatically by email or by entering the code.
5. The member signs in with Google or Apple and sees an **"Accept invite"** screen:
   - the kameti name and owner,
   - their slot(s), share, monthly due and payout month(s).

   They tap **Join** or **Decline**.
6. After joining, the kameti appears on their home screen (read-only). The owner sees the member as **Joined ✓** and gets a notification.

**What makes an invite safe**
- Each token belongs to **one member record**. It is single-use and **expires after 14 days**. The owner can **resend** it (which makes a new link and cancels the old one) or **revoke** it at any time.
- **When the email used to sign in doesn't match the invited email** (forwarded link, Apple "Hide My Email", or a different Google account):
  - the member can still accept, but their status becomes **"Waiting for approval"**;
  - the owner sees "*Ata accepted using a••••@privaterelay.appleid.com, invited as ata@gmail.com*" and taps **Approve** or **Reject**;
  - nothing is shown to the member until the owner approves.
  - This stops a forwarded link from letting the wrong person into the group.
- **When the email matches**, the member is added straight away with no approval step.
- **Automatic match:** if someone signs into the app for the first time with an email that has pending invites, those invites appear in an **"Invitations"** inbox. They still have to tap Join, and they are never added silently.
- **Sharing on WhatsApp (optional):** the same personal link can also be shared through WhatsApp or the share sheet, for people who don't check email. The same rules apply.

**Invite status per member, as the owner sees it**

| Status | Meaning | Owner actions |
|---|---|---|
| Not invited | Added to the ledger, no invite sent | Send invite |
| Invited | Email sent, waiting | Resend, Revoke, Copy link |
| Waiting for approval | Accepted with a different email | Approve, Reject |
| Joined | Linked to an account | Unlink |
| Declined / Expired | Didn't join | Resend |

- **A member never has to join** for the kameti to work. Members who haven't joined are still in the ledger, and the owner records their payments as normal. They just don't get the app view or push reminders (FR-84 WhatsApp reminders cover them).
- Invite emails are rate-limited to **20 per kameti per hour**, and a resend to the same person to **once every 10 minutes**.

### 5.5 Linking, unlinking and leaving
- One account can be a joined member of many kametis, under many owners, and can also own kametis.
- The owner can **unlink** a member (e.g. the wrong person joined). They lose access straight away, and the member record and its history stay in the ledger.
- A member **can't leave** a kameti themselves, because they still owe or are owed money. They can **mute** its notifications or **hide** it from their home screen.
- **Account deletion** is in the app, as Apple and Google require:
  - A member deleting their account is unlinked, and their member record stays in the owner's ledger.
  - An owner with active kametis is blocked: they must archive or hand over those kametis first (see D5).

---

## 6. Functional requirements

### 6.1 Home (all users)
- FR-1: List every kameti the user **owns** or is a **member of**, grouped as "Running by me" and "I'm a member".
- FR-2: Each card shows the name, the current month (e.g. "Month 2 of 20"), this month's recipient(s), "You owe Rs X this month" or "Paid ✓", and the collection progress.
- FR-3: Archived and completed kametis appear in a separate "Past" section.

### 6.2 Create a kameti (owner)
- FR-10: Wizard steps:
  1. **Kameti name** (required, 3–40 characters, e.g. "Office Kameti 2026"; must be unique among the owner's active kametis; can be renamed at any time), an optional description, start month, N (months) and C (slot amount). The pot and total are shown live.
  2. Due-day settings: due by the **10th** by default; the reminder window is days 1–10.
  3. Add members.
  4. Build slots and shares.
  5. Set the payout order.
  6. Review, then **Start**.
- FR-11: A kameti is a **Draft** until started. Everything in a draft can be edited freely.
- FR-12: **Start is blocked** unless all of these hold:
  - exactly N slots exist;
  - every slot's shares add up to C;
  - every slot has a payout month;
  - no member exceeds the slot limit.
- FR-13: The owner can duplicate an existing kameti as a new draft, keeping the members and structure but no payments.

### 6.3 Members (owner)
- FR-20: Add, edit or remove members, either by **picking from the owner's contacts** or by adding a new person (§5.3). Fields: name, email, phone, nickname or relation (e.g. "Ata – office"), avatar initial and colour. Send, resend or revoke invites from here (§5.4).
- FR-21: A member can only be removed while they hold no shares and have no payments. Otherwise the owner must use **Replace / transfer** (FR-33).
- FR-22: Two members can share a display name. They are told apart by internal ID, with an optional nickname to tell them apart on screen.

### 6.4 Slots, shares and payout order (owner)
- FR-30: The slot list shows month, recipient(s), shares and a note.
- FR-31: Add or edit shares on a slot using amount chips, custom amounts or "Give the rest" (§3.1), with live validation ("Rs 50,000 left to assign").
- FR-32: **Payout order:**
  - Drag to reorder, or swap two slots.
  - Months already paid out are **locked**.
  - After the kameti starts, only unpaid future months can be reordered, and every change is written to the audit log and the affected members are notified.
- FR-33: **Replace or transfer a share.** A share moves from member A to member B from a given month onward.
  - A's past payments stay with A.
  - The settlement between A and B (who refunds whom) is recorded as a note. It is outside the app's maths.
- FR-34: Changing C or N after start is **not allowed** (it would break every payout). The owner must close the kameti and start a new one. See D6.

### 6.5 Recording payments (owner)
- FR-40: Record a payment:
  - **Required:** member, amount, date received.
  - **Optional:** method (cash, bank transfer, other), reference, note, receipt photo (v1.1).
- FR-41: **Ledger model.** Payments are applied **oldest-due-first** to the member's running balance:
  - **Partial payment:** the month is marked *Partial*, and what's left carries forward as dues.
  - **Overpayment or advance:** the extra becomes **credit** that pays future months automatically. This covers Naveed's 250k in October and Osama's 180k for December.
- FR-42: **Quick "Mark paid in full".** One tap records exactly this month's outstanding amount, dated today.
- FR-43: **Record many at once ("tap to settle").** A list of everyone who still owes this month:
  - one tap marks a member's full outstanding amount; holding (or **Edit**) enters a different amount for a partial payment;
  - **Mark all paid** marks everyone;
  - the pot bar shows marked-but-unsaved money in a lighter shade;
  - one date and one method apply to the whole batch;
  - nothing is written until **Save N payments · Rs X**, which records each payment separately (each one audited and notified) in a single transaction;
  - tapping a marked member again undoes it before saving.
- FR-44: Edit or **void** a payment. Payments are never hard-deleted. Voided entries stay in the audit trail, and balances recalculate.
- FR-45: **Paid by someone else.** A payment can carry an optional "paid by" name (e.g. Hassan paying Ata's share). It still counts towards Ata's balance.
- FR-46: Backdated payments are allowed. Future-dated payments are not.

### 6.6 Payouts (owner)
- FR-50: Each month has a status:
  - **Upcoming:** a future month.
  - **Collecting:** the current month.
  - **Fully collected:** everything due this month has been received.
  - **Paid out:** the pot has been handed over.
  - **Paid out (short Rs X):** the pot was handed over with a shortfall.
- FR-51: Record the payout for each recipient: amount, date, method and note. For a shared slot, the expected amounts are pre-filled in proportion to the shares.
- FR-52: The owner **can mark a month paid out even if collection is short**. The shortfall is shown and kept against the members who still owe (they continue to show dues). The question of who covered the gap is answered with a note (see D2).
- FR-53: A payout can be recorded in more than one part (e.g. half today, half next week).

### 6.7 Member view (read-only)
- FR-60: "My dues" per kameti: monthly due, total paid, outstanding balance or credit, and the next payment date.
- FR-61: "My payout": my month(s), my share and the expected amount, and the status (upcoming, received).
- FR-62: Full payout schedule, with my months highlighted.
- FR-63: Current month board: who has paid, partially paid or not paid, and the collection progress bar.
- FR-64: My payment history, with dates and receipts.

### 6.8 Notes
- FR-70: The owner can add **timestamped notes** to a kameti, a member, a slot, a payment or a payout. Examples: "Ata pays 275k, remaining 100k covered by Hassan"; "Naveed's extra 125k is advance for Nov".
- FR-71: Each note is **Private** (owner only, the default) or **Shared** (visible to the members involved).
- FR-72: Notes are listed on their item and in a kameti-wide "Notes" feed, and can be searched.

### 6.9 Reminders and notifications
- FR-80: **Automatic reminders.** During the reminder window (default days 1–10, in Asia/Karachi time), members with an outstanding balance for the current month get a push notification. The default schedule is the **1st, 5th, 8th and 10th at 10:00 AM**, and the owner can change it per kameti.
  - Members who are fully paid (including through credit) are **never** reminded.
- FR-81: **Overdue.** After the due day, the member gets an "Overdue" reminder and the owner gets a digest (e.g. "3 members still owe Rs 4,50,000 for November").
- FR-82: **Owner broadcast.** One tap sends a reminder to **all unpaid members** of a kameti. The owner can optionally edit the message and choose recipients (e.g. all members, unpaid only, or selected people).
  - Rate limit: at most **one broadcast per kameti per day**.
- FR-83: **Event notifications** to members:
  - a payment was recorded for you;
  - a payment was edited or voided;
  - your payout month is next month;
  - you have been paid out;
  - the payout order changed;
  - you were added to a kameti.
- FR-84: Members without the app (unlinked) get no push. For them the owner gets a **"Share reminder on WhatsApp"** action that opens WhatsApp with a pre-filled message.
- FR-85: Notification preferences per user: reminders on or off, and event notifications on or off. The owner's broadcast always arrives unless the user has turned off OS notifications.
- FR-86: An **in-app notification inbox** keeps every notification, so nothing is lost if a push fails.

### 6.10 History, audit and export
- FR-90: An **audit log** per kameti records who changed what and when: payments, payouts, order changes and share transfers. The owner sees all of it. Members see the entries that affect them.
- FR-91: Export the kameti as a **PDF / image summary** to share on WhatsApp, and as a **CSV** (in the spreadsheet layout).
- FR-92 (v1.1): **Import** from CSV in the current spreadsheet layout, to migrate the existing Oct 2026 kameti.

### 6.11 Kameti lifecycle
- **States:** Draft → Active → Completed → Archived. A kameti can also be **Cancelled** from Draft or Active.
- **Completed:** all N payouts recorded. Outstanding dues are still shown, and it closes once every balance is zero (or the owner force-closes it with a note).
- **Archived:** read-only for everyone, hidden from the main list, and can be restored.
- **Cancelled while active:** the owner records how money was settled, using notes and payouts. The app shows each member's net position (paid in − received).

---

## 7. Edge cases (must be handled)

### Structure
- E1: Shares don't add up to C → the slot is invalid and the kameti can't start.
- E2: A typed share isn't a multiple of Rs 1,000, or the shares go over C → inline error on that field; "Give the rest" is hidden when nothing is left or the remainder is under Rs 1,000.
- E3: A member would exceed the slot limit (4) or a slot would exceed 4 sharers → blocked with a clear message.
- E4: The same member holds two shares of the **same** slot → merge them into one share.
- E5: A slot has no payout month, or two slots claim the same month → can't start.
- E6: The owner tries to change N or C after start → blocked (FR-34).
- E7: A slot is reordered into a month that was already paid out → blocked.
- E8: A member in a draft is removed while they still hold shares → the affected slots become invalid and are highlighted.

### Payments
- E10: Partial payment → the month shows Partial and the remainder carries forward.
- E11: Overpayment → credit, applied to the next months automatically and shown as "Credit Rs X".
- E12: Advance for a future month (Osama's 180k for December) → treated as credit, and December shows "Rs 1,80,000 of 3,75,000 paid in advance".
- E13: Payment for a member who has already received their payout → normal. They still owe every month.
- E14: Payment recorded against the wrong member → void and re-enter. Both actions are audited and both members are notified.
- E15: A large backdated correction changes past month statuses → recalculate, and only notify the members affected.
- E16: Two owner devices record the same payment at the same time → duplicate warning (same member, amount and date within 2 minutes) and an idempotency key on create.
- E17: A payment amount of 0 or less is rejected. An amount larger than everything left the member owes for the whole kameti is allowed, with a warning.

### Payouts
- E20: Paid out while collection is short → allowed, with the shortfall shown (FR-52).
- E21: A shared slot is paid out to one sharer only so far → the month shows *Partially paid out*.
- E22: The payout amount differs from what's expected → allowed, and the owner must add a note.
- E23: The recipient hasn't paid their own dues → warn the owner before recording the payout (e.g. "Ata owes Rs 1,00,000. Deduct it from the payout?"). A deduction is recorded as a payment plus a reduced payout.

### Members and people
- E30: A member drops out **before** receiving → transfer the share to a replacement (FR-33) or cancel the kameti.
- E31: A member stops paying **after** receiving (defaulter) → dues keep accumulating, the member is flagged "Defaulter" for the owner, and reminders continue.
- E32: A member dies or leaves permanently → transfer to a successor and add notes.
- E33: An invite link is forwarded to or opened by the wrong person → the email doesn't match, so the owner has to approve (§5.4). If the owner approves by mistake, they can unlink, and a new link cancels the old one.
- E34: A user signs in with Apple's private relay email → handled by the invite link plus owner approval.
- E38: An invite link is opened after it expired, was revoked or was already used → a clear "This invite is no longer valid. Ask {owner} to resend." screen.
- E39: An invite is opened by someone already in that kameti on another member record → blocked, with a message to the owner (duplicate person).
- E39a: The owner removes a member who has a pending invite → the invite is revoked automatically.
- E39b: The invite email bounces or goes to spam → the owner sees "Bounced" status and can copy the link to share on WhatsApp.
- E39c: The same email is invited to two different kametis → two separate invites. Accepting one never reveals the other kameti.
- E35: A user signs in with Google on one device and Apple on another → these are two accounts. Allow **linking both providers** to one account from settings.
- E36: The owner's own account is deleted or lost → see D5 (co-owner or recovery).
- E37: A member is in several kametis with different owners → each kameti is shown separately, and dues are never combined across owners.

### Time and notifications
- E40: All dates are calculated in **Asia/Karachi**, wherever the device is. A member abroad still sees the PK due date.
- E41: Push token expired or app uninstalled → remove the token, and the in-app inbox still records the notification.
- E42: The owner taps broadcast twice → the daily rate limit applies, with a "Sent today at 10:42" state.
- E43: A month whose reminder days fall on a weekend or holiday → no special handling in v1.
- E44: Kameti started mid-month → month 1 is the start month, and the reminder window applies from the next scheduled day.

### App and platform
- E50: Offline → cached data is shown read-only with a "Last updated…" banner. Owner writes need a connection in v1 and give a clear error otherwise.
- E51: Large kameti (60 months × 240 members) → lists are virtualised and the month grid paginates.
- E52: Number format → PKR in **lakh/crore grouping** (Rs 24,00,000), with a compact "24 L" or "2.4 Cr" in tight spaces.
- E53: Dark mode, dynamic font size and screen readers are supported.

---

## 8. Non-functional requirements

| Area | Requirement |
|---|---|
| Platforms | iOS 16+, Android 8+ (API 26+), phones only in v1 |
| Performance | Cold start under 2.5 s on a mid-range Android; a dashboard with a 20-month kameti renders in under 1 s from cache |
| Security | Row-level security on every table; the client can never write as a member; all money writes go through validated database functions |
| Integrity | Money stored as integer rupees; payments and payouts are append-only with void + audit; maths checked by unit tests against the sheet's data |
| Privacy | No real payment data collected; email and phone visible only to the owner; a privacy policy and in-app account deletion |
| Localisation | English in v1, with strings externalised; Urdu (RTL) in v1.1 |
| Availability | Managed backend, daily backups, point-in-time recovery |
| Analytics and crash reporting | Crash reporting (Sentry); privacy-respecting product analytics without amounts or names |
| Accessibility | WCAG AA contrast, 44 pt touch targets, screen-reader labels |

---

## 9. Tech stack recommendation

### 9.1 Mobile: **Flutter (Dart)**, cross-platform (decided 2026-11-09)

| Option | Verdict |
|---|---|
| **Flutter** ✅ | One codebase for iOS and Android with pixel-identical UI on both, which suits a custom design system. Strong typing, fast rendering of long lists and grids, first-party Supabase SDK. You already ship VoiceQuote with Flutter. |
| React Native (Expo) | Equally capable; not chosen. |
| Native (Swift + Kotlin) | Two codebases, twice the effort, and no benefit for a forms-and-lists app. |

**Packages:**

| Concern | Choice |
|---|---|
| SDK | Flutter stable channel, Dart 3 (null safety, records, sealed classes); versions pinned with FVM |
| State management | `flutter_riverpod` + `riverpod_generator` |
| Navigation and deep links | `go_router` + `app_links` (Universal Links / App Links for `/kameti/join/*`) |
| Models | `freezed` + `json_serializable` |
| Backend SDK | `supabase_flutter` |
| Sign-in | `google_sign_in` + `sign_in_with_apple`, exchanged with Supabase `signInWithIdToken` |
| Push | `firebase_messaging` (FCM, which also delivers to APNs) + `flutter_local_notifications` for foreground display |
| Offline cache | `drift` (SQLite) for read-only cached data (E50) |
| Localisation | Flutter `gen-l10n` with ARB files (English v1, Urdu RTL v1.1); `intl` for dates |
| Money formatting | A small in-house `Money` type with lakh/crore grouping (§3, E52), unit-tested |
| Forms | Flutter `Form` + design-system fields with shared validators |
| Crash reporting and analytics | `sentry_flutter`; `posthog_flutter` (optional) |
| Lints | `very_good_analysis` |
| Tests | `flutter_test`, `mocktail`, golden tests for the design system (`alchemist`), `integration_test` |
| Environments | Flavors `dev` / `staging` / `prod` with `--dart-define-from-file` |
| Builds and releases | GitHub Actions for CI (analyze, test); Codemagic or Fastlane for signed builds and store upload; optional Shorebird code push for urgent fixes |

### 9.2 Backend: **Supabase** (Postgres) recommended over Firebase

| | Supabase ✅ | Firebase |
|---|---|---|
| Data shape | Relational: kameti → slots → shares → members → payments. Joins and SUMs are natural. | NoSQL documents. Balances need manual denormalisation or Cloud Functions. |
| Money integrity | Foreign keys, CHECK constraints (shares add up to C), transactions, Postgres functions | Rules can't enforce cross-document sums. Transactions are limited. |
| Read-only members | Row-level security policies in SQL | Security Rules (fine, but harder for derived permissions) |
| Reminders | `pg_cron` + Edge Function → FCM | Scheduled Cloud Function → FCM |
| Auth | Google + Apple built in | Google + Apple built in |
| Cost at scale | Flat tiers, no per-read billing | Per-document reads: month grids viewed by many members add up |
| Lock-in | Plain Postgres, easy to move | High |

Firebase is a valid choice, and we still use **Firebase Cloud Messaging** (only) for push. But this app is a **ledger**, and a relational database with constraints is the safer foundation.

### 9.3 Proposed architecture

```
Flutter app (iOS/Android)
  ├─ Supabase Auth (Google, Apple)
  ├─ PostgREST reads (RLS-protected views)
  └─ RPC calls for all writes (record_payment, record_payout, reorder_slots, …)
Supabase Postgres
  ├─ tables + RLS + audit triggers
  ├─ views: member_balances, month_status
  └─ pg_cron → Edge Function "send-reminders" (daily 10:00 PKT)
Edge Functions (Deno/TS): reminders, broadcast, send-invites, accept-invite, account deletion
Transactional email: Resend, sending from a subdomain of fhbtechservices.com (§9.5)
Web: pages under www.fhbtechservices.com/kameti/* in the existing fhb-website repo (§9.5)
Edge Functions → FCM HTTP v1 API → Android / APNs (iOS)
Sentry (crashes), PostHog (analytics, optional)
```

### 9.4 Draft data model

```
profiles(id, display_name, avatar_url, created_at)
auth_identities (managed by Supabase: google/apple)
kametis(id, owner_id, name, start_month, months_n, slot_amount_c,
        due_day=10, reminder_days int[]={1,5,8,10}, status, privacy_settings jsonb,
        created_at, archived_at)
contacts(id, owner_id, name, email, phone, note, created_at)          -- private per owner
members(id, kameti_id, contact_id, profile_id NULL, name, nickname, color,
        join_status[not_invited|invited|pending_approval|joined|declined], created_at)
invites(id, member_id, token_hash, code, sent_to_email, sent_at, expires_at,
        accepted_by_profile_id NULL, accepted_email NULL, status, revoked_at)
slots(id, kameti_id, payout_month_index 1..N UNIQUE per kameti)
shares(id, slot_id, member_id, monthly_amount, effective_from_month, effective_to_month NULL)
payments(id, kameti_id, member_id, amount, received_on, method, reference, paid_by_name,
         recorded_by, idempotency_key, voided_at, void_reason)
payouts(id, slot_id, member_id, amount, paid_on, method, recorded_by, voided_at)
notes(id, kameti_id, target_type, target_id, body, visibility, author_id, created_at)
notifications(id, user_id, kameti_id, type, title, body, data, read_at, created_at)
broadcasts(id, kameti_id, sent_by, message, recipient_count, sent_at)
device_tokens(id, user_id, token, platform, last_seen_at)
audit_log(id, kameti_id, actor_id, action, entity, entity_id, before jsonb, after jsonb, at)
```

### 9.5 Website and email on the existing domain

The web side lives in the existing **fhb-website** repo (Next.js 16 App Router, Tailwind 4, deployed on Vercel at `https://www.fhbtechservices.com`). No new domain is needed.

**App identifiers:** iOS bundle ID and Android package name `com.brixel.kameti` (Brixel Labs brand; differs from the older `com.fhbtechservices.*` apps, which is fine because App Links / Universal Links are keyed by app ID, not domain).

**New routes to add to fhb-website**

| Route | Purpose | Notes |
|---|---|---|
| `/kameti` | App landing page: what it is, screenshots, store buttons | Added to `lib/apps.ts` once the app is live in the stores |
| `/kameti/join/[token]` | Fallback page when the invite link opens in a browser: "Open in app" button, App Store / Play Store buttons, "Use the 6-character code from your email" | **Static, no data fetch.** It never shows kameti or member details, so a leaked link reveals nothing. `noindex` |
| `/kameti/privacy` | Kameti app privacy policy (required by both stores) | Separate from the website's own policy, which only covers the contact form |
| `/kameti/terms` | Terms of use | |
| `/kameti/delete-account` | How to delete your account and data | **Required by Google Play** as a web URL, in addition to in-app deletion |
| `/kameti/support` | Support / contact | Required App Store field |
| `/.well-known/apple-app-site-association` | Lets iOS open `/kameti/join/*` links in the app | Route handler returning `application/json`, no redirect. Built so DeenFlow / VoiceQuote can be added later |
| `/.well-known/assetlinks.json` | Lets Android open `/kameti/join/*` links in the app (App Links) | Needs the Play App Signing SHA-256 fingerprint |

**Rules for the website changes**
- Invite links always use **`www.fhbtechservices.com`**, the host the site actually serves. A redirect between the apex domain and `www` breaks Universal Links on the redirected host.
- The existing Content-Security-Policy stays unchanged, because the join page makes no client-side calls to Supabase.
- `robots.ts` disallows `/kameti/join/`, and the sitemap excludes it.
- The landing, legal and support pages reuse the site's existing layout, navbar, footer and theme.
- Changes to that repo follow its own `AGENTS.md` (Next.js 16 conventions).

**Email (Resend)**
- Send from a **subdomain**, e.g. `Kameti <invites@mail.fhbtechservices.com>`, so the app's email reputation is kept apart from the main domain's.
- Add Resend's SPF, DKIM and DMARC DNS records for that subdomain wherever fhbtechservices.com's DNS is managed.
- The Resend API key lives only in Supabase Edge Function secrets, never in the app or the website.
- Resend webhooks (delivered / bounced / complained) update the invite's status, which drives the "Bounced" state (E39b).

- Balances and month statuses are **calculated in views**, never stored.
- `shares.effective_from/to_month` supports transfers (FR-33) without rewriting history.

---

## 10. Delivery plan

| Phase | Scope | Est. |
|---|---|---|
| **0. Foundations** | Repos, Flutter app (flavors, FVM), Firebase project (FCM only), Supabase project, CI, environments (dev/staging/prod), design system tokens, Claude agents/rules/skills | 1 wk |
| **1. Design** | Screens with 2–3 visual directions → choose one → hi-fi screens for every flow | 1–2 wks |
| **2. MVP core** | Auth (Google/Apple), create-kameti wizard, members, slots/shares, payout order, record payments/payouts, ledger maths, member read-only views, home | 4–5 wks |
| **3. Engagement** | Reminders (auto + broadcast), event notifications, inbox, notes, email invites (Resend) + owner approval, audit log; in fhb-website: `/kameti/join`, `.well-known` files | 2–3 wks |
| **4a. Website** | In fhb-website: `/kameti` landing, privacy, terms, delete-account, support pages; Resend DNS records | 3–4 days |
| **4. Polish and launch** | PDF/CSV export, WhatsApp share, account deletion, empty and error states, accessibility, store assets, privacy policy, TestFlight / Play internal testing with your real kameti | 2 wks |
| **v1.1** | Urdu (RTL), CSV import, receipt photos, linking two sign-in providers to one account, co-owner | later |

**Acceptance gate for MVP:** your Oct 2026 – May 2028 kameti is entered in the app, and every due, balance, credit and payout matches the spreadsheet.

---

## 11. Decisions (agreed 2026-11-09)

| # | Decision | Agreed |
|---|---|---|
| D1 | Max slots per member | Per-kameti setting, **default 4, max 6** |
| D2 | When a pot is paid out short, who covers the gap? | Record only: the owner notes it, and the debtors keep owing |
| D3 | Can members see **other members'** payment status and amounts? | Status yes (within the same kameti only); amounts as an owner setting, on by default |
| D4 | Can members add their own notes or "I've paid" claims? | v1.1: an "I've paid" request the owner approves |
| D5 | Co-owner or ownership transfer | Ownership transfer in v1; co-owner in v1.1 |
| D6 | Allow changing C or N mid-kameti? | No. Close it and start a new one |
| D7 | Monetisation | Free for v1 |
| D8 | Urdu | v1.1 |
| D9 | How a slot is split | Any amount in **Rs 1,000 steps**, adding up exactly to C, entered with amount chips + Custom + "Give the rest" (no fraction presets) |
| D14 | Visual design | Direction **A "Ledger"** (light, emerald, Inter) with a dark mode; the payout schedule uses the 4-column month grid. Board: https://claude.ai/artifact/CU8Y4xmfhCPFHoMyavyf6e |
| D15 | Recording many payments | **Tap to settle** (FR-43) |
| D10 | Group privacy | Each kameti is a closed group; groups never see each other (§5.2) |
| D11 | Joining | Personal email invite link + code; owner approval when the email doesn't match (§5.4) |

| D12 | Domain | Use the existing **www.fhbtechservices.com** with `/kameti/*` pages (§9.5) |
| D13 | Transactional email | **Resend**, from a mail subdomain |
