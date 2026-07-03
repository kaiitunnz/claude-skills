---
name: make-commits
description: Split current staged and unstaged changes into multiple logical commits whose messages match the repo's existing style. Verifies the configured git author against recent commits before committing, honors a project signoff convention if AGENTS.md / CONTRIBUTING.md require it, and pauses on non-trivial pre-commit hook failures. Use when the user says "make commits", "/make-commits", or asks to commit a mixed bag of changes as separate logical units.
---

Turn a dirty working tree into a clean stack of commits that look like they belong to the repo. The user wants logical grouping, faithful style match, no accidental files, and no surprises in author/signoff configuration.

## Step 1 — Survey the changes

Run in parallel:

- `git status` (never `-uall`) — full list of staged + unstaged + untracked.
- `git diff --stat` and `git diff --cached --stat` — file-level shape of both halves.
- `git log -10 --format='%h %an <%ae> %s'` — recent commits for author and subject style.
- `git log -5 --format='%B' --no-merges` — recent commit *bodies* for trailer/signoff conventions.
- `git config user.name` and `git config user.email`.

If the working tree is clean (nothing staged, nothing unstaged, no untracked), stop with: "Nothing to commit."

## Step 2 — Verify the author

Compare the configured `user.name`/`user.email` to recent commit authors from step 1:

- If `user.email` looks suspicious (empty, `you@example.com`, an AI noreply like `*@anthropic.com`, or doesn't appear in recent commit history at all when other authors do), **stop and ask the user to confirm**. Show what you found and what you'd commit as.
- If the configured author matches recent commits, proceed silently.
- If the repo has no recent commits to compare against, surface the configured author and ask the user to confirm before continuing.

Do **not** edit git config. Author correction is the user's call.

## Step 3 — Detect signoff and other trailer conventions

Look for explicit signoff requirements in:

- `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`
- `CONTRIBUTING.md`, `docs/CONTRIBUTING.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

Signals: "DCO", "Developer Certificate of Origin", "sign off your commits", "Signed-off-by".

Also scan the recent commit bodies (from step 1) for the actual trailers in use:

- `Signed-off-by: Name <email>` — DCO signoff. If present in most recent commits **or** required by docs, include it on every commit you create.
- `Co-Authored-By: ...` — only add when the user requests it; don't add it just because earlier commits have it.
- Project-specific trailers (e.g. `Change-Id`, `Reviewed-by`) — match if they're consistent in the repo.

Use `git commit -s` for DCO signoff (git generates the trailer from the configured author). Do not hand-write the signoff line.

## Step 4 — Plan the commit groups

Read the diff of changed files (`git diff`, `git diff --cached`, and `git diff` against untracked files individually) to understand scope. Group files into commits by:

- **Concern** — backend vs. frontend; feature code vs. tests vs. docs; refactor vs. new behavior; bugfix vs. polish.
- **Atomicity** — each commit should pass tests on its own where practical. Don't ship a feature commit whose tests live in a later commit.
- **Order** — dependencies before dependents (schema before code that uses it; lib changes before callsites).

Output the plan to the user **before** running any `git add` / `git commit`:

    Planned commits:
    1. <subject> — files: a, b, c
    2. <subject> — files: d, e

For 3+ commits, also use **TodoWrite** to track each as a todo item; mark in_progress / completed as you commit.

If anything in the worktree looks unrelated to the user's apparent intent (stray build artifacts, accidentally-edited config files, unrelated dependency bumps), call it out in the plan and ask whether to include or skip. Do not silently bundle.

Get user confirmation if the plan has 3+ commits or if anything was ambiguous. For 1–2 obvious commits, proceed.

## Step 5 — Stage and commit, one group at a time

For each planned commit:

- **Stage by name**, never `git add -A` / `git add .`. Use `git add <path> [<path> ...]` so accidental files don't ride along.
- For partial-file commits (one file split across multiple commits), use `git add -p <path>` and walk the hunks. Mention this in the plan beforehand — it's not always obvious from `git status`.
- Verify what's actually staged with `git diff --cached --name-only` before committing.
- Write the subject in the project's observed style:
  - **Imperative mood** (`Add X`, `Fix Y`, `Refactor Z`).
  - Match the prefix convention (`feat:` / `fix:` / `chore:` / lowercase noun / etc.) from recent commits.
  - ≤ ~70 chars. Details go in the body.
- Add a body only when the *why* is non-obvious. One short paragraph. No bullet-list summary of the diff; the diff is the diff.
- Apply the trailer convention from step 3 (`-s` for DCO).

Commit with heredoc to preserve formatting:

    git commit -s -m "$(cat <<'EOF'
    <subject>

    <optional body>
    EOF
    )"

(`-s` only if signoff is required; omit otherwise.)

After each commit, run `git status` to confirm the working tree shrank by exactly the staged files and nothing else.

## Step 6 — Handle pre-commit hook failures

If a commit fails because a hook made changes (auto-formatters like `black`, `prettier`, `ruff --fix`, `isort`):

- The commit did **not** happen — never `--amend` to "fix" it. That would amend the previous commit instead.
- Inspect what the hook modified (`git status` + `git diff`).
- If the changes are clearly cosmetic and limited to files already in this commit group (e.g. import sorting, whitespace, line-length reflow), re-stage those files and re-run `git commit`. This is the "trivial" path.
- If the hook touched files outside the current group, or made semantic changes, or failed with an error rather than a fix — **stop and surface the failure to the user**. Quote the hook output. Do not retry, do not edit, do not stage other files.

If a hook fails on a check that requires code changes (lint, mypy, typecheck), **always surface and pause**. Don't try to fix lint findings as part of this skill.

## Step 7 — Final report

When all commits are in, output:

    Created <N> commits on <branch>:
      <short-hash> <subject>
      ...
    Working tree: <clean | "<file>" still untracked>

No further commentary.

## Guardrails

- **Never `git add -A` / `git add .` / `git add -u`.** Always name files.
- **Never `--amend`.** Pre-commit failures mean the commit didn't happen; create a new commit.
- **Never edit `git config`** — author correction is the user's decision.
- **Never `--no-verify`** to skip hooks. If a hook fails, surface it.
- **Never commit lockfiles, build outputs, `.env`, or credential files** unless the user explicitly included them in the plan.
- **Never push.** This skill stops at the local commits.
- **Don't invent commit groups.** If everything is one logical change, ship it as one commit and say so.
