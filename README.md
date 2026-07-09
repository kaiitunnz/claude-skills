# claude-skills

A small collection of portable **agent skills** for everyday development workflows — project setup, git, PR, and review. Each skill is a `SKILL.md` with YAML frontmatter (`name`, `description`) and a step-by-step procedure the agent follows when the skill is invoked; larger skills add a `references/` directory that the `SKILL.md` routes to for detail.

The format follows the emerging cross-agent convention also used by [`AGENTS.md`](https://agents.md): a plain markdown file with a short frontmatter header and natural-language instructions. Skills here have been tested with **Claude Code**, but the contents are agent-neutral — Codex, OpenCode, Cursor, Aider, and other agents that load markdown instructions / custom commands / prompt libraries can use the same files (sometimes with a thin per-agent loader).

## Skills

| Skill | Purpose |
| --- | --- |
| [`init-python-project`](skills/init-python-project/SKILL.md) | Scaffold a new Python project — or align an existing one — onto a uv + src-layout + pre-commit + pytest baseline, surfacing the few real choices (workspace, version source, async, CLI, security tier) as decisions. |
| [`make-commits`](skills/make-commits/SKILL.md) | Split staged + unstaged changes into logical commits matching the repo's existing style. Verifies author, honors DCO signoff, pauses on non-trivial pre-commit failures. |
| [`create-pr`](skills/create-pr/SKILL.md) | Open a PR that mirrors the host repo's title prefix, body structure, and detail level by inspecting recent merged PRs. Supports `draft`. |
| [`rebase-main`](skills/rebase-main/SKILL.md) | Rebase the current branch onto the latest base, auto-resolve trivial plumbing conflicts (lockfiles, generated files), surface real semantic conflicts, re-run verify. |
| [`address-ci-failures`](skills/address-ci-failures/SKILL.md) | Pull failing CI logs (`gh pr checks` / `gh run view`), classify failures (lint / type / test / build / infra-flake), reproduce locally, fix in batch. Leaves changes staged for `make-commits`. |
| [`address-review`](skills/address-review/SKILL.md) | Work through reviewer feedback systematically — accept or push back per finding with reasoning, implement accepted ones, draft a per-finding reply. |
| [`verify-impl`](skills/verify-impl/SKILL.md) | Run a project's checks as a pre-push / pre-PR gate — formatting, lint, types, tests — via the repo's own declared command, falling back to a per-language toolchain (`references/<lang>.md`; Python today). Reports a green/red verdict; surfaces failures, doesn't fix. |
| [`review-diff`](skills/review-diff/SKILL.md) | Critical review of a local diff (staged / unstaged / `<target> [<base>]` range). Focuses on correctness, style, and other concrete issues; ends with a ship/iterate verdict. |
| [`review-pr`](skills/review-pr/SKILL.md) | Critical review of a PR (number, URL, or current branch). Checks out the PR locally, reads description or infers intent, ends with a merge verdict. |
| [`memory-audit`](skills/memory-audit/SKILL.md) | Audit the shared cross-workspace memory store for stale, duplicate, and contradicting entries. Drafts specific edits and asks for batch approval before applying. |
| [`ship`](skills/ship/SKILL.md) | End-to-end release: verify (pre-commit + tests) → commit → push → open PR → revise (self-review + address findings + final verify, via `loop-revise`). Orchestrates the other skills when installed, falls back to inline otherwise. Supports `draft`. |
| [`loop-revise`](skills/loop-revise/SKILL.md) | Critical self-review → address findings → re-review loop (runs to convergence like `loop-plan`), capped with a final full-verify gate. Targets an open PR or a local diff; the revision phase of `ship`, usable standalone. |
| [`loop-plan`](skills/loop-plan/SKILL.md) | Iterate a request into a converged, written plan via a fresh-context review→revise loop (runs until reviews stop finding material issues). Any request type; autonomous, no plan mode, no approval gate. |
| [`loop-dev`](skills/loop-dev/SKILL.md) | Full autonomous dev loop: `loop-plan` → branch → implement (with `make-commits`) → verify to green → `ship`. Branches on code vs. document deliverable; right-sizes the endpoint (PR / local branch / leave-as-is). |
| [`loop-optimize`](skills/loop-optimize/SKILL.md) | Autonomous measured-improvement loop: explore the codebase and its harness → settle goal/metrics/scope/constraints/budget → baseline → iterate hypothesis → change → validate → evaluate → keep/reject → confirm winner. Adapts to the repo's own metrics; imposes no fixed schema. Leaves the winner on a branch — doesn't ship. |
| [`babysit-prs`](skills/babysit-prs/SKILL.md) | One idempotent sweep over your open PRs — bring stale branches current, fix CI (`address-ci-failures`), address review feedback (`address-review`), re-verify, report per-PR status. Acts only on your PRs; never force-pushes, merges, or posts replies. Pair with `/loop` or `/schedule`. |

## Typical flows

- **New project:** `init-python-project` (scaffold the baseline, then verify)
- **Commit → PR:** `make-commits` → `create-pr`
- **CI red on a PR:** `address-ci-failures` → `make-commits`
- **Reviewer left comments:** `address-review` → `make-commits`
- **Behind on main:** `rebase-main`
- **Green before pushing:** `verify-impl` (checks + tests) then `review-diff`
- **Self-review before pushing:** `review-diff` (worktree) or `review-pr` (after push)
- **Whole branch out the door:** `ship` (runs the verify → commit → push → PR → `loop-revise` chain end to end)
- **Request → shipped, hands-off:** `loop-dev` (plans via `loop-plan`, then branch → implement → verify → `ship`)
- **Make it faster / better, measured:** `loop-optimize` (baseline → hypothesize → change → evaluate → keep/reject on the repo's own harness; leaves the winner on a branch for `ship`)
- **Keep open PRs green:** `/loop <interval> /babysit-prs` (recurring sweep: update branch → fix CI → address review → re-verify → report)

## Install

`install.sh` symlinks the skills under [`skills/`](skills/) into a skill directory. It defaults to `~/.agents/skills` — the cross-agent location that Codex, OpenCode, Cursor, and other `AGENTS.md`-family agents read — and can also target Claude Code's `~/.claude/skills`. Symlinks (not copies) mean one source of truth: `git pull` in this repo instantly updates every install.

```bash
./install.sh                          # all skills -> ~/.agents/skills (default)
./install.sh --both                   # -> ~/.agents/skills and ~/.claude/skills
./install.sh --claude                 # Claude Code only
./install.sh ship make-commits --both # a chosen subset
./install.sh --project --both         # project scope: ./.agents/skills, ./.claude/skills
./install.sh --target ~/some/dir      # any directory (repeatable)
./install.sh --uninstall --both       # remove this repo's symlinks
./install.sh --dry-run --both         # preview without changing anything
```

The installer is idempotent (re-running is a no-op) and safe: it never overwrites a real directory, and leaves a symlink pointing at another source untouched unless you pass `--force`. It targets macOS and Linux; run it as `./install.sh` or `bash install.sh`. See `./install.sh --help` for the full flag list, and `test/smoke.sh` for the behavior contract.

Once installed, invoke a skill by slash command (`/<skill-name>`) on agents that support it, or by describing the task in plain language — agents match against each skill's `description` field.

Skills are intentionally written as **prose procedures**, not code — they describe what the agent should read, decide, and do, in the order it should do them. That makes them portable across agents and easy to adapt: fork a `SKILL.md`, tweak the steps, drop it into your own workflow.

## Conventions across skills

- **Read before acting.** Every skill starts by surveying repo state (`git status`, recent commits, project conventions in `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`).
- **Stage, don't commit.** `address-ci-failures` and `address-review` leave changes in the worktree and hand off to `make-commits`.
- **Render, don't post.** `address-review` drafts replies in chat; the user posts them.
- **Surface, don't bypass.** No `--no-verify`, no auto-`--amend`, no auto-stash, no `--force` without `--with-lease`. When a step is ambiguous, the skill stops and asks.
- **No invented findings.** Reviews are short when the diff is clean; audits are silent when memory is healthy.
