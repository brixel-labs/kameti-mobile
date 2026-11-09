# Git workflow (Git Flow)

These rules apply to **kameti-mobile** and **kameti-backend**. Both use the same branching model and the same version numbers for a release, so a mobile release and its backend migrations ship together.

## Branches

| Branch | Created from | Merges into | Purpose | Protected |
|---|---|---|---|---|
| `main` | — | — | Exactly what is in production (stores / live Supabase). Every commit on `main` is a tagged release. | ✅ |
| `develop` | `main` (once) | — | Integration branch for the next release. Always builds and passes tests. | ✅ |
| `feature/<issue>-<slug>` | `develop` | `develop` (squash PR) | New functionality | — |
| `bugfix/<issue>-<slug>` | `develop` | `develop` (squash PR) | Non-urgent bug found before release | — |
| `release/<X.Y.Z>` | `develop` at cut-off | `main` (merge commit) **and** back into `develop` | Stabilising a release: version bump, changelog, release-blocking fixes only | ✅ while open |
| `hotfix/<X.Y.Z>` | `main` | `main` (merge commit) **and** `develop` (and any open `release/*`) | Urgent production fix | — |

- `<issue>` is the GitHub issue number when there is one: `feature/42-email-invites`. Without an issue: `feature/email-invites`.
- `<slug>` is lowercase kebab-case, at most 5 words.
- No other branch prefixes. A `chore/`, `docs/` or `refactor/` change goes on a `feature/` branch with the matching commit type.

## Commits: Conventional Commits

```
<type>(<scope>): <imperative summary, ≤72 chars, no full stop>

<optional body: why, not what>

<optional footer: Closes #42, BREAKING CHANGE: …>
```

- **Types:** `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `build`, `ci`, `chore`, `revert`.
- **Scopes (mobile):** `auth`, `kameti`, `members`, `slots`, `payments`, `payouts`, `reminders`, `invites`, `notes`, `ledger`, `ds` (design system), `l10n`, `release`, `deps`.
- **Scopes (backend):** `schema`, `rls`, `rpc`, `views`, `functions`, `cron`, `email`, `push`, `release`, `deps`.
- One logical change per commit. Formatting-only changes go in their own `style` commit.
- Commit messages created by Claude end with the attribution line from the session's system instructions.

## Pull requests

- `feature/*` and `bugfix/*` → `develop`: **squash merge**. The PR title becomes the commit, so it must be a valid Conventional Commit.
- `release/*` and `hotfix/*` → `main`: **merge commit** (`--no-ff`), never squash, so the tag points at a real merge.
- Back-merges (`release/*` or `hotfix/*` → `develop`): merge commit.
- Before opening a PR the branch must be **rebased on its target** and pass the local checks:
  - mobile: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`
  - backend: `supabase db lint`, `supabase test db`, function tests
- The PR body has: **What**, **Why**, **How to test**, **Screenshots** (UI changes, light + dark), **Checklist**, and `Closes #<issue>`.
- A PR touching money maths (ledger, balances, payouts, splits) must include or update tests that reproduce the reference sheet (REQUIREMENTS §3.3).

## Versioning

- SemVer `X.Y.Z`. `feat` → minor, `fix` → patch, `BREAKING CHANGE` → major (before 1.0.0, breaking → minor).
- Mobile: `pubspec.yaml` `version: X.Y.Z+<build>`. The build number is one integer that **only ever increases**, shared by iOS and Android.
- Tags: `vX.Y.Z` on `main`, annotated (`git tag -a`), in both repos for a joint release.
- `CHANGELOG.md` in "Keep a Changelog" format, generated from the Conventional Commits since the previous tag.

## Branch guards

GitHub branch protection isn't available for private repos on the org's current (free) plan, so `main` and `develop` are guarded locally:

- **`.githooks/pre-push`** refuses any direct push to, or deletion of, `main` or `develop`. Enable it once per clone with `git config core.hooksPath .githooks`. People can override it in an emergency with `KAMETI_ALLOW_PROTECTED_PUSH=1`.
- **`.claude/settings.json`**:
  - **denies** Claude direct pushes to `main` or `develop`, force-pushes, `--no-verify`, deleting those branches, changing `core.hooksPath`, and using the override variable;
  - **asks** before `gh pr merge`, tagging, pushing tags, deleting remote branches and creating GitHub releases.

Because of this, **every** change reaches `main` and `develop` through a PR, back-merges included. If the org moves to GitHub Team, switch on server-side protection with the same rules.

## Hard rules for Claude

1. **Never commit, push, open a PR, merge, tag or delete a branch unless the user asked for it in this conversation.** Approval for one doesn't carry over to the next.
2. **Never push to `main` or `develop` directly.** Changes reach them only through a PR.
3. **Never merge into `main` without the user's explicit "yes"** for that release or hotfix.
4. **Never force-push** `main`, `develop` or `release/*`. On your own feature or bugfix branch, `--force-with-lease` only, and only after a rebase.
5. **Never commit secrets or private data:** `.env*`, keystores, `*.p8`, `*.p12`, `google-services.json` / `GoogleService-Info.plist` for prod, the Supabase service-role key, the Resend key, or the reference spreadsheet PDF.
6. Before starting work, check `git status`. Never discard someone's uncommitted changes. Stash or ask.
7. If the work is on the wrong branch, stop and say so before committing.
8. **Never bypass the guards:** no `--no-verify`, no `KAMETI_ALLOW_PROTECTED_PUSH`, no changing `core.hooksPath`, no editing `.githooks/` or the deny rules in `.claude/settings.json` unless the user asks for that specific change.
