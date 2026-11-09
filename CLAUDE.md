# Kameti — Mobile (Flutter)

Kameti is a record-keeping and transparency app for rotating savings groups (kameti / committee). The owner records payments and payouts. Members have a read-only view. **No money moves through the app.**

- Product source of truth: `docs/REQUIREMENTS.md`. Cite FR-/E- numbers in plans, PRs and reviews.
- Design system: `docs/DESIGN_SYSTEM.md`.
- Backend: sibling repo `../kameti-backend` (Supabase).
- Web pages (join links, privacy, account deletion): `/kameti/*` in `../../fhb-website`, which is a **public** repo, so never copy these docs or any member data there.
- Bundle ID / package: `com.brixel.kameti`.

## Rules (in `.claude/rules/`)
- `git-workflow.md`: Git Flow (main / develop / feature / bugfix / release / hotfix), Conventional Commits, PR and versioning rules, and what Claude must never do with git.
- `flutter-architecture.md`: feature-first layers, Riverpod, writes only via RPC, time and l10n rules.
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
| `flutter-feature-developer` | implements a feature end to end with tests |
| `bug-investigator` | reproduces a bug, finds the root cause, writes the regression test |
| `code-reviewer` | pre-PR review: correctness, money, security, architecture, tests, git |
| `design-system-guardian` | reviews UI and new components for KDS compliance |
| `release-manager` | version, changelog, release PR body, risks (never merges or tags) |

## Commands
```bash
fvm flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json
```
(The app hasn't been scaffolded yet. These commands apply once Phase 0 is done.)

## Never
- Commit, push, open or merge PRs, or tag without the user asking (see `git-workflow.md`).
- Use `double` for money, or show an amount without `KMoneyText`.
- Write to Supabase tables directly from the app, or ship the service-role key.
- Commit the reference spreadsheet PDF or any member contact details.
