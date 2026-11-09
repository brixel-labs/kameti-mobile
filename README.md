# Kameti — Mobile

iOS and Android app for running a kameti (committee / ROSCA): the owner records contributions and payouts, and members see their dues, the payout schedule and each month's pot status (read-only).

- **Stack:** Flutter 3.47.5 (Dart 3.13), Riverpod, go_router, supabase_flutter
- **Bundle ID / package:** `com.brixel.kameti`
- **Backend:** [kameti-backend](https://github.com/fhb-tech-services/kameti-backend) (Supabase)
- **Web pages** (join links, privacy, account deletion): `www.fhbtechservices.com/kameti/*` in [fhb-website](https://github.com/fhb-tech-services/fhb-website)
- **Design board:** https://claude.ai/artifact/CU8Y4xmfhCPFHoMyavyf6e (direction A, row A)

## Docs

- [Requirements](docs/REQUIREMENTS.md): the source of truth for product rules, edge cases, tech stack and plan.
- [Design system](docs/DESIGN_SYSTEM.md): tokens and the `K*` component catalogue.

## First-time setup

```bash
git config core.hooksPath .githooks   # blocks direct pushes to main/develop
flutter pub get
cp env/example.json env/dev.json      # then fill in the Supabase URL and publishable key
```

The Flutter version is pinned in `.fvmrc` (3.47.5). With [FVM](https://fvm.app) installed, prefix commands with `fvm`.

## Run

```bash
flutter run -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```

Without an env file the app still starts, with no backend (handy for UI work).

## Before every PR

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
```

CI (`.github/workflows/ci.yml`) runs the same checks on every PR to `develop`, `main` and `release/*`.

## Project layout

```
lib/
  main_dev.dart · main_staging.dart · main_prod.dart   # entry points
  app/            # bootstrap, app widget, router
  core/           # env, Money, KametiClock (Pakistan time)
  design_system/  # tokens, theme, K* components (import design_system.dart only)
  features/       # auth, home, invites, … (data / domain / presentation)
  l10n/           # app_en.arb → generated AppLocalizations
```

Native flavors (separate bundle IDs and Firebase projects for dev, staging and prod) come once the Firebase projects exist. Until then the environment is chosen only by the `env/*.json` file.
