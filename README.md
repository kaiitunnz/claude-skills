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
| [`write-prd`](skills/write-prd/SKILL.md) | Turn a rough product idea or feature request into a concrete product requirements document (PRD), defining users, prioritized scope, requirements, success metrics, and launch considerations before technical design or implementation. |
| [`write-rfc`](skills/write-rfc/SKILL.md) | Expand a rough feature, architecture, product, process, or technical request into a concrete RFC/design proposal that enables informed technical decisions. |
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
- **Product idea → technical design:** `write-prd` → `write-rfc` (align product scope and success measures, then turn the approved product direction into a technical design as needed)
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

Third-party skills (see below) are only available once their submodule is checked out, so on a fresh clone initialize submodules first:

```bash
git clone --recurse-submodules <this-repo>        # or, after a plain clone:
git submodule update --init
```

Once installed, invoke a skill by slash command (`/<skill-name>`) on agents that support it, or by describing the task in plain language — agents match against each skill's `description` field.

## Third-party sources

Alongside the first-party skills under [`skills/`](skills/), this repo can vendor skills from other authors as **git submodules** under [`3rdparty/`](3rdparty/). A submodule pins an exact upstream commit, so imports are reproducible and updates are deliberate; the upstream `LICENSE` travels with the code rather than being copied.

Each source has a sibling `3rdparty/<vendor>.manifest` — a plain list of skill directories (relative to the submodule) to install. Curating that list is deliberate: upstream repos often ship deprecated or work-in-progress skills we don't want auto-installed, so only skills the manifest lists are installed by default. `install.sh` installs first-party and listed third-party skills together under their basename; on a name clash the first-party skill wins (and the installer warns).

`./install.sh --list` shows two groups: the skills installed by default (each with its source), and **every third-party skill in the submodules that no manifest lists**, shown by its exact path. Those aren't installed by default, but you can install any of them by naming that path:

```bash
./install.sh --list                                             # default skills, then the rest by path
./install.sh 3rdparty/mattpocock/skills/engineering/tdd         # install one by its path
./install.sh --uninstall 3rdparty/mattpocock/skills/engineering/tdd
```

A positional argument with no slash is a skill **name**; one containing a slash is a **path** to a skill directory (which must live under `skills/` or `3rdparty/` and contain a `SKILL.md`). If a path's skill name collides with one already installed, `install.sh` refuses rather than silently shadowing it — pass `--force` to install it in the other's place. To install a skill for everyone by default, add its path to the manifest instead.

### Vendored sources

| Source | Upstream | License | Skills exposed |
| --- | --- | --- | --- |
| [`3rdparty/mattpocock`](3rdparty/mattpocock) | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT © Matt Pocock | `setup-matt-pocock-skills`, `handoff`, `teach`, `grill-me`, `grilling` (see [`3rdparty/mattpocock.manifest`](3rdparty/mattpocock.manifest)) |

### Updating a vendored source

```bash
git submodule update --remote 3rdparty/mattpocock      # pull the latest upstream commit
./install.sh --list                                    # review what the manifest now resolves
#   edit 3rdparty/mattpocock.manifest to adopt/drop skills as needed
git add 3rdparty/mattpocock 3rdparty/mattpocock.manifest
git commit -m "Bump mattpocock skills"
```

To adopt more skills from an existing source, add their paths to the manifest (`ls 3rdparty/mattpocock/skills/*/` shows the upstream categories). To vendor a new source, `git submodule add <url> 3rdparty/<vendor>` and create `3rdparty/<vendor>.manifest`.

Skills are intentionally written as **prose procedures**, not code — they describe what the agent should read, decide, and do, in the order it should do them. That makes them portable across agents and easy to adapt: fork a `SKILL.md`, tweak the steps, drop it into your own workflow.

## Conventions across skills

- **Read before acting.** Every skill starts by surveying repo state (`git status`, recent commits, project conventions in `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`).
- **Stage, don't commit.** `address-ci-failures` and `address-review` leave changes in the worktree and hand off to `make-commits`.
- **Render, don't post.** `address-review` drafts replies in chat; the user posts them.
- **Surface, don't bypass.** No `--no-verify`, no auto-`--amend`, no auto-stash, no `--force` without `--with-lease`. When a step is ambiguous, the skill stops and asks.
- **No invented findings.** Reviews are short when the diff is clean; audits are silent when memory is healthy.
