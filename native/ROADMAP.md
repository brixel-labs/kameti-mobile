# Native iOS roadmap

Status of the native SwiftUI app (`native/ios`) against the Flutter app and the design canvas, and the order of work. Updated 2026-11-10.

Each step is done on its own branch cut from `feature/native-ios`, with one commit per finished feature and no push without asking.

## Done

- Foundation: package layers (Core, Domain, UI, Data, Navigation, TestSupport, features), design tokens, router, deep-link parsing.
- Sign-in with Apple and Google, session handling, glass tab bar (Home, Inbox, Profile).
- Data layer: every repository call exists (kametis, members, slots and shares, ledger views, payments and payouts, invites, activity, profile, contacts, auth). Only exercised against the demo store so far.
- Shared components: amount field, chips, stepper, bottom sheet, select field, checkbox, switch, underline tabs, reorderable list, avatar stack, tonal button.
- Create wizard, six steps, reworked to the canvas.
- Demo flavor with sample kametis (`native/ios/scripts/use-env.sh demo`).
- Home cards (owner, member, past) and the owner Overview tab matched to the canvas.

## Screens: state

| Screen | State | Missing or unchecked |
|---|---|---|
| Sign-in | Built | Not compared to its artboard |
| Home | Cards match the canvas | Invitations section, empty state and invite-code card unchecked, "Run by …" line |
| Create wizard | Steps 1–6 built | Steps 1 and 6 loosely checked; overdue/summary switches and "email invites on start" are display only; reopening a draft |
| Detail, Overview | Matches the canvas | Remind and Record payment buttons do nothing |
| Detail, Members / Schedule / Payments | Built from Flutter | Not checked against the canvas |
| Member view | Built from Flutter | Not checked against the canvas |
| Profile | Name, counts, sign out | Settings rows from the canvas |
| Inbox | Invitations and join requests | Activity feed (step 8) |
| Record payment, tap-to-settle, void | Built | Checked in the demo only |
| Record payout | Built, with the shortfall | Checked in the demo only |
| Members management | Built (board AM-1a/1b: sheets) | Checked in the demo only |
| Invites, join, approve | Built (boards AI-1a/1b, AF-Join-Invite, AF-Approve-Join) | Universal links; checked in the demo only |
| Activity log | Built (AL-1 feed with AL-2 before → after; ••• menu; members see their own) | Activity in the Inbox feed |
| Edit kameti, draft screen, Notes | Built: drafts reopen in the wizard; Notes tab (A2-Notes-Tab, swipe actions); edit a running kameti (AE-1, ••• menu) | Notes on payment and payout screens |
| Offline and error states | Basic messages | Canvas design |
| Dark mode | Colours switch | No screen checked against the dark artboards |
| Android | Not started | Later |

## Order of work

1. **Design alignment pass** on what exists: Members, Schedule and Payments tabs, member view, Profile, Sign-in, Home empty state.
2. **Record payment and void a payment.**
3. **Tap-to-settle** (bulk).
4. **Record payout**, including the shortfall.
5. **Members management**: add, edit, remove.
6. **Invites and joining**: owner send/resend/revoke/approve, join screen, Home invitations, Inbox. Needs the backend `feature/invites` migration applied first (a decision for the owner).
7. **Edit kameti, reopen a draft, Notes tab.**
8. **Activity log.**
9. **Profile and settings** (Profile v2 artboard).
10. **Dark mode, offline and error states, accessibility.**
11. **Release preparation**: remove sample data from release builds, real-device test, Apple and Google configuration, PR to `develop`.
12. **Android.**

## Working rules

- Build screens to the canvas artboards; propose design options on the canvas first when a screen is unclear.
- After a change: build and launch on the iPhone 18 Pro Max simulator; the owner tests the app. Run the package tests when logic changes.
- One commit per finished feature; ask before pushing.
