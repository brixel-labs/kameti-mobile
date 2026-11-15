# Handoff: Kameti Android first Play release (written 2026-11-15)

For the next Claude session (any account) that picks this up. Read this file, then `docs/ANDROID_PORT_STATUS.md`, `CLAUDE.md` and `.claude/rules/git-workflow.md`. Nothing here contains a password or key; the secrets stay on the owner's Mac (see "Secrets").

## What you are continuing

Get the Android app (`com.brixel.kameti`) into **Google Play Console → Testing → Internal testing**, then finish what Play needs around it. The owner uploads in Play Console by hand: Claude in Chrome never connected in the last session, and the built-in browser was signed in to a different Google account from the one that owns the app. Do not ask for their Google password and do not try to type it. If Chrome is connected in your session, you can drive Play Console there instead (the owner is signed in in their own Chrome).

- Play Console app: https://play.google.com/console/u/0/developers/8237807643282076051/app/4973057694000999150/app-dashboard
- Repo: `kameti-mobile` (the git repo; the parent folder `kameti/` is not one). Backend is the sibling `kameti-backend`.

## State right now

**Git** (repo `kameti-mobile`): branch `feature/privacy-push-update`, cut from `develop` at `9795dbe` ("feat(reminders): one list on the remind sheet ... (#46)"). **Uncommitted** changes, three files, all the owner's to commit when they ask:

| File | Change |
|---|---|
| `legal-site/privacy/index.html` | Privacy page: notifications and device token, read-only guest links, Firebase Cloud Messaging, Cloudflare instead of Vercel, date 2026-11-15. **Not deployed** (the site is a Cloudflare Worker deployed by hand: `cd legal-site && npx wrangler deploy`, after `npx wrangler login` once). |
| `android/ui/src/main/kotlin/com/brixel/kameti/ui/components/KMoney.kt` | Bug fix: the big pot amount wrapped and showed only "Rs" when long (e.g. "Rs 10,00,000" beside "of Rs 15,00,000"). A `PotHeadline` layout now puts the two side by side when they fit and stacks them otherwise, like iOS. |
| `android/app/build.gradle.kts` | `versionCode` 1 to 2 (versionName stays 1.0). |

These are two different changes plus a version bump. When the owner says "commit and push", split them: a `fix(ds)` commit for KMoney (+ the versionCode bump as `build(release)`), and a `docs(legal)`/`feat(legal)` commit for the privacy page. Keep the privacy page on its own PR if they prefer. Also `docs/ANDROID_PORT_STATUS.md` and this file are new/edited and uncommitted.

Watch for noise: `xcodebuild` rewrites `ios/Kameti/Kameti.xcodeproj/project.xcproj` and the `Localizable.xcstrings` catalogs (reordering, "state" fields). That is not a real change: `git checkout --` those files before committing.

**Release build**
- Bundle: `kameti-1.0-2.aab` (versionCode 2, versionName 1.0, prod Supabase config, R8 shrunk), signed with the new upload key. Copies (durable, outside the repo): `~/Desktop/Hassan/Personal/kameti/play-release-2026-11-15/`. The original is `android/app/build/outputs/bundle/release/app-release.aab` (deleted by `./gradlew clean`). `kameti-1.0-1.aab` is the earlier build without the KMoney fix; ignore it.
- Rebuild: `cd android && export JAVA_HOME=$(/usr/libexec/java_home -v 21) && ./gradlew :app:bundleRelease` (JDK 21 required; the default is 26). **versionCode must only ever go up**: the next upload after 2 needs 3.
- Check the config first: `cmp env/prod.json android/app/src/main/assets/KametiConfig.json` must say identical (the owner's local config is prod). `android/scripts/use-env.sh prod|dev|demo` switches it; **always switch back to prod** before a release build. The last session left it on prod.
- Upload key: `~/.android/kameti-upload.jks`, alias `kameti-upload`, passwords in the git-ignored `android/keystore.properties` (never print it, never commit it). Created 2026-11-15, valid to 2054. Upload certificate fingerprints (public):
  - SHA-1 `89:A2:44:D1:99:8C:A7:96:76:C7:14:DE:40:CA:24:27:28:5C:7F:BA`
  - SHA-256 `13:44:C3:90:08:6E:42:51:F4:63:CD:C5:02:79:C2:76:26:3F:33:33:48:1C:60:7B:D8:08:61:06:43:37:6A:6E`
  - **The owner must back up the `.jks` and `keystore.properties`.** If they are lost, only a Play upload-key reset recovers it.

**Not confirmed:** whether the owner has uploaded `kameti-1.0-2.aab` (or `-1`) and whether a release was created in Internal testing. Ask them first. Also unknown: whether the app already had a different upload key registered in Play (if Play says the bundle is signed with the wrong key, find the original key; do not create another).

## Next steps, in order

1. **Upload to Internal testing** (owner, or you through their Chrome): Testing → Internal testing → Create new release → accept Play App Signing → upload `kameti-1.0-2.aab` → Save → review → start rollout. Then the Testers tab: an email list with the owner's address, copy the opt-in link, install on a phone.
2. **After Play enrolls the app**, go to App integrity → App signing and copy the SHA-1 and SHA-256 of the *app signing* key:
   - add the SHA-1 to the Google Cloud Android OAuth client and to the Firebase Android app (without it **Google sign-in fails in the store build**; debug SHA-1 is already there: `46:AE:62:40:60:E6:68:3F:60:FB:3A:BA:CD:69:4D:D3:96:3C:7B:11`);
   - add the SHA-256 to `legal-site/.well-known/assetlinks.json` (today it lists the debug fingerprint only) and deploy the site, so invite links open the store build.
3. **Deploy the privacy page** (`cd legal-site && npx wrangler deploy`) before the data safety form or store listing is submitted: Play compares the policy with the declarations.
4. **Finish the store listing and App content** (needed for production, and Play may ask for some of it before an internal release). Prepared material is below.
5. A real push to an Android phone has still not been tried; the Internal testing build is the first chance (Firebase `google-services.json` is in `android/app/`, git-ignored).

## Store listing material (drafted, owner to review)

- Privacy policy URL: `https://kameti.fhbtechservices.com/privacy` (check it loads). Account deletion URL: `https://kameti.fhbtechservices.com/delete-account` (in the app: Profile → Delete account).
- Short description (80 max): `Run your kameti: record payments, track turns, remind members.`
- Full description:

```
Kameti keeps your committee (kameti) organised and transparent, without spreadsheets or group-chat arguments.

If you run a rotating savings group, Kameti is where you record who has paid, whose turn it is and what is still due. Everyone in the group sees the same numbers.

For the person running the kameti
• Set up a kameti in a few steps: monthly amount, number of months, due date and each member's slots.
• Split a slot between people by amount.
• Record payments and payouts, including part payments, advances and credit.
• See at a glance who has paid, who has part paid and who is overdue.
• Remind members who owe with a notification, or on WhatsApp for people without the app.
• Share a read-only update link with members who don't use the app.
• Keep notes and a full activity history.

For members
• Join with an invite link or code.
• See what you owe, what you've paid and when your turn comes.
• Get a reminder before the due date.

Important: Kameti is a record-keeping app. No money moves through it. Payments are made outside the app, and the owner records them.
```

- Graphics (in the durable folder above): `kameti-play-icon-512.png` (512x512), `kameti-feature-graphic-1024x500.png`, `kameti-phone-1-home.png` and `kameti-phone-2-overview.png` (1080x1920, built from the app's **demo-flavor sample data**, so no real member names). Still missing: a category and contact email in the listing; Play wants at least 2 phone screenshots (done) and may want more for a good listing.
- **Data safety draft** (based on the Android app's real permissions, INTERNET and POST_NOTIFICATIONS, and no ads/analytics/crash SDK; only Firebase Messaging): collects data: yes; encrypted in transit: yes; users can request deletion: yes; nothing shared with third parties (Supabase, Resend and Firebase act as service providers). Collected, for app functionality and account management only: name, email address, phone number (optional, entered by an owner for a member), other financial info (recorded payments and payouts; no card or bank details), other user-generated content (notes), device or other IDs (push token). Not collected: location, contacts, photos, files, messages, health, audio, web browsing, app info and performance.
- Likely other App content questions (not yet answered, owner to confirm): app access (sign-in with Google is required, so Play will want test access: a tester with a Google account, or instructions), no ads, content rating questionnaire, target audience (not for children under 13, per the privacy policy), a financial features declaration (the app records savings-group payments but moves no money).

## Things worth flagging

- `env/prod.json` has `INVITE_BASE_URL` = `https://www.fhbtechservices.com/kameti/join` (the old invite host). The port notes say links are now `https://kameti.fhbtechservices.com/join/<token>` and the old ones still work. Not changed; check whether the app should use the new host.
- The status doc's "Waiting on the owner" still lists the owner-side tasks: push test on a real Android phone, deploy the website, iOS on a physical iPhone, and the first CI run (it runs on the next push to `develop`).
- iOS and Android stay in step: anything changed on one side needs the matching change on the other (the remind sheet rework in #46 was done on both).

## What the last session did (for context)

- **Remind sheet (iOS and Android), merged as PR #46:** one list of everyone who owes (avatar, name, "Owes Rs X" in orange, and a Notify or WhatsApp button), a total in the subtitle, a footnote "Members with the app get a notification instead.", the WhatsApp icon (new `kWhatsApp` outline), the message now starts "Assalam O Alaikum", and the overview Remind button no longer counts the owner. The full-height sheet was kept.
- **A bottom tab bar experiment was reverted:** a separate Record button next to the native tab bar was tried with several approaches and removed at the owner's request. Nothing from it is in the code.
- **Release prep:** the upload key, the signed bundle (versionCode 2), the store graphics, the data safety draft and the privacy page edit described above.

## The owner's working rules (from memory and `docs/ANDROID_PORT_STATUS.md`)

- Do not commit, push, open or merge a PR, or tag unless the owner asks in that conversation. "Commit and push" from them means the whole cycle: commit, push, PR into `develop`, squash-merge, sync local `develop` (`git merge --ff-only origin/develop`). Use `GH_TOKEN=$(gh auth token --user hassan31)` for git and gh on this org's repos; do not switch the active gh account.
- No git worktrees: branch off `develop` in the main checkout, `feature/<slug>`.
- Do not drive or test the running app; build, install, launch, hand over. (The last session made three emulator taps only to capture store screenshots from the demo flavor.) After an iOS change: build and run on the two **iOS 27.0** simulators only (not the device): iPhone 18 Pro `0BC1155A-6449-40C5-890F-9B04FDE62AF8`, iPhone 18 Pro Max `984FECDF-0E66-43BC-B6B2-E185A673C2D1`. There are same-named iOS 27.2 simulators; the owner does not watch those. Terminate the app before installing a new build or it keeps running the old one.
- Android: emulator `Pixel_10_Pro` (`emulator-5554`), `adb install -r`, then `am force-stop` and `am start -n com.brixel.kameti/.MainActivity`; only check it did not crash.
- Never run `supabase db push` or change prod settings unasked; Supabase has one project, `kameti-prod`, no staging. Never commit `KametiConfig.json`, `google-services.json`, keystores or member contact details.
- Whole cards are tappable; selectors and pickers are tappable as a whole; new design versions go on new artboards.

## Secrets: where they live (values deliberately not in this file)

- Upload keystore and its passwords: `~/.android/kameti-upload.jks` and `android/keystore.properties` (git-ignored).
- Supabase config and client IDs: `env/prod.json` (git-ignored) copied into the apps' config files by the `use-env.sh` scripts.
- Firebase: `android/app/google-services.json` and `ios/Kameti/Kameti/GoogleService-Info.plist` (git-ignored).
