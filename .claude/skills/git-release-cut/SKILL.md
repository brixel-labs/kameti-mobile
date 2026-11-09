---
name: git-release-cut
description: Cut a release from develop into a release/X.Y.Z branch, stabilise it, then (with approval) merge to main, tag, and back-merge into develop. Use when the user says "cut a release", "release cut-off", "prepare version X.Y.Z" or "ship the release".
argument-hint: "cut [X.Y.Z] | fix <description> | finish"
disable-model-invocation: true
---

# Release cut-off

Follow `.claude/rules/git-workflow.md`. Use the `release-manager` agent for the changelog and checks if the user wants it done in the background.

A release covers **both repos** when the backend changed. Cut, tag and ship them with the same version, backend first.

## 1. Cut (from develop)

1. `git status` must be clean. `git fetch origin --tags`, `git switch develop && git pull --ff-only`.
2. Make sure no other `release/*` branch is open (`git branch -r --list 'origin/release/*'`). If one is, stop and ask.
3. Make sure `develop` is green: run the local checks; check CI with `gh run list --branch develop --limit 1`.
4. Work out the version from the commits since the last tag (`git log $(git describe --tags --abbrev=0)..HEAD --oneline`):
   - any `BREAKING CHANGE` → major (minor before 1.0.0)
   - any `feat` → minor
   - otherwise → patch

   Tell the user the proposed version and the reason. Use theirs if they gave one.
5. `git switch -c release/X.Y.Z`.
6. Bump the version:
   - mobile: `pubspec.yaml` `version: X.Y.Z+<build>`, with build = previous build + 1;
   - backend: the `VERSION` file.
7. Generate `CHANGELOG.md` for the new version from the Conventional Commits, grouped as Added (feat), Fixed (fix), Changed (refactor/perf), and skipping chore/ci/style/test.
8. Commit `chore(release): X.Y.Z` (when the user has asked you to commit), push, and open a PR `release/X.Y.Z → main` titled `Release X.Y.Z` that includes the changelog and the QA checklist below.

**From the moment of the cut, `develop` is open again for the next release.** Only release-blocking fixes go on the release branch.

## 2. Stabilise

- Fixes go on `bugfix/<slug>` branches **from `release/X.Y.Z`**, with a PR back into `release/X.Y.Z`.
- No new features. If something isn't ready, revert it on the release branch instead of finishing it.
- Each fix increments the build number (not the version), e.g. `1.2.0+15 → 1.2.0+16`.

### QA checklist (in the PR body)
- [ ] Reference-sheet acceptance tests pass (REQUIREMENTS §3.3)
- [ ] Sign in with Google and with Apple (iOS + Android)
- [ ] Create kameti → members → slots/shares → order → start
- [ ] Record full, partial and advance payments; balances and credit are correct
- [ ] Record a payout, including one with a shortfall
- [ ] Member read-only view; no write controls; other groups invisible
- [ ] Email invite: app installed, app not installed, mismatched email → approval
- [ ] Reminders and owner broadcast received (push)
- [ ] Light/dark mode, large text, small phone
- [ ] Backend migrations applied to staging; RLS tests pass
- [ ] Store builds uploaded to TestFlight / Play internal testing

## 3. Finish (only with the user's explicit approval)

1. Confirm with the user: "Merge release X.Y.Z to main and tag vX.Y.Z?" Wait for a yes.
2. Merge the PR into `main` **with a merge commit** (`gh pr merge <n> --merge`).
3. Tag: `git switch main && git pull --ff-only && git tag -a vX.Y.Z -m "Release X.Y.Z" && git push origin vX.Y.Z`.
4. Back-merge into develop **through a PR**. Direct pushes to `develop` are blocked by the pre-push hook.
   ```bash
   gh pr create --base develop --head release/X.Y.Z --title "chore(release): back-merge X.Y.Z into develop"
   ```
   Merge it with a merge commit (`gh pr merge <n> --merge`) once the user approves. Resolve any conflicts on the release branch first.
5. Delete the release branch locally and on the remote, after the user agrees.
6. Create a GitHub release from the tag with the changelog: `gh release create vX.Y.Z --notes-file <notes>`.
7. Remind the user of the store steps: submit the iOS build for review, promote the Android build from internal → production, and check Sentry for the new release.
