# claude-skills

A small collection of [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) for everyday git, PR, and review workflows. Each skill is a single `SKILL.md` with a YAML frontmatter (`name`, `description`) and a step-by-step procedure Claude follows when invoked.

## Skills

| Skill | Purpose |
| --- | --- |
| [`make-commits`](make-commits/SKILL.md) | Split staged + unstaged changes into logical commits matching the repo's existing style. Verifies author, honors DCO signoff, pauses on non-trivial pre-commit failures. |
| [`create-pr`](create-pr/SKILL.md) | Open a PR that mirrors the host repo's title prefix, body structure, and detail level by inspecting recent merged PRs. Supports `draft`. |
| [`rebase-main`](rebase-main/SKILL.md) | Rebase current branch onto the latest base, auto-resolve trivial plumbing conflicts (lockfiles, generated files), surface real semantic conflicts, re-run verify. |
| [`address-ci-failures`](address-ci-failures/SKILL.md) | Pull failing CI logs (`gh pr checks` / `gh run view`), classify failures (lint / type / test / build / infra-flake), reproduce locally, fix in batch. Leaves changes staged for `make-commits`. |
| [`address-review`](address-review/SKILL.md) | Work through reviewer feedback systematically — accept or push back per finding with reasoning, implement accepted ones, draft a per-finding reply. |
| [`review-diff`](review-diff/SKILL.md) | Critical review of a local diff (staged / unstaged / `<target> [<base>]` range). Focuses on correctness, style, and other concrete issues; ends with a ship/iterate verdict. |
| [`review-pr`](review-pr/SKILL.md) | Critical review of a PR (number, URL, or current branch). Checks out the PR locally, reads description or infers intent, ends with a merge verdict. |
| [`memory-audit`](memory-audit/SKILL.md) | Audit the shared cross-workspace memory store for stale, duplicate, and contradicting entries. Drafts specific edits and asks for batch approval before applying. |

## Typical flows

- **Commit → PR:** `/make-commits` → `/create-pr`
- **CI red on a PR:** `/address-ci-failures` → `/make-commits`
- **Reviewer left comments:** `/address-review` → `/make-commits`
- **Behind on main:** `/rebase-main`
- **Self-review before pushing:** `/review-diff` (worktree) or `/review-pr` (after push)

## Install

Skills are discovered from `~/.claude/skills/` (user-scope) or `.claude/skills/` (project-scope). Either symlink or copy individual skill directories:

```bash
# User-scope (available in every project)
mkdir -p ~/.claude/skills
ln -s "$PWD"/make-commits ~/.claude/skills/make-commits

# Or project-scope (only this repo)
mkdir -p .claude/skills
ln -s "$PWD"/make-commits .claude/skills/make-commits
```

Invoke from Claude Code via `/<skill-name>` (e.g. `/make-commits`), or just describe the task in plain language — Claude will match against each skill's `description`.

## Conventions across skills

- **Read before acting.** Every skill starts by surveying repo state (`git status`, recent commits, project conventions in `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md`).
- **Stage, don't commit.** `address-ci-failures` and `address-review` leave changes in the worktree and hand off to `/make-commits`.
- **Render, don't post.** `address-review` drafts replies in chat; the user posts them.
- **Surface, don't bypass.** No `--no-verify`, no auto-`--amend`, no auto-stash, no `--force` without `--with-lease`. When a step is ambiguous, the skill stops and asks.
- **No invented findings.** Reviews are short when the diff is clean; audits are silent when memory is healthy.
