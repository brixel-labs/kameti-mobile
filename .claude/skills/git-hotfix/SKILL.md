---
name: git-hotfix
description: Urgent production fix on a hotfix/X.Y.Z branch from main, merged into main (tagged) and back into develop and any open release branch. Use only for live-production problems such as wrong money amounts, data loss, sign-in broken, crashes on launch, or another group's data being visible.
argument-hint: "<issue#> <description>"
disable-model-invocation: true
---

# Hotfix

Follow `.claude/rules/git-workflow.md`.

1. Confirm it really is a production emergency (see the git-bugfix skill). If it can wait for the next release, use `git-bugfix` instead.
2. `git status` (clean), `git fetch origin --tags`, `git switch main && git pull --ff-only`.
3. The version is the latest tag's patch + 1: `v1.2.0 → 1.2.1`. Then `git switch -c hotfix/1.2.1`.
4. Reproduce it with a **failing regression test** (use the `bug-investigator` agent if the cause isn't obvious).
5. Make the **smallest possible fix**. No refactors and no unrelated changes.
6. Bump the version (`MARKETING_VERSION` 1.2.1, `CURRENT_PROJECT_VERSION` build+1 / backend `VERSION`) and add a `CHANGELOG.md` entry.
7. Run the full local checks and the reference-sheet tests.
8. When the user asks: commit (`fix(<scope>): …`, then `chore(release): 1.2.1`), push, and open a PR `hotfix/1.2.1 → main` labelled **hotfix**.
9. **With the user's explicit approval only:** merge with a merge commit, then tag `v1.2.1` on main and push the tag.
10. Back-merge `hotfix/1.2.1` into `develop` **through a PR** (`gh pr create --base develop --head hotfix/1.2.1`, then merge with a merge commit). Direct pushes to `develop` are blocked. If a `release/*` branch is open, open a PR into that too (otherwise the fix is lost in the next release).
11. If the backend changed, deploy the migration or function to production first, then ship the app build. Tell the user which store builds to expedite (iOS: request an expedited review).
12. Delete the hotfix branch after the user agrees.
