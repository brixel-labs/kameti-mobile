---
name: git-bugfix
description: Fix a non-urgent bug on a bugfix branch from develop, reproduce-first with a regression test. Use when the user reports a bug that is not breaking production right now. For a live production emergency, use git-hotfix instead.
argument-hint: "<issue#> <slug> | <bug description>"
---

# Bugfix branch

Follow `.claude/rules/git-workflow.md`. Branch: `bugfix/<issue>-<slug>` from `develop`, squash-merged back into `develop`.

**Is it a hotfix?** If the bug is in the live app or live database and is losing data, showing wrong money amounts to users, blocking sign-in or payments recording, or leaking another group's data, stop and suggest `git-hotfix` instead.

**Is a release open?** If `release/*` exists and the bug blocks that release, branch from the release branch instead and target it (see `git-release-cut`).

## Steps

1. `git status` (stop on uncommitted changes), `git fetch origin`, `git switch develop && git pull --ff-only`.
2. Read the issue (`gh issue view <n>`) or write down the report as:
   **Steps to reproduce / Expected / Actual / Device, OS, app version / Kameti state** (N, C, shares, payments involved).
3. `git switch -c bugfix/<issue>-<slug>`.
4. For anything non-trivial, hand the investigation to the `bug-investigator` agent and use its root-cause report.
5. **Write a failing test first** that reproduces the bug (unit, widget, or `supabase test db`). Run it and confirm it fails for the right reason.
6. Fix the root cause, not the symptom. Keep the change as small as possible.
7. Run the test again (now passing) and the full local checks.
8. If money is involved, check the reference-sheet tests still pass (REQUIREMENTS §3.3).
9. When the user asks: commit as `fix(<scope>): <summary>` with `Closes #<issue>`, push, and open a PR to `develop` with **Root cause**, **Fix**, **Regression test** and **How to verify** sections.
