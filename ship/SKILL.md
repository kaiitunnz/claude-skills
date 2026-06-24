---
name: ship
description: Take a finished branch all the way out — verify (pre-commit + full tests), commit, push, open a PR, then critically self-review and address every finding before reporting done. Orchestrates the other git/PR/review skills when they're installed and falls back to doing each step inline when they aren't. Optional argument `draft` opens the PR as a draft. Use when the user says "ship it", "/ship", or "take this to a PR".
---

Drive a ready branch through the whole release path: **verify → commit → push → open PR → self-review → address findings → done**. This is an orchestrator. Each step has a dedicated skill; when that skill is installed, invoke it and treat it as authoritative for its step. When it isn't, do the step inline following the principles named here. Never duplicate a delegated skill's work — call it, read its output, move on.

`ARGUMENTS` is optional. The only accepted value is the literal `draft` (case-insensitive), which is passed through to PR creation. Anything else is an error — surface it and stop.

Invoking `/ship` authorizes the full pipeline (including the push and the PR). Do **not** re-confirm each step. Do stop and surface whenever a step fails, is ambiguous, or wants to widen scope — the gates below are where the pipeline halts.

## Step 1 — Preflight

Run in parallel:

- `git status` — staged / unstaged / untracked.
- `git rev-parse --abbrev-ref HEAD` — current branch.
- `git rev-parse --abbrev-ref --symbolic-full-name '@{u}'` — upstream, if any (may fail; fine).
- Determine the base: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, falling back to `main`.
- `git log --oneline <base>..HEAD` — commits already ahead of base.
- `gh pr view --json number,url,state,isDraft` — does an open PR already exist for this branch?
- Read `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `CONTRIBUTING.md` — for the verify commands and project conventions.

Hard stops:

- **On the default branch** (current branch == base) — stop and ask for a branch name; `/ship` does not push features straight to `main`. Offer to create the branch off the current HEAD.
- **Nothing to ship** — clean worktree *and* no commits ahead of base *and* no existing PR. Stop with "Nothing to ship."

Then state the plan in one block: branch, base, what will be committed (or "already committed, N ahead"), the verify commands you'll run, whether a PR will be opened or an existing one updated.

## Step 2 — Verify (pre-commit + tests)

Find the project's verify commands in the docs read at step 1 (sections like "Testing", "Verification", "Pre-commit", "Build") and in the tool configs:

- **Pre-commit / lint / type:** `pre-commit run --all-files`, `ruff`, `mypy`/`pyright`, `npm run lint`, `tsc --noEmit`, etc.
- **Full test suite:** `pytest`, `npm test`, `cargo test`, `go test ./...`, etc. — run it *if the project has one*. Detect by presence of a test dir / documented command. If there is genuinely no test suite, say so and skip — that's the "if applicable" clause, not a license to skip an existing one.

Run them against the current worktree (everything you're about to ship). Run independent commands in parallel where they don't share state.

This is a **hard gate**. If any verify command fails:

- Surface the failure verbatim and **stop**. Do not commit or push broken code.
- Don't auto-fix here — a real failure is the user's call (or a separate `/address-ci-failures` / debugging pass). The exception: a formatter that *only reformats* files (no errors) — re-running clean is fine; fold its changes into the commit.

## Step 3 — Commit

Only if there are uncommitted changes. If the worktree is already clean and the branch is ahead, skip to step 4.

- If `/make-commits` is available, **invoke it** and let it plan the logical commits, match repo style, verify author, and handle signoff. Read its report.
- Otherwise commit inline following its principles: group by concern, stage **by name** (never `git add -A`), match the repo's subject style, signoff only if the project requires it. Never `--amend`, never `--no-verify`.

If `/make-commits` pauses (author mismatch, pre-commit hook failure, ambiguous grouping), let it pause — do not paper over it.

## Step 4 — Push

- No upstream → `git push -u origin <branch>`. Otherwise `git push`.
- If the branch already has an upstream and history was rewritten, **stop and ask** before any force-push; use `--force-with-lease`, never bare `--force`. (Plain `/ship` should not be rewriting history — if it is, something upstream went wrong; surface it.)
- If push fails (rejected, no remote), surface the error and stop.

## Step 5 — Open or update the PR

- **Existing open PR** (from step 1): don't create a duplicate. The push already updated it; note the PR URL and continue.
- **No PR:** if `/create-pr` is available, **invoke it** (pass `draft` through when given). It mirrors the repo's PR style. Otherwise open one inline with `gh pr create`, matching the title prefix and body structure of recent merged PRs; reference any related issue with non-auto-closing phrasing (`Addresses #N`).

Capture the PR URL — the self-review and final report need it.

## Step 6 — Critical self-review

Review what you just shipped, **critically and with fresh eyes**. The goal is to catch what the author (you) is biased not to see.

- **Prefer a subagent.** If your harness can spawn a sub-agent with its own context, delegate the review to one so it reads the diff cold rather than reusing your justifications. Instruct it to run `/review-pr <N>` (or `/review-diff` if the PR isn't reviewable yet) and return the structured verdict + findings. If no subagent capability exists, do the review inline.
- Use `/review-pr` (PR is open) when available; fall back to `/review-diff <branch> <base>` for a local range review. If neither skill is installed, review inline against correctness, project coding conventions, and other concrete issues — no padding, no invented findings.

Capture the verdict and the per-finding list verbatim.

## Step 7 — Address findings (loop)

If the review verdict is **clean** ("Ready to merge" / "Looks good") with no actionable findings, skip to step 8.

Otherwise, work the findings:

- If `/address-review` is available, **invoke it** with the review text. It evaluates each finding (accept / push back / clarify with reasoning), implements the accepted ones, and leaves changes staged. Honor its push-backs — a finding you genuinely disagree with stays unaddressed, with the reasoning recorded.
- Otherwise address them inline with the same discipline: fix what's genuinely right, push back with reasoning on what isn't, don't widen scope.

After changes are made:

1. **Re-verify** the affected scope (at minimum the relevant tests/lint; the full suite if changes were broad). Same hard gate as step 2.
2. **Commit** the fixes (step 3's path) and **push** (step 4's path) — this updates the open PR.
3. **Re-review** once more (step 6) to confirm the findings are resolved and nothing regressed.

Bound the loop to **at most 2 address→re-review rounds**. If the review still reports blocking findings after that, **stop and surface them** — don't loop indefinitely or quietly downgrade them. Genuine disagreements (push-backs) don't count as unresolved; record them and move on.

## Step 8 — Final report

End with a compact pipeline summary:

    Shipped <branch> → <base>.
      Verify:  <commands> — passed
      Commits: <N> (<short-hash> <subject> …)
      PR:      <url>  [draft]
      Review:  <final verdict>; <N findings addressed, M pushed back>

    <PR URL on its own line>

If anything stopped the pipeline early, report where and why instead — what passed, what failed, and the exact next action the user needs to take.

## Guardrails

- **Don't ship broken code.** A failed verify (step 2 or step 7) halts the pipeline. No `--no-verify`, no skipping an existing test suite.
- **Don't push to the default branch.** `/ship` always works on a feature branch.
- **Don't force-push without asking**, and never bare `--force` — `--force-with-lease` only, after confirmation.
- **Don't duplicate a PR.** Reuse the existing open PR for the branch.
- **Don't suppress your own review.** Findings are addressed or explicitly pushed back with reasoning — never silently dropped to reach "done".
- **Don't widen scope.** If addressing a finding tempts a refactor nobody asked for, surface it and ask.
- **Delegate, don't re-implement.** When a sub-skill is installed, call it and trust its output; only fall back to inline work when it's absent.
- **Surface every halt.** Author mismatch, push rejection, unresolved findings, ambiguous state — stop and tell the user the exact next step rather than guessing.
