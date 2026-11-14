# Kameti — Mobile (native iOS and Android)

Kameti is a record-keeping and transparency app for rotating savings groups (kameti / committee). The owner records payments and payouts. Members have a read-only view. **No money moves through the app.**

- Product source of truth: `docs/REQUIREMENTS.md`. Cite FR-/E- numbers in plans, PRs and reviews.
- Design system: `docs/DESIGN_SYSTEM.md` (implemented in `ios/KametiKit/Sources/KametiUI`).
- Roadmap: `docs/ROADMAP.md`.
- iOS app: `ios/` (SwiftUI; see README for the layout and KametiKit layers).
- Android app: `android/` (Kotlin, Jetpack Compose), a module-for-module port of the iOS app. In progress: **read `docs/ANDROID_PORT_STATUS.md` first** (which phase is done, what is next, how to build and hand over) and update it at the end of every phase.
- Backend: sibling repo `../kameti-backend` (Supabase).
- Website (join links, support, privacy, account deletion): `legal-site/`.
- Bundle ID and Android application ID: `com.brixel.kameti`.

## Rules (in `.claude/rules/`)
- `git-workflow.md`: Git Flow (main / develop / feature / bugfix / release / hotfix), Conventional Commits, PR and versioning rules, and what Claude must never do with git.
- `ios-architecture.md`: KametiKit layers, `@Observable` view models, writes only via RPC, time and strings rules.
- `android-architecture.md`: the Gradle modules, convention plugins, view models, and the strings and tokens scripts.
- `design-system.md`: KDS components and tokens only in UI code.
- `money-and-ledger.md`: integer rupees, the share and payout maths, the reference fixture.

## Skills (in `.claude/skills/`)
| Skill | Use for |
|---|---|
| `git-feature` | start or finish a feature branch and PR to develop |
| `git-bugfix` | reproduce-first bug fix on a bugfix branch |
| `git-release-cut` | release cut-off → `release/X.Y.Z` → main + tag + back-merge (user-invoked only) |
| `git-hotfix` | urgent production fix from main (user-invoked only) |
| `ds-component` | add or change a reusable KDS component |

## Agents (in `.claude/agents/`)
| Agent | Role |
|---|---|
| `bug-investigator` | reproduces a bug, finds the root cause, writes the regression test |
| `code-reviewer` | pre-PR review: correctness, money, security, architecture, tests, git |
| `design-system-guardian` | reviews UI and new components for KDS compliance |
| `release-manager` | version, changelog, release PR body, risks (never merges or tags) |

## Commands
```bash
ios/scripts/use-env.sh prod|dev|demo
python3 design-tokens/generate.py
cd ios/KametiKit && xcodebuild test -scheme KametiKit-Package -destination 'id=<simulator-id>'
xcodebuild -project ios/Kameti/Kameti.xcodeproj -scheme Kameti -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build

# Android (JDK 21: export JAVA_HOME=$(/usr/libexec/java_home -v 21))
android/scripts/use-env.sh prod|dev|demo
python3 android/scripts/import-strings.py        # after changing an iOS String Catalog
cd android && ./gradlew test :app:assembleDebug
```

## Never
- Commit, push, open or merge PRs, or tag without the user asking (see `git-workflow.md`).
- Use `Double` for money, or show an amount without `Money.format()` / `KMoneyText`.
- Write to Supabase tables directly from the app, or ship the service-role key.
- Commit the reference spreadsheet PDF, `KametiConfig.json`, `GoogleService-Info.plist`, `google-services.json`, a keystore or any member contact details.
