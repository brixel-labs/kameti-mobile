# Android port: status and handover

Read this first when picking up the Android port in a new session. Update it at the end of every phase (and whenever the state below changes).

**Last updated:** 2026-11-14, end of phase 10.

## Where things stand

- **Phases 1–10 are done. Next: phase 11.** Start a phase only when the owner says "Continue phase N".
- **Phases 1–10 are committed** on branch `feature/android-scaffold` in `kameti-mobile` (the git repo is `kameti-mobile`, not the parent `kameti` folder): phases 1–7 in `f7c60a0`, phases 8–10 in the commit after it. Nothing is pushed and there is no pull request.
- **Last verified (2026-11-14):** `./gradlew test :app:assembleDebug :app:lintDebug` succeeds, 227 unit tests pass, the demo build starts on the Pixel 10 Pro emulator without crashing. The screens have not been checked visually by Claude; the owner tests them.
- **Android app config is `demo`** (`android/app/src/main/assets/KametiConfig.json`, gitignored). Switch with `android/scripts/use-env.sh prod|dev|demo` run from `kameti-mobile`, then rebuild. The iOS config is untouched.
- **Sign-in on prod does not work on Android yet** (see "Waiting on the owner"). Until then the tabs are reachable only in demo, or dev against a local Supabase.

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
| 11 | Profile | Next |
| 12 | Push, live updates, invite links, offline states, release preparation, CI | — |

The same table is in `docs/ROADMAP.md` ("Android port"); keep both in step.

## Left open by finished phases

These are deliberate gaps, each owned by a later phase:

- **Phase 7 (done), differences from iOS:** the floating Record payment button opens a short sheet of actions, not a menu; the method in the "Received … by …" bar opens a short sheet, not a menu; a WhatsApp reminder falls back to the system share sheet when WhatsApp can't open the link; names skipped by a reminder are joined with commas.
- **Phase 9 (done), differences from iOS:** in Invite all, a row turns green and says "Invite sent" but stays in the list (iOS fades each row out); iOS's `AddMemberSheet` is not ported, because members are only added while a kameti is a draft and a draft opens the wizard, so the sheet can't be reached; the app-icon badge that follows the Inbox count belongs to phase 12 (push).
- **Phase 10 (done), differences from iOS:** the ••• menu opens a short sheet of actions, not a menu; the note composer's "@ Kameti" chooser is a sheet; the Notes search button sits on the filter row inside the tab (iOS puts it in the navigation bar); note text can't be selected for copying; after archiving or restoring, Home shows the change on its next reload.
- **Sentences built in logic** (activity rows, note labels, the duplicate name) take a `Strings` lookup (`kametidetail/Strings.kt`); tests pass `english`, which reads `strings.xml`, so they check whole sentences like the iOS tests.
- **Phase 11:** Profile tab is a stand-in with a working Sign out (`ProfileComingNext`).
- **Phase 12:** `data/SupabaseLiveUpdates.kt` is written but not wired into any screen.
- **Phase 8 (done), differences from iOS:** the wizard's top bar and footer are its own (a close or back arrow, then Previous and the primary button); the tab bar is hidden while it is open, as on iOS; the system Back button steps back a step. The keyboard has no previous/next bar. As on iOS, the overdue-reminder and owner-summary switches and "Email invites now" are shown but not saved.
- The past kametis route (from Profile) shows `ComingNext` until phase 11.
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

- Sign in with Apple on Android through Supabase web OAuth in a browser tab, returning via `com.brixel.kameti://login-callback`. Google sign-in is native (Credential Manager).
- System font (Roboto), not bundled Inter.
- App icon picker included (alternate launcher entries).
- minSdk 26, compileSdk and targetSdk 37, application ID `com.brixel.kameti`.
- Record payment on Home is a bottom sheet, not a menu.

## Waiting on the owner

- **Google Cloud:** an Android OAuth client for package `com.brixel.kameti` with the debug SHA-1 `46:AE:62:40:60:E6:68:3F:60:FB:3A:BA:CD:69:4D:D3:96:3C:7B:11` (and later the release one).
- **Supabase:** add `com.brixel.kameti://login-callback` to the redirect URLs, and an Apple Services ID on the Apple provider.
- **Firebase:** add the Android app and supply `google-services.json` (phase 12, push).
- **Website:** the release signing fingerprint for `assetlinks.json` (phase 12, invite links).

## Technical notes worth keeping

- Versions: AGP 9.5.1, Kotlin 2.4.21, supabase-kt 3.9.0 (BOM), Ktor 3.6.0 (okhttp engine), androidx.credentials 1.6.0, googleid 1.2.1. Catalog: `android/gradle/libs.versions.toml`.
- Modules: `:core`, `:domain`, `:navigation` (pure Kotlin), `:testsupport`, `:ui`, `:data`, `:feature:{auth,home,kametidetail,createkameti,invites,shell}`, `:app`.
- State: one `ViewModel` per screen with a `StateFlow` UI state; a public suspend `load()` for tests plus `refresh()` / `onX()` that launch in `viewModelScope`. Repositories throw only `Failure`.
- Navigation: `Route` and `AppRouter` in `:navigation`; the shell gives each stack entry its own saved state and `ViewModelStore` (`feature/shell/RouteEntries.kt`), so a screen creates its model with `viewModel { … }`. Home's model is shared across the tab (`viewModel(key = "home-$userId")`).
- Dates: a calendar day or month is `LocalDate`, a moment is `Instant`; "now" always comes from `KametiClock`.
- supabase-kt details checked against the 3.9.0 sources: an order clause is sent as `created_at.desc.nullslast`; the client builder strips the URL scheme, so `:data` sets `useHTTPS` from the URL; in the dev config `127.0.0.1` / `localhost` is mapped to `10.0.2.2` for the emulator (`app/AppConfig.kt`).
