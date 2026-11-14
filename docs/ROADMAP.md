# Native iOS roadmap

Status of the native SwiftUI app (`ios/`) against the original Flutter app (removed 2026-11-12) and the design canvas, and the order of work. Updated 2026-11-10.

Each step is done on its own branch cut from `feature/native-ios`, with one commit per finished feature and no push without asking.

## Done

- Foundation: package layers (Core, Domain, UI, Data, Navigation, TestSupport, features), design tokens, router, deep-link parsing.
- Sign-in with Apple and Google, session handling, glass tab bar (Home, Inbox, Profile).
- Data layer: every repository call exists (kametis, members, slots and shares, ledger views, payments and payouts, invites, activity, profile, contacts, auth). Only exercised against the demo store so far.
- Shared components: amount field, chips, stepper, bottom sheet, select field, checkbox, switch, underline tabs, reorderable list, avatar stack, tonal button.
- Create wizard, six steps, reworked to the canvas.
- Demo flavor with sample kametis (`ios/scripts/use-env.sh demo`).
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
| Profile | Built (v3b icon list): edit name, appearance cards, My people, sign-in methods, past kametis, support/privacy links, delete account | Website pages for support/privacy; archive so owners can delete |
| Inbox | Invitations and join requests | Activity feed (step 8) |
| Record payment, tap-to-settle, void | Built | Checked in the demo only |
| Record payout | Built, with the shortfall | Checked in the demo only |
| Members management | Built (board AM-1a/1b: sheets) | Checked in the demo only |
| Invites, join, approve | Built (boards AI-1a/1b, AF-Join-Invite, AF-Approve-Join) | Universal links; checked in the demo only |
| Activity log | Built (AL-1 feed with AL-2 before → after; ••• menu; members see their own) | Activity in the Inbox feed |
| Edit kameti, draft screen, Notes | Built: drafts reopen in the wizard; Notes tab (A2-Notes-Tab, swipe actions); edit a running kameti (AE-1, ••• menu) | Notes on payment and payout screens |
| Offline and error states | Built (AF-States): offline banner, writes blocked offline, skeletons, error and invite cards | Saved copy for opening the app offline |
| Dark mode | Checked: tokens match the dark artboards; two hard-coded colours fixed | — |
| Android | All 12 phases ported 2026-11-14; waiting on the owner's setup and testing. Started 2026-11-14: project, modules, tokens, strings, `:core`, `:domain`, sample data, design system, `:data`, sign-in, the tab shell, Home, the kameti detail and recording (payments, voids, payouts, reminders) | See "Android port" below |

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
10. **Dark mode, offline and error states.** (Accessibility pass dropped: not required for this app.)
11. **Release preparation**: remove sample data from release builds, real-device test, Apple and Google configuration, PR to `develop`.
12. **Android.**

## Working rules

- Build screens to the canvas artboards; propose design options on the canvas first when a screen is unclear.
- After a change: build and launch on the iPhone 18 Pro Max simulator; the owner tests the app. Run the package tests when logic changes.
- One commit per finished feature; ask before pushing.

## Android port

`android/` is a module-for-module port of the iOS app (Kotlin, Jetpack Compose, supabase-kt). One `feature/android-*` branch per phase.

| # | Phase | State |
|---|---|---|
| 1 | Scaffold: Gradle modules, convention plugins, token generator, strings importer, env script | Done |
| 2 | `:core`, `:domain`, `:testsupport` with the ported tests | Done |
| 3 | Design system: every `K*` component in Compose, `KIcons`, failure messages | Done |
| 4 | Data layer (supabase-kt), sign-in, tabs and router, demo flavor. Inbox, Profile and the pushed screens are stand-ins (`feature/shell/ComingNext.kt`) | Done |
| 5 | Home: owner, member and past cards, members sheet, invitations, join code, archived list, Record payment menu (as a sheet) | Done |
| 6 | Kameti detail (read): Overview, Members, Schedule, Payments, member view. No write controls yet | Done |
| 7 | Recording: record payment, void, tap-to-settle, payout with shortfall and dues taken from it, owner reminders (push and WhatsApp). The Record payment menu is a sheet | Done |
| 8 | Create wizard: six steps, slot split sheet, payout order, reopening a draft. The tab bar hides while it is open | Done |
| 9 | Members and invites, Inbox: edit member, app access, share transfer, Invite all, join screen, approve sheet | Done |
| 10 | Notes tab and member notes, activity log, edit kameti, edit setup, archive, restore, duplicate | Done |
| 11 | Profile: name, appearance, app icon (four launcher entries), notification settings, my people, sign-in methods, past kametis, delete account | Done |
| 12 | Push (Firebase), live updates, invite links (App Links), adaptive launcher icons, shrunk release build without sample data, optional release signing, Android CI job | Done |

Needs the owner: an Android OAuth client (Google Cloud, with the app's SHA-1), `com.brixel.kameti://login-callback` in Supabase's redirect URLs and an Apple Services ID on the Apple provider (Sign in with Apple opens in a browser tab on Android), the Android app in Firebase (`google-services.json`), and the release signing fingerprint for `assetlinks.json` on the website.
