---
name: address-ci-failures
description: Diagnose and fix failing CI checks on a PR. Fetches failing runs via `gh pr checks` / `gh run view`, classifies each failure (lint / type / test / build / infra-flake), reproduces locally where possible, and fixes them in batch. Optional argument is a PR number, PR URL, a run URL/ID, a path/file containing log output, or pasted log text; defaults to the open PR for the current branch. Leaves changes staged for /make-commits.
---

Take a PR with red CI and turn it green. Fetch the failing checks, work out why each one failed, fix them all locally, and leave the changes staged for the user to commit. The output is staged code changes plus a per-check summary of what was wrong and what changed.

`ARGUMENTS` is optional. Accepted forms, in resolution order:

1. **Empty** — address failures on the open PR for the current branch. Resolve via `gh pr view --json number,url`.
2. **Bare integer** (matches `^\d+$`) — a PR number. Fetch via `gh pr view <N>` and `gh pr checks <N>`.
3. **GitHub PR URL** (contains `github.com/.../pull/`) — same path, PR number parsed from URL.
4. **GitHub run URL or run ID** (contains `/actions/runs/` or matches a numeric run ID under `gh run list`) — single-run mode: only address that one run's failures via `gh run view <id> --log-failed`.
5. **Existing file path** — read its contents as the log text. Skip the `gh` fetch entirely.
6. **Anything else** — treat the argument verbatim as the log text. This is the common case for pasting a CI failure block directly into the invocation.

Detect in that exact order. A multi-line pasted log starting with `Error:` is log text (rule 6), not a PR number.

## Step 1 — Establish context

Run in parallel:

- `git status` — record whether the worktree is clean.
- `git rev-parse --abbrev-ref HEAD` — current branch.
- Resolve the target PR / run per the rules above. For PR mode: `gh pr checks <N> --json name,state,link,workflow` to enumerate checks; `gh pr view <N> --json number,url,headRefName,headRefOid`.
- Read `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, and any CI workflow files in `.github/workflows/` — you need to know what each check actually runs locally.

If the worktree has uncommitted changes from earlier work, **stop and ask** whether to layer fixes on top or stash first. Mixing in-progress work with CI fixes makes `/make-commits` harder to split cleanly.

If `gh pr checks` shows zero failing checks (everything passing or pending), **stop and report that** — don't invent failures.

## Step 2 — Collect failing logs

For each failing check, fetch the failed-step log:

    gh run view <run-id> --log-failed

`<run-id>` comes from the `link` field in `gh pr checks` JSON (the run ID is the last numeric segment of the URL). For checks reported by external services (e.g. third-party bots), note that you cannot fetch their logs and surface that to the user.

If a single run has multiple failed jobs, fetch the log once and split by job — don't make N separate `gh run view` calls.

For pasted-log / file-path mode (rules 5–6), skip this step and treat the provided text as the full failure context.

## Step 3 — Classify each failure

For every distinct failure, assign one of:

- **lint** — formatter, linter, style check (ruff, eslint, black, prettier, isort, codespell).
- **type** — type checker (mypy, pyright, tsc).
- **test** — unit/integration test failure.
- **build** — compile / bundle / package step failed before tests ran.
- **infra-flake** — clearly transient (runner OOM, network timeout, registry 5xx, action setup failures unrelated to the diff). Mark these for **retry**, not fix.
- **unknown** — can't tell from logs. Surface and ask.

Output the classified list to the user before doing anything else, so they can correct misclassifications and decide whether to re-run flakes vs. fix them.

For 4+ failures, use **TodoWrite** to track each one (pending → in_progress → completed).

## Step 4 — Reproduce locally where possible

For each non-flake failure, run the same command the workflow ran, locally:

- Read the workflow YAML to find the exact command (don't guess — projects often have non-default flags).
- Run it. If the failure reproduces, you have the right diagnosis.
- If it doesn't reproduce, surface that to the user before changing code — it usually means an env/version mismatch worth investigating rather than a code bug.

Reproducing isn't always possible (e.g. failures requiring secrets, specific OS, or external services). When you can't reproduce, work from the log alone but say so explicitly in the summary.

## Step 5 — Fix all failures in batch

Work through every non-flake failure and apply the minimal fix:

- Make the smallest change that addresses the root cause. Don't refactor surrounding code.
- After each fix, re-run the relevant local command to confirm the failure is gone.
- If fixing one check breaks another (e.g. silencing a lint introduces a type error), surface and resolve before continuing.

For **infra-flake** items, do **not** edit code. Note them as "retry recommended" — the user can re-run via `gh run rerun <id>`.

Do **not** commit, stage, or push. The user will run `/make-commits` after the summary.

If a fix turns out to be non-trivial (requires design decisions, scope expansion, or might break unrelated behavior), **stop and ask** — don't barrel through.

## Step 6 — Final summary

End the response with a per-check block, in the order the checks appeared:

    **<check name>** — <verdict: Fixed / Retry / Skipped — needs input>
    
    <one-paragraph: root cause + concrete fix (path:line) OR reason it's a flake OR what input is needed>

Then list the files you modified:

    Modified:
      <path>
      <path>
    
    Run `/make-commits` to split these into logical commits. For flakes, run `gh run rerun <id>`.

Nothing else after that.

## Guardrails

- **Do not commit, push, or stage.** Leave changes in the worktree for `/make-commits`.
- **Do not retry flakes automatically.** Surface them; the user decides.
- **Do not silence failures.** Adding `# noqa`, `# type: ignore`, `xfail`, or `.skip` to make a check pass is only acceptable when the underlying behavior is correct and the tool is wrong — and even then, requires explicit user approval first.
- **Do not edit CI configuration to bypass a check** without explicit user approval — that's a separate decision, not part of "address failures."
- **Do not invent fixes for failures you couldn't reproduce or fully understand.** Surface and ask.
- **Do not widen scope.** If a fix tempts you into refactoring, surface the temptation to the user and ask.
- **Don't claim a check is fixed without local verification** (or, when verification isn't possible, an explicit note that the fix is log-driven only).
