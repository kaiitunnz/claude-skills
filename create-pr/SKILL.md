---
name: create-pr
description: Open a pull request that matches the host repo's existing style. Use when the user says "create a PR" or "open a PR" and there is a non-empty branch ahead of the base. Inspects recent merged PRs to learn the project's title prefix, body structure, and detail level, then drafts a faithful PR body and pushes the branch. Optional argument `draft` opens a draft PR instead.
---

Open a pull request for the current branch that **matches the host repository's existing PR style** — title prefix, body section order, level of detail, formatting. Do not invent a generic template.

The user invokes this when their branch is ready to ship. Read the codebase first; do not assume any specific convention.

`ARGUMENTS` is optional. The only accepted value is the literal `draft` (case-insensitive); anything else is an error — surface it and stop. When `draft` is passed, open the PR as a draft via `gh pr create --draft`.

## Step 1 — Inspect repo state

Run these in parallel:

- `git status` — must be clean (no uncommitted changes). If dirty, stop and tell the user to commit/stash first.
- `git log --oneline <base>..HEAD` — confirm there are commits ahead. If zero, stop.
- `git rev-parse --abbrev-ref HEAD` — current branch.
- `git rev-parse --abbrev-ref --symbolic-full-name '@{u}'` (may fail if no upstream — that's fine).
- `gh pr list --state merged --limit 5 --json number,title,url` — recent merged PRs for style reference.

`<base>` is usually `main` or `master`. Confirm by checking `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` if unsure.

## Step 2 — Learn the project's PR style

Pick **2–3 recent merged PRs** (from step 1's list, skip drafts and bot PRs) and fetch their bodies:

    gh pr view <N> --json title,body

Read carefully and extract:

- **Title prefix convention** — `feat:` / `fix:` / `chore:` / no prefix / something custom? Imperative mood? Length?
- **Body section structure** — `## Summary` then `## Changes` then `## Test Plan`? Just a paragraph? Bullet-only? Per-area subsections (`### Backend` / `### Frontend`)?
- **Detail level** — terse (one short paragraph per section) vs. detailed (specific function names, file paths, behaviors). Match the median of recent PRs.
- **Test-plan format** — checkbox list of commands? Plain text? Manual steps?
- **Issue references** — `Addresses #N` vs `Fixes #N`. Default to **`Addresses #N`** (non-auto-closing) unless the project clearly uses `Fixes`.

## Step 3 — Draft the PR

Title: imperative, prefix matching the project, ≤70 chars. Details go in the body, not the title.

Body: faithfully follow the section structure you observed. Use the same heading levels, bullet styles, and detail granularity. If the project splits changes into backend/frontend (or other areas), do the same here when applicable.

For each change, prefer concrete specifics (function names, file paths, behavior) over hand-waving. Don't restate what the diff already shows — explain the *why* and the user-visible effect.

Test plan: list the actual commands you ran during this branch's development (tests, lint, build, manual verification). If something wasn't run, say so explicitly rather than fabricating a checkmark.

If the branch addresses a GitHub issue, link it. Use `Addresses #N` (or whatever non-auto-closing phrasing the project uses) so the user can close the issue manually after verification.

## Step 4 — Push and open

- If no upstream, push with `-u`. Otherwise plain `git push`.
- Run `gh pr create --title "..." --body "$(cat <<'EOF' ... EOF)"` to preserve markdown formatting via heredoc. Add `--draft` when `ARGUMENTS` is `draft`.
- Return the PR URL on its own line so the user can click it. If it was opened as a draft, prefix the URL with `Draft PR: ` so it's obvious from the output.

## Guardrails

- **Don't create a commit.** If something needs committing, ask the user first.
- **Don't force-push.** If push fails, surface the error.
- **Don't squash or rebase** without explicit request.
- **Don't claim test-plan items that weren't actually run** in this session.
- **Don't fabricate "screenshots attached" or other artifacts.** Omit the line if not applicable.
- If the project uses a PR template (`.github/PULL_REQUEST_TEMPLATE.md`), prefer its structure over recent-PR inference.

## Output

End with one line: the PR URL. No summary, no "happy reviewing" footer.
