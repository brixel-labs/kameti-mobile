---
name: git-feature
description: Start or finish a feature branch in the Kameti Git Flow. Use when beginning new functionality ("start a feature for email invites") or when a feature is done and needs a PR to develop.
argument-hint: "start <issue#> <slug> | finish"
---

# Feature branch

Follow `.claude/rules/git-workflow.md`. Branch: `feature/<issue>-<slug>` from `develop`, squash-merged back into `develop`.

## Start

1. `git status`. If there are uncommitted changes, stop and ask what to do with them.
2. `git fetch origin` and `git switch develop && git pull --ff-only`.
3. If an issue number was given, read it: `gh issue view <n>`. Restate the acceptance criteria and the REQUIREMENTS.md sections it touches (FR-/E- numbers).
4. `git switch -c feature/<issue>-<slug>`.
5. Plan the change in small steps. For UI, list the design-system components it uses (`docs/DESIGN_SYSTEM.md`). If a needed component doesn't exist, build it first with the `ds-component` skill.

## While working

- Commit in small Conventional Commits (`feat(payments): …`) **only when the user has asked you to commit**.
- Write tests alongside the code: unit for logic, widget for screens, golden for new DS components.
- Keep the branch up to date: `git fetch origin && git rebase origin/develop`.

## Finish

1. `git fetch origin && git rebase origin/develop`. Resolve conflicts carefully; never drop the other side's changes without asking.
2. Run the local checks:
   - mobile: `dart format --set-exit-if-changed . && flutter analyze && flutter test`
   - backend: `supabase db lint && supabase test db`
3. Fix anything that fails. Don't skip or delete tests to make them pass.
4. Ask the `code-reviewer` agent to review the diff against `develop`, and address its findings.
5. Once the user asks for it, push (`git push -u origin HEAD`) and open the PR:
   ```bash
   gh pr create --base develop --title "feat(<scope>): <summary>" --body-file <body>
   ```
   The body uses the PR template: What / Why / How to test / Screenshots (light + dark) / Checklist / `Closes #<issue>`, ending with the attribution line from the session's system instructions.
6. Report the PR link. Don't merge it yourself unless the user asks.
