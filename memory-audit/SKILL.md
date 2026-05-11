---
name: memory-audit
description: Audit the shared cross-workspace memory store for stale, duplicate, and contradicting entries. Verifies code references (paths, symbols, flags) against the current workspace where applicable, drafts specific edits for each finding, and asks for batch approval before applying. Use when the user says "audit my memories", "/memory-audit", or notices the memory index has grown stale.
---

Curate the shared memory store the user maintains across workspaces. Surface staleness with reasoning, propose concrete edits, get approval, apply.

## Step 1 — Resolve the store

The shared memory directory lives next to a workspace-level `AGENTS.md` and is git-synced across machines, so the absolute path is host-specific. Resolve it:

- Find the user's global agent config (Claude Code: `~/.claude/CLAUDE.md`). Read its `@`-imports.
- Follow the import that points at an `AGENTS.md` outside `~/.claude/` — that's the shared workspace.
- The memory directory is `memory/` relative to that `AGENTS.md`, with an index at `memory/MEMORY.md`.

If the path can't be resolved (no global config, no shared AGENTS.md, no memory dir), stop with: "Could not locate the shared memory store. Expected `<path>/memory/MEMORY.md`."

Record the resolved absolute path and use it for every subsequent step.

Do **not** audit `~/.claude/projects/<workspace>/memory/` — that's Claude Code's workspace-scoped auto-memory and it manages itself. Scope is shared cross-workspace only.

## Step 2 — Read the index and entries

- Read `MEMORY.md` — the flat index (one line per memory file).
- For each entry in the index, read the referenced markdown file.
- Note its frontmatter (`name`, `description`, `type`) and body.

Also list everything in the `memory/` directory (`ls memory/*.md`) and cross-check against the index — orphans in either direction are findings.

## Step 3 — Check each entry

For each memory file, evaluate against these categories of finding:

**Dead references** — a memory names a specific path, function, symbol, or flag. Verify it still exists:

- Path: `Read` the file or `ls` the directory.
- Symbol/function/flag/env var: `Grep` for it in the relevant workspace.
- If the memory's "relevant workspace" is named (e.g. "in the waypoint repo"), check there. If not, the memory is probably cross-workspace by design and a code check doesn't apply — skip the verification with a note.
- If a referenced thing is gone, the memory is stale. Propose deletion or a rewrite that drops the dead reference.

**Duplicates** — two memories cover the same ground. Look across entries for overlapping `description` lines or contradicting feedback on the same axis. Propose merging into one, with the more recent / more accurate content winning.

**Contradictions** — two memories disagree on a rule. Surface both quotes and ask the user which is current; do not auto-pick.

**Frontmatter drift** — `type` doesn't match the body (e.g. `type: user` but the body is a project status), `description` doesn't reflect the body, filename doesn't fit the type prefix (`feedback_*`, `user_*`, `project_*`, `reference_*`).

**Index hygiene** — entries in `MEMORY.md` that point at missing files, or files in `memory/` not listed in the index. Propose adding or removing the line.

**Out-of-scope content** — memories that should live in a workspace's own `AGENTS.md` instead of the cross-workspace store (e.g. "in this codebase, the architecture is X"). Propose moving — surface the destination but don't actually edit the destination file in this skill.

If the audit takes more than ~3 categories or covers a store with ≥10 entries, use **TodoWrite** with one todo per category to track progress.

## Step 4 — Draft edits

For each finding, draft the **exact** edit needed. Format:

    ### Finding #<N>: <one-line summary>
    
    **Category:** <dead reference | duplicate | contradiction | frontmatter | index | out-of-scope>
    
    **Evidence:**
    - `<file>:<line>` — <quote or summary>
    - …
    
    **Proposed edit:**
    - Delete `memory/feedback_x.md` and remove its line from `MEMORY.md`.
    - OR: Edit `memory/user_role.md` — replace `<old>` with `<new>`.
    - OR: Merge `memory/feedback_a.md` into `memory/feedback_b.md`; delete the former; update the index.
    
    **Reasoning:** <one or two sentences>

Order findings by category, severest first (contradictions → dead references → duplicates → frontmatter → index → out-of-scope).

After the list, output one consolidated prompt:

    Apply all proposed edits? (yes / individually / no)

## Step 5 — Apply

Wait for the user's answer.

- **yes** — apply all proposed edits in order. After each edit, re-read the affected file to confirm the change is what the proposal said. If the index changes, re-read it after writing.
- **individually** — walk through findings one at a time, ask `apply / skip / revise` for each, apply accordingly.
- **no** (or any other answer) — make no edits. Report that the audit is complete and unchanged.

For every applied edit:

- Use the `Edit` tool with the exact `old_string` / `new_string` from the proposal. Don't rephrase.
- For deletions, the proposal must explicitly include removing the line from `MEMORY.md` — both go together.
- For new content (e.g. merge), the agent does not introduce facts that weren't already in the originals.

## Step 6 — Final report

After applying (or skipping):

    Audited <N> entries in <path>.
    <K> findings, <M> edits applied.
    
    Edits:
    - <one line per edit>

If anything required the user's judgment but was skipped (contradictions, out-of-scope moves), list them with `Open:` prefix so they don't get lost.

## Guardrails

- **Do not edit anything in step 3 or 4** — those steps are observation and proposal only. Edits happen in step 5 after approval.
- **Do not auto-resolve contradictions.** Surface and ask.
- **Do not delete a memory whose dead reference might come back** (e.g. a feature flag that's temporarily off). When in doubt, propose a rewrite that drops the reference instead of deletion.
- **Do not edit workspace `AGENTS.md` files** or the user's global agent config. Out-of-scope moves are proposed but not executed.
- **Do not touch `~/.claude/projects/<workspace>/memory/`.** That store is out of scope.
- **Do not invent findings.** If the audit is clean, say so plainly and skip steps 4–5.
