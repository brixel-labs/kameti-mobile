# Android port: status and handover

Read this first when picking up the Android port in a new session. Update it at the end of every phase (and whenever the state below changes).

**Last updated:** 2026-11-15, after the remind sheet rework (kameti-mobile#46) and the first Play Console internal-test build (see "First Play release" below).

## Where things stand

- **All 12 phases are done and merged into `develop`** (kameti-mobile#39 with the whole Android app and the reminder time; #40 with guest members, the setup card and delete a draft; #42 with the guest view link, quick send and the aligned guest UI; #43 and #44 with the Cloudflare site fixes). The git repo is `kameti-mobile`, not the parent `kameti` folder. What is left is the owner's release setup (see "Waiting on the owner") and the owner's testing.
- **Last verified (2026-11-14):** `./gradlew test :app:assembleDebug :app:lintDebug` succeeds, 258 unit tests pass, the demo build starts on the Pixel 10 Pro emulator without crashing. `./gradlew :app:assembleRelease` (shrunk with R8) also builds, and that build, signed with the debug key, starts on the emulator without crashing; nothing beyond its first screen was exercised. The screens have not been checked visually by Claude; the owner tests them.
- **Android app config:** the owner's local copy points at **prod** (`android/app/src/main/assets/KametiConfig.json`, gitignored) with `android/app/google-services.json` in place. Switch with `android/scripts/use-env.sh prod|dev|demo` run from `kameti-mobile`, then rebuild. Google sign-in on Android is set up (the Android OAuth client and the Firebase app exist for the debug key); Apple sign-in was removed from Android on purpose.
- **Backend:** every migration is applied to kameti-prod: the reminder time (#22), guest members and delete a draft (#23), and the guest view links with their 12-character tokens (#24).

## Phases

| # | Phase | State |
|---|---|---|
| 1 | Scaffold: Gradle modules, convention plugins, token generator, strings importer, env script | Done |
| 2 | `:core`, `:domain`, `:testsupport` with the ported tests | Done |
| 3 | Design system: every `K*` component in Compose, `KIcons`, failure messages | Done |
| 4 | Data layer (supabase-kt), sign-in, tabs and router, demo flavor | Done |
| 5 | Home: cards, members sheet, invitations, join code, archived list, Record payment sheet | Done |
| 6 | Kameti detail (read): Overview, Members, Schedule, Payments, member view | Done |
| 7 | Recording: payments, void, tap-to-settle, payouts with shortfall, reminders | Done |
| 8 | Create wizard: six steps, slot split sheet, reorder, reopening a draft | Done |
| 9 | Members and invites, Inbox: edit member, app access, share transfer, Invite all, join screen, approve sheet | Done |
| 10 | Notes, activity, edit, archive, restore, duplicate, edit setup | Done |
| 11 | Profile: name, appearance, app icon, notification settings, my people, sign-in methods, past kametis, delete account | Done |
| 12 | Push, live updates, invite links, offline states, release preparation, CI | Done |

The same table is in `docs/ROADMAP.md` ("Android port"); keep both in step.

## Left open by finished phases

These are deliberate gaps, each owned by a later phase:

- **Phase 7 (done), differences from iOS:** the floating Record payment button opens a short sheet of actions, not a menu; the method in the "Received … by …" bar opens a short sheet, not a menu; a WhatsApp reminder falls back to the system share sheet when WhatsApp can't open the link; names skipped by a reminder are joined with commas.
- **Phase 9 (done), differences from iOS:** in Invite all, a row turns green and says "Invite sent" but stays in the list (iOS fades each row out); iOS's `AddMemberSheet` is not ported, because members are only added while a kameti is a draft and a draft opens the wizard, so the sheet can't be reached; the app-icon badge that follows the Inbox count belongs to phase 12 (push).
- **Phase 10 (done), differences from iOS:** the ••• menu opens a short sheet of actions, not a menu; the note composer's "@ Kameti" chooser is a sheet; the Notes search button sits on the filter row inside the tab (iOS puts it in the navigation bar); note text can't be selected for copying; after archiving or restoring, Home shows the change on its next reload.
- **Sentences built in logic** (activity rows, note labels, the duplicate name) take a `Strings` lookup (`kametidetail/Strings.kt`); tests pass `english`, which reads `strings.xml`, so they check whole sentences like the iOS tests.
- **Phase 11 (done), differences from iOS:** My people and Notifications are routes (`Route.MyPeople`, `Route.NotificationSettings`, Android only); the app icon changes by enabling one of four launcher entries (`activity-alias` in the manifest, `app/LauncherIcons.kt`), which the launcher shows after a moment and with no system alert; wording that says "iPhone" on iOS has Android versions in `shell/res/values/strings_android.xml`.
- **Phase 12 (done):**
  - *Live updates:* the shell starts `dependencies.live` after sign-in and stops it on sign-out; changes go through `KLiveUpdates`, which reloads Home, the Inbox and an open kameti. Coming back to the app after it was in the background reloads everything.
  - *Invite links:* `https://kameti.fhbtechservices.com/join/<token>` (verified App Link) and the old `fhbtechservices.com/kameti/join/<token>` links (not verified: Android may ask which app opens them) open the join screen. `legal-site/.well-known/assetlinks.json` lists the **debug** signing fingerprint only; the website has to be deployed for it to count.
  - *Push:* Firebase Messaging in `:app` (`Push.kt`, `KametiMessagingService`), `PushCenter` in `:feature:shell`. The phone's token is saved for the signed-in account and removed on sign-out; a tapped notification opens its kameti or the Inbox; the "Know when it matters" sheet asks once after sign-in, after the name prompt. Without `app/google-services.json` the app builds and runs, with no push. Android has no app-icon count like iOS; the launcher shows its own dot when a notification is waiting.
  - *Offline:* `KConnectivity` and the offline banners were already in each screen from earlier phases; nothing new was needed.
  - *Launcher icons:* adaptive (a flat colour behind the iOS art, `res/mipmap-anydpi-v26`, `res/values/launcher_colors.xml`), one per icon choice. No themed (monochrome) layer yet.
  - *Release build:* R8 shrinking is on; sample data is a debug-only dependency (`app/src/debug/DemoBackend.kt` has it, `app/src/release/DemoBackend.kt` returns nothing), so a release build cannot run the demo; signing reads `android/keystore.properties` (git-ignored: `storeFile`, `storePassword`, `keyAlias`, `keyPassword`) and without it the release APK is unsigned.
  - *CI:* `.github/workflows/ci.yml` has an `android` job on Linux (unit tests, lint, debug build with the demo config) beside the iOS job. It runs on pushes to `develop` and `main`, so it has not run yet.
- **Launching from adb still uses** `am start -n com.brixel.kameti/.MainActivity`: the launcher entries are aliases, but the activity is exported.
- **Phase 8 (done), differences from iOS:** the wizard's top bar and footer are its own (a close or back arrow, then Previous and the primary button); the tab bar is hidden while it is open, as on iOS; the system Back button steps back a step. The keyboard has no previous/next bar. As on iOS, the overdue-reminder and owner-summary switches and "Email invites now" are shown but not saved.
- `ui/res/drawable/k_apple_logo.xml` was drawn by hand; the owner should check it looks right.
- One difference from iOS: the member's schedule opens as a full-height sheet, not a pushed page.

## How to build and hand over

```bash
cd kameti-mobile/android
export JAVA_HOME=$(/usr/libexec/java_home -v 21)     # the default JDK is 26; the build needs 21
./gradlew test :app:assembleDebug :app:lintDebug
adb -s emulator-5554 install -r app/build/outputs/apk/debug/app-debug.apk
adb -s emulator-5554 shell am force-stop com.brixel.kameti
adb -s emulator-5554 shell am start -n com.brixel.kameti/.MainActivity
adb -s emulator-5554 logcat -d -s AndroidRuntime:E   # check only that it did not crash
```

- Emulator: AVD `Pixel_10_Pro` (shows up as `emulator-5554`).
- Debug only: add `--ez gallery true` to the `am start` line to open the design-system gallery.
- After changing an iOS String Catalog: `python3 android/scripts/import-strings.py`. After changing tokens: `python3 design-tokens/generate.py`.

## How each phase is done

1. Read the iOS sources for the feature in `ios/KametiKit/Sources/Feature*` and port them module for module, following `.claude/rules/android-architecture.md`, `design-system.md` and `money-and-ledger.md`.
2. Every iOS test file gets a Kotlin twin with the same cases.
3. Strings come from the generated `strings.xml` (names are the module prefix plus the snake_case sentence, such as `detail_*`, `home_*`); Android-only wording goes in the module's hand-written `strings_android.xml` as `<prefix>_android_*`.
4. Feature code uses only `K*` components and tokens, never raw Material. Features never depend on `:data`. Writes go only through Postgres RPCs (`data/RpcParams.kt` already has the params for every RPC).
5. Finish with the build commands above, install and launch on the emulator, mark the phase Done here and in `docs/ROADMAP.md`, and report what is in and what is left out.

## The owner's working rules

- Do not commit, push, open or merge a PR, or tag unless the owner asks in that conversation. No git worktrees: branch off `develop` in the main checkout.
- Do not drive or test the running app. Build, install, launch, check for a crash, and hand over; the owner tests.
- Keep runs lean: no per-tweak commits or extra test runs beyond the build and launch.
- Supabase has one project, `kameti-prod` (no staging). Never `supabase db push` or change prod settings without the owner's approval for that action. Never fetch or print the service-role key.
- Never commit `KametiConfig.json`, `google-services.json`, `GoogleService-Info.plist`, keystores, the reference spreadsheet PDF or member contact details.

## Decisions already approved (2026-11-14)

- **No Sign in with Apple on Android** (the owner changed this on 2026-11-14, after the port: the button, the web sign-in and its `login-callback` link were removed). Google sign-in is native (Credential Manager). An account made with Apple on iOS can't sign in on Android; Profile still names Apple as the sign-in method for such an account.
- System font (Roboto), not bundled Inter.
- App icon picker included (alternate launcher entries).
- minSdk 26, compileSdk and targetSdk 37, application ID `com.brixel.kameti`.
- Record payment on Home is a bottom sheet, not a menu.

## Waiting on the owner

- **Done:** the Android OAuth client in Google Cloud and the Firebase Android app (both for the debug SHA-1 `46:AE:62:40:60:E6:68:3F:60:FB:3A:BA:CD:69:4D:D3:96:3C:7B:11`).
- **Push test:** a real push to an Android phone has not been tried. The backend already accepts `android` tokens (`register_device`, `send-push` through FCM).
- **Release key:** **created 2026-11-15** (`~/.android/kameti-upload.jks`, details in the git-ignored `android/keystore.properties`; the owner must back both up). Still to do after Play enrolls the app: add Play's app-signing SHA-1 (Play Console, App integrity) to the Google OAuth client and to the Firebase app, or Google sign-in fails in the store build.
- **Website:** add the release SHA-256 fingerprint (from Play Console → App signing) to `legal-site/.well-known/assetlinks.json` and deploy the site, so invite links open the store build without asking.
- **Not tried:** the iOS build on the physical iPhone 17 Pro Max (it was locked), and the first run of the Android CI job (it runs on the next push to `develop`).

## First Play release (2026-11-15)

Full details and the next steps are in `docs/ANDROID_RELEASE_HANDOFF.md`. In short:

- A signed release bundle exists: **versionCode 2, versionName 1.0**, prod config, signed with the new upload key (SHA-1 `89:A2:44:D1:99:8C:A7:96:76:C7:14:DE:40:CA:24:27:28:5C:7F:BA`). Build it with `cd android && export JAVA_HOME=$(/usr/libexec/java_home -v 21) && ./gradlew :app:bundleRelease`; the result is `android/app/build/outputs/bundle/release/app-release.aab`. versionCode only ever goes up: the next upload needs 3.
- **Not confirmed:** whether the owner has uploaded it to Play Console (Internal testing). Claude in Chrome was never connected, and the built-in browser was signed in to the wrong Google account, so the owner does the Play Console steps by hand.
- Store listing assets and texts, the data safety answers and the privacy page update were prepared (see the handoff). The privacy page is merged (kameti-mobile#47) but **not deployed** (the site is a Cloudflare Worker deployed by hand).
- An Android layout fix went in the same PR (#47): the big pot amount on Home and Overview used to wrap and show only "Rs" for long amounts (`ui/.../KMoney.kt`, `PotHeadline`); it now stacks under the amount like iOS.

## Technical notes worth keeping

- Versions: AGP 9.5.1, Kotlin 2.4.21, supabase-kt 3.9.0 (BOM), Ktor 3.6.0 (okhttp engine), androidx.credentials 1.6.0, googleid 1.2.1. Catalog: `android/gradle/libs.versions.toml`.
- Modules: `:core`, `:domain`, `:navigation` (pure Kotlin), `:testsupport`, `:ui`, `:data`, `:feature:{auth,home,kametidetail,createkameti,invites,shell}`, `:app`.
- State: one `ViewModel` per screen with a `StateFlow` UI state; a public suspend `load()` for tests plus `refresh()` / `onX()` that launch in `viewModelScope`. Repositories throw only `Failure`.
- Navigation: `Route` and `AppRouter` in `:navigation`; the shell gives each stack entry its own saved state and `ViewModelStore` (`feature/shell/RouteEntries.kt`), so a screen creates its model with `viewModel { … }`. Home's model is shared across the tab (`viewModel(key = "home-$userId")`).
- Dates: a calendar day or month is `LocalDate`, a moment is `Instant`; "now" always comes from `KametiClock`.
- supabase-kt details checked against the 3.9.0 sources: an order clause is sent as `created_at.desc.nullslast`; the client builder strips the URL scheme, so `:data` sets `useHTTPS` from the URL; in the dev config `127.0.0.1` / `localhost` is mapped to `10.0.2.2` for the emulator (`app/AppConfig.kt`).

## Changes after phase 12 (2026-11-14), made on both platforms

- **Slot sheet closes after Save slot** (Android only; iOS was fine): the sheet refused to close while the save was still reloading, so it now closes once the write is done (`StepSlots.kt`).
- **Reminder time is editable**, on iOS and Android: step 2 of the wizard (the "At" row opens a list of hours) and Edit kameti (a "Reminder time" row). Whole hours from 6:00 AM to 10:00 PM, Pakistan time (`ReminderTime` in `KametiCore` / `:core`; the shared list is `KReminderTimeList` in `KametiUI` / `:ui`). `Kameti.reminderHour` defaults to 10 when the backend sends none; the activity log shows "Reminder time: 10:00 AM → 6:00 PM".
- **Needs a backend migration:** `kameti-backend/supabase/migrations/20261114120000_reminder_hour.sql` (branch `feature/reminder-time`, tests in `supabase/tests/140_reminder_hour.test.sql`). It was applied to **kameti-prod on 2026-11-14** with `supabase db push` (the owner approved it); the 3 kametis there keep 10:00. The apps leave `p_reminder_hour` out of a call when it is 10 or unchanged, so they also work against a backend that hasn't got it. The branch is not committed or merged.
- **After Start, the kameti opens on its Members tab** (new `Route.KametiMembers`), so the owner can send invites at once; both platforms.
- **Sign in with Apple removed from Android** (see Decisions above).

## Guest members, the guest page and quick send (2026-11-14 and 2026-11-15), on both platforms

A guest is a member the owner marked as not using the app (`members.no_app`). Everything below is on iOS and Android, built together.

- **Setup card and counts:** while anyone hasn't joined, the owner's Overview shows a warning card ("Waiting for Ali to join" / "3 of 9 haven't joined yet"); it opens the Members tab. Home's owner card says "3 people haven't joined yet", and the Members tab has a count pill ("Members 3"). Guests never count as waiting and are left out of Invite all. Recording is never hidden or blocked: payments don't depend on anyone having the app.
- **Marking a guest:** "Mark as guest" on the member sheet (only for a member who isn't invited or has declined). The card shows a "Guest mode" tag; the Members row shows a "Guest" pill. "Invite to the app" puts them back. A guest's row reads like every other row (see Members rows).
- **App access card (member sheet):** for a guest it is a list: **Share view-only link** (makes the guest's link if there is none, then opens the share sheet, which also copies it), **Invite to the app**. The tapped row's chevron turns into a spinner while it works. A guest has one link for good: the apps have no "turn off"; the backend `turn_off_member_view_link` is kept but unused.
- **Quick send:** the Overview has a **Guests card** (the two guests who owe most first, then "Show all N guests"; each with name, "Owes / Ahead by / All paid up" and a tonal **Share update** capsule), and a guest's row in Members has a plain **Share update** text link on its third line (forward-arrow icon). Both make the guest's link if needed, then open WhatsApp with the update, or the share sheet without a phone number. Links the owner already made are read when the screen loads, never created by it.
- **What is sent** (`GuestUpdate`): a short text of only that guest's own figures (this month, owes or ahead, their payout turn) plus "See everything any time: <link>". The card copy is generic ("doesn't use the app… share by message, email or any app"); only the receipt sheet's "WhatsApp" button and the Remind sheet still say WhatsApp. After a payment for a guest, the "Send a receipt?" sheet offers it (one at a time, or several with tap-to-settle).
- **Members rows:** a sentence with the name in bold: "**You** have 2 slots" on the owner's own row, "**Ata Rabbi** has 1 slot" on the others ("has no slot yet" with none), the monthly amount under it, and the owes/settled chip plus the join status (or the Guest pill) pinned to the bottom of the row so a long name has the width.
- **The guest page:** `https://kameti.fhbtechservices.com/v/<token>`, `legal-site/v/index.html`. Responsive, light and dark; on phones an iOS-style floating glass pill (Overview, Payments, Schedule), a top nav from 720px. It calls the public RPC `get_guest_view` with the publishable key and shows only that guest's own figures, the payout schedule and a paid count for the month, never other members' amounts. There is no owner phone number on it, so corrections say "tell <owner>". An unknown or removed token shows "This link isn't working".
- **Links:** new links are 12 characters (A-Z a-z 0-9 - _, 72 bits); the first links made were 64 characters and still work. One link per guest (`member_view_links`, owner-readable only; the apps read it with a select and create it with `member_view_link`).
- **Hosting:** `kameti-site` is a **Cloudflare Worker with static assets**, not Pages and **not connected to git**: merging to `develop` does not deploy it. Deploy by hand with `cd legal-site && npx wrangler deploy` (needs `npx wrangler login` once). `legal-site/wrangler.jsonc` sets `html_handling: drop-trailing-slash`; `_redirects` rewrites `/join/*` and `/v/*` to `/join` and `/v` (a rewrite to `index.html` is rejected as a loop); `_headers` sets the `.well-known` content types and noindex/no-referrer. `vercel.json` is gone.
- **Backend:** `20261114180000_member_no_app.sql`, `20261115100000_member_view_links.sql` and `20261115140000_short_view_link_tokens.sql`, with tests `150` and `170`; all applied to kameti-prod. Local note: the demo data used to try the page on the local database can make backend tests 120 and 130 fail on a duplicate user until `supabase db reset`.

### Aligned on both platforms at the same time

- **Shapes and icons:** buttons are capsules, fields are rounded rectangles (multi-line too). The forward share arrow, the broken link, the person-plus and the transfer arrows are the same drawn icons on both (iOS asset catalog `kLinkOff` / `kUserPlus` and SF arrows; Android vectors in `KIcons`). The back and close arrows are plain 30dp icons.
- **Sheets:** a full-page sheet on Android keeps a fixed 93% height from its first frame (the dimmed gap above it), and closing after a save no longer gets vetoed by the busy lock (the record-payment sheet dismisses). Invite all's rows fade out after their tick. Archiving a kameti goes back to Home, reloaded.
- **Text:** the member sheet is "Update member details"; sizes under names are 15pt (`subtitleLg`).

## Delete a draft (2026-11-14), on both platforms

- A draft kameti (not through the create wizard yet, or reopened with Edit setup) can be **deleted for good**: from the wizard's ••• menu once the draft exists, and by pressing and holding the draft's card on Home. A confirm sheet says it can't be undone. Nothing is recorded in a draft, so only the setup, the people added and any invites go. Anything running or finished is still archived, not deleted.
- **Needs a backend migration:** `kameti-backend` `20261114200000_delete_kameti_draft.sql` (`delete_kameti_draft`, owner only, drafts only; branch `feature/guest-members`, tests `160_delete_kameti_draft.test.sql`), applied to kameti-prod.
