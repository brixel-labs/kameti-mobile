# Handoff: Kameti iOS App Store Connect listing (written 2026-11-15)

For the next session. Read with `docs/ANDROID_RELEASE_HANDOFF.md` (the Play side) and `CLAUDE.md`. Nothing here contains a password; the reviewer password is in the owner's password manager.

## State right now

- App Store Connect app: **Kameti**, Apple ID `6832690829`, iOS App Version **1.0**, status **Prepare for Submission**, build **1** already attached. Page: https://appstoreconnect.apple.com/apps/6832690829/distribution/ios/version/inflight
- **Not saved and not submitted.** The page's **Save** is blocked until the App Review contact has a first name, last name and phone number (with a `+` country code). The owner said they will enter those themselves. They also type the reviewer username and password.
- The owner's Apple account is signed in in **Claude in Chrome** (the built-in browser was signed in earlier too, but it cannot attach files; Chrome can, with `file_upload`).
- Page edits in Chrome were left as draft edits in the open tab. If the tab was closed, redo them from the lists below.

## What is on the page (Chrome tab)

| Area | Value |
|---|---|
| Header | `header-3840x1646.png` (1 of 1) |
| Search Results | `search-results-3840x2560.png` (1 of 1; 1920x1280 copy also exists) |
| Screenshots | six captioned screenshots, 1206x2622, under "iPhone with Dynamic Island (medium display)" (6 of 10) |
| App preview | `kameti-app-preview-29s-886x1920.mp4` (1 of 3). The poster frame was still a placeholder when last checked: confirm Apple finished processing it |
| Promotional text | "Run your kameti with confidence. Record every payment, see whose turn is next and keep the whole group on the same page." |
| Description | the Play description (organised, no spreadsheets; owner and member sections; "No money moves through it") |
| Keywords | `kameti,committee,savings group,payment tracker,ledger,rotating savings,turns,reminders,members` (limit is 100; the first draft was 101 and was trimmed) |
| Support / Marketing URL | `https://kameti.fhbtechservices.com/support` / `https://kameti.fhbtechservices.com` |
| Copyright | `2026 Brixel Labs Inc.` |
| App Review: Sign-in required | ticked; username/password **left for the owner** (test account `kameti.reviewer@gmail.com`, Google sign-in) |
| App Review: contact email | `contact@fhbtechservices.com`; first name, last name, phone **left for the owner** |
| App Review: notes | detailed notes (what the app is, how to sign in, what the reviewer will see, members and invites, permissions and data, attachment). No password in them |
| App Review: attachment | `kameti-walkthrough-60s-1206x2622.mp4` (55 s, about 3 MB) |
| Release | "Automatically release this version" is selected (set earlier by the owner or by default: check it is what they want) |

**Not touched:** iPad and Apple Watch screenshot sets, App Privacy answers, age rating, pricing and availability, "Sign in with Apple" review notes beyond the text above. Check each before "Add for Review".

## Remaining sections filled later on 2026-11-15 (by Claude, in Chrome)

- **App Privacy:** privacy policy URL `https://kameti.fhbtechservices.com/privacy`. Seven data types, each **collected, linked to the user's identity, used only for App Functionality, not used for tracking**: Name, Email Address, Phone Number, User ID, Device ID, Other Financial Info, Other User Content. **Not published yet**: the Publish button on the App Privacy page is enabled and is the owner's call (it must be published before Add for Review).
- **App Information:** subtitle `Run your kameti, track turns`; primary category **Productivity** (matches Play); Content Rights: "No, it does not contain, show, or access third-party content"; **age rating questionnaire** all No / None, calculated **4+** (172 countries 4+, Brazil L, Korea ALL, Vietnam 000+ style regional values), saved.
- **Pricing and Availability:** price schedule **Free ($0.00, base country USA)**, availability **all 175 countries or regions** ("Available on App Release"; this includes Pakistan). Tax category is App Store software.
- iPad and Apple Watch screenshots: not needed (the owner said so).
- Not done: **Publish** of App Privacy, the review contact name/phone, the reviewer username/password, **Add for Review**, "Digital Services Act" trader details (the page says the developer is already identified as a trader: check the contact details shown there), export compliance (encryption) answers when the build is submitted, and the App Accessibility page.

## The assets (all in `appstore-assets-2026-11-15/`, next to the repo, not inside it)

- `screenshots/ios-1..6`: raw captures from the **iPhone 18 Pro, iOS 27.2** simulator (UDID `78CF5CC5-0562-428E-AA3D-B8A57A645330`), which gives exactly **1206x2622**. The iPhone 18 Pro **Max** is 1320x2868 (not a listed size for the 6.1/6.3 set).
- `screenshots-captioned/captioned-1..6`: the same with a headline and a device frame. These are what is uploaded.
- `header-3840x1646.png`, `search-results-3840x2560.png`, `search-results-1920x1280.png`.
- `video/kameti-walkthrough-60s-1206x2622.mp4` (the 1-minute video, attached to App Review) and `video/kameti-app-preview-29s-886x1920.mp4` (the App Store preview, capped at 30 s).
- Sizes Apple lists on the page: header 5244x2950 or 3840x1646; search results 5244x2950, 3840x2560 or 1920x1280; screenshots 1206x2622, 1179x2556, 2622x1206, 2556x1179; app previews 1920x886 or 886x1920.

## How the assets were made (repeatable)

1. Build for the sim and install over the old app: `xcodebuild -project ios/Kameti/Kameti.xcodeproj -scheme Kameti -destination 'id=78CF5CC5-…' -derivedDataPath <scratch> build`, then `xcrun simctl install <udid> …/Kameti.app`. The sim must run the **latest** build, not an old one. `git checkout --` the noisy `project.xcproj` and `Localizable.xcstrings` after building.
2. Clean status bar: `xcrun simctl status_bar <udid> override --time 9:41 --batteryState charged --batteryLevel 100 --cellularMode active --cellularBars 4 --wifiBars 3`.
3. Screenshots: `xcrun simctl io <udid> screenshot out.png`. Video: `xcrun simctl io <udid> recordVideo --codec h264 --force out.mov` (stop with SIGINT), then ffmpeg to cut and re-encode (`libx264`, `yuv420p`, `+faststart`, add a silent AAC track; Apple wants audio on previews).
4. Captions, header and search images were drawn with Pillow from the real captures (a scratch venv; Pillow is not installed system-wide). The scripts are in the session scratchpad only, so rebuild them if needed.
5. Upload only through **Claude in Chrome** `file_upload` on the hidden `file-input` of each section (header, search results, screenshots panel, attachment). The built-in browser has no file tool.

## Data used in the assets

- Real data, no demo flavor: the reviewer Google account `kameti.reviewer@gmail.com` (prod) owns **"Family Kameti 2026"**: 12 people, Rs 50,000 a slot, Nov 2026 to Oct 2027, 8 of 12 paid for November, 11 members "Not invited". The owner's profile and member name is **"Ahmed Raza"** (renamed from "Kameti Reviewer" in Profile and in the member sheet).
- The kameti lives in the prod database; the Play and Apple reviewers see it. Do not delete it before review ends.
- The first run of the walkthrough opened Collect November and marked two members, then closed without saving. Nothing was saved from the recording.

## Next steps, in order

1. Owner: enter the review contact (first name, last name, phone with `+`), the reviewer username and password, then **Save**.
2. Check the App Preview shows a thumbnail (processing finished) and that the six screenshots look right in the page's Preview.
3. Fill the remaining sections: App Privacy (match the Play Data safety answers: name, email, user ID, phone (optional), other financial info (recorded amounts only), user content (notes), device ID (push token); none shared; not used for tracking), age rating, pricing and availability, and iPad screenshots if iPad is a supported device.
4. **Add for Review** (owner's decision).
5. After approval, join the release with the Android side (same versions and the backend migrations that shipped).

## Things worth flagging

- The reviewer password was pasted into a chat on 2026-11-15. It belongs to a throwaway account, but change it once review is done.
- The listing text and screenshots say nothing about Sign in with Apple being absent on Android, which is fine: iOS offers both Apple and Google.
- Both stores' reviewers sign in with Google. For Android, Play's app-signing SHA-1 must be added to the Google OAuth client and Firebase (see the Android handoff) or the reviewer's sign-in fails in the store build.
- `docs/ROADMAP.md`, `.claude/rules/` and the code were not changed for any of this.
