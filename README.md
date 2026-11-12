# Kameti — Mobile

Native iOS app for running a kameti (committee / ROSCA): the owner records contributions and payouts, and members see their dues, the payout schedule and each month's pot status (read-only). Android comes later.

- **Stack:** SwiftUI, Swift 6, iOS 26, supabase-swift; Xcode 27.2
- **Bundle ID:** `com.brixel.kameti`
- **Backend:** [kameti-backend](https://github.com/fhb-tech-services/kameti-backend) (Supabase)
- **Website** (join links, support, privacy, account deletion): `legal-site/`, served at kameti.fhbtechservices.com
- **Design board:** https://claude.ai/artifact/CU8Y4xmfhCPFHoMyavyf6e (direction A, row A)

## Docs

- [Requirements](docs/REQUIREMENTS.md): the source of truth for product rules, edge cases and plan.
- [Design system](docs/DESIGN_SYSTEM.md): tokens and the `K*` component catalogue.
- [Roadmap](docs/ROADMAP.md): what's built and the order of work.

## First-time setup

```bash
git config core.hooksPath .githooks   # blocks direct pushes to main/develop
ios/scripts/use-env.sh prod           # or dev (local Supabase) or demo (sample data)
open ios/Kameti/Kameti.xcodeproj
```

`ios/scripts/use-env.sh` copies `env/<flavor>.json` (gitignored; start from `env/example.json`) into the app as `KametiConfig.json`. Push needs `ios/Kameti/Kameti/GoogleService-Info.plist` from the Firebase console (gitignored).

## Project layout

```
ios/
  Kameti/            the thin app target (Kameti.xcodeproj, JSON .xcproj format): app icons,
                     sign-in providers, push, wiring
  KametiKit/         Swift package with all app code (iOS 26, Swift 6)
  scripts/           use-env.sh
design-tokens/       tokens.json is the single source of truth; generate.py writes Swift
docs/                requirements, design system, roadmap
legal-site/          static website (Vercel)
env/                 per-flavor backend settings (gitignored except example.json)
```

## KametiKit layers (dependencies point inward)

| Target | Contains | Depends on |
|---|---|---|
| `KametiCore` | `Money`, `Failure`, Pakistan-time `KametiClock`, JSON rules | nothing |
| `KametiDomain` | backend row models, repository protocols (typed `throws(Failure)`) | Core |
| `KametiUI` | design tokens, components (SwiftUI) | Core |
| `KametiData` | supabase-swift implementations of the protocols | Domain, Core |
| `Feature*` | screens + `@Observable` view models | Domain, UI (never Data) |

Only the app target links `KametiData` and wires it into the features, so every view model is tested with fake repositories.

## Commands

```bash
# After editing design-tokens/tokens.json
python3 design-tokens/generate.py

# Unit tests (any iPhone simulator id from `xcrun simctl list devices available`)
cd ios/KametiKit && xcodebuild test -scheme KametiKit-Package -destination 'id=<simulator-id>'

# Build the app
xcodebuild -project ios/Kameti/Kameti.xcodeproj -scheme Kameti -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build
```

CI (`.github/workflows/ci.yml`) runs the KametiKit tests on pushes to `develop` and `main` (after a PR merges), so run them locally before opening a PR. It can also be started by hand from the Actions tab.
