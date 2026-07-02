# claude-skills

A small collection of portable **agent skills** for everyday development workflows — project setup, git, PR, and review. Each skill is a `SKILL.md` with YAML frontmatter (`name`, `description`) and a step-by-step procedure the agent follows when the skill is invoked; larger skills add a `references/` directory that the `SKILL.md` routes to for detail.

The format follows the emerging cross-agent convention also used by [`AGENTS.md`](https://agents.md): a plain markdown file with a short frontmatter header and natural-language instructions. Skills here have been tested with **Claude Code**, but the contents are agent-neutral — Codex, OpenCode, Cursor, Aider, and other agents that load markdown instructions / custom commands / prompt libraries can use the same files (sometimes with a thin per-agent loader).

## Skills

| Skill | Purpose |
| --- | --- |
| [`init-python-project`](init-python-project/SKILL.md) | Scaffold a new Python project — or align an existing one — onto a uv + src-layout + pre-commit + pytest baseline, surfacing the few real choices (workspace, version source, async, CLI, security tier) as decisions. |
| [`make-commits`](make-commits/SKILL.md) | Split staged + unstaged changes into logical commits matching the repo's existing style. Verifies author, honors DCO signoff, pauses on non-trivial pre-commit failures. |
| [`create-pr`](create-pr/SKILL.md) | Open a PR that mirrors the host repo's title prefix, body structure, and detail level by inspecting recent merged PRs. Supports `draft`. |
| [`rebase-main`](rebase-main/SKILL.md) | Rebase the current branch onto the latest base, auto-resolve trivial plumbing conflicts (lockfiles, generated files), surface real semantic conflicts, re-run verify. |
| [`address-ci-failures`](address-ci-failures/SKILL.md) | Pull failing CI logs (`gh pr checks` / `gh run view`), classify failures (lint / type / test / build / infra-flake), reproduce locally, fix in batch. Leaves changes staged for `make-commits`. |
| [`address-review`](address-review/SKILL.md) | Work through reviewer feedback systematically — accept or push back per finding with reasoning, implement accepted ones, draft a per-finding reply. |
| [`verify-impl`](verify-impl/SKILL.md) | Run a project's checks as a pre-push / pre-PR gate — formatting, lint, types, tests — via the repo's own declared command, falling back to a per-language toolchain (`references/<lang>.md`; Python today). Reports a green/red verdict; surfaces failures, doesn't fix. |
| [`review-diff`](review-diff/SKILL.md) | Critical review of a local diff (staged / unstaged / `<target> [<base>]` range). Focuses on correctness, style, and other concrete issues; ends with a ship/iterate verdict. |
| [`review-pr`](review-pr/SKILL.md) | Critical review of a PR (number, URL, or current branch). Checks out the PR locally, reads description or infers intent, ends with a merge verdict. |
| [`memory-audit`](memory-audit/SKILL.md) | Audit the shared cross-workspace memory store for stale, duplicate, and contradicting entries. Drafts specific edits and asks for batch approval before applying. |
| [`ship`](ship/SKILL.md) | End-to-end release: verify (pre-commit + tests) → commit → push → open PR → critical self-review → address findings. Orchestrates the other skills when installed, falls back to inline otherwise. Supports `draft`. |
| [`loop-plan`](loop-plan/SKILL.md) | Iterate a request into a converged, written plan via a fresh-context review→revise loop (runs until reviews stop finding material issues). Any request type; autonomous, no plan mode, no approval gate. |
| [`loop-dev`](loop-dev/SKILL.md) | Full autonomous dev loop: `loop-plan` → branch → implement (with `make-commits`) → verify to green → `ship`. Branches on code vs. document deliverable; right-sizes the endpoint (PR / local branch / leave-as-is). |

## Typical flows

- **New project:** `init-python-project` (scaffold the baseline, then verify)
- **Commit → PR:** `make-commits` → `create-pr`
- **CI red on a PR:** `address-ci-failures` → `make-commits`
- **Reviewer left comments:** `address-review` → `make-commits`
- **Behind on main:** `rebase-main`
- **Green before pushing:** `verify-impl` (checks + tests) then `review-diff`
- **Self-review before pushing:** `review-diff` (worktree) or `review-pr` (after push)
- **Whole branch out the door:** `ship` (runs the verify → commit → push → PR → self-review chain end to end)
- **Request → shipped, hands-off:** `loop-dev` (plans via `loop-plan`, then branch → implement → verify → `ship`)

## Install

The right install path depends on your agent — each one looks in a different place for custom skills / commands / prompts. Common patterns:

```bash
# Claude Code — user scope (every project) or project scope
ln -s "$PWD"/make-commits ~/.claude/skills/make-commits
ln -s "$PWD"/make-commits .claude/skills/make-commits

# Codex, OpenCode, and other agents following the AGENTS.md convention
ln -s "$PWD"/make-commits ~/.agents/skills/make-commits        # user scope
ln -s "$PWD"/make-commits .agents/skills/make-commits          # project scope
```

Once installed, invoke either by slash command (`/<skill-name>`) on agents that support it, or by describing the task in plain language — agents will match against each skill's `description` field.

Skills are intentionally written as **prose procedures**, not code — they describe what the agent should read, decide, and do, in the order it should do them. That makes them portable across agents and easy to adapt: fork a `SKILL.md`, tweak the steps, drop it into your own workflow.

## Conventions across skills

- **Read before acting.** Every skill starts by surveying repo state (`git status`, recent commits, project conventions in `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`).
- **Stage, don't commit.** `address-ci-failures` and `address-review` leave changes in the worktree and hand off to `make-commits`.
- **Render, don't post.** `address-review` drafts replies in chat; the user posts them.
- **Surface, don't bypass.** No `--no-verify`, no auto-`--amend`, no auto-stash, no `--force` without `--with-lease`. When a step is ambiguous, the skill stops and asks.
- **No invented findings.** Reviews are short when the diff is clean; audits are silent when memory is healthy.
