---
name: loop-revise
description: Critically self-review a just-shipped change, drive every review finding to resolution, then confirm the result is still green. Runs a fanned-out cold review, addresses findings, and re-reviews each round's delta until it converges, then closes with a final full-verify gate. Orchestrates /review-diff, /address-review, and the repo's verify skill when installed; falls back inline when they aren't. Optional argument is a PR number/URL or a diff range; defaults to the open PR for the current branch. Add `e2e` to include the end-to-end suite in the verify gates, `no-commit` to keep every change uncommitted, and `lean` / `thorough` to select how hard the loop works. Use when the user says "/loop-revise", "review and fix what I just shipped", or as the revision phase of /ship.
---

Take a change (usually committed and pushed as a PR) and drive it to a **reviewed, resolved, verified-green** state. This is the **review → address findings → re-review** loop, run to convergence and capped with a final verify gate. It's an orchestrator: each sub-step has a dedicated skill; when that skill is installed, invoke it and treat it as authoritative; when it isn't, do the step inline following the principles named here. Never duplicate a delegated skill's work — call it, read its output, move on.

`ARGUMENTS` is optional and names the review target:

- A **PR number or URL** → review the PR.
- A **diff range** `<target> [<base>]`, or `staged` / `unstaged` → review a local diff.
- **Empty** → default to the open PR for the current branch (`gh pr view --json number,url,state`); if there's no open PR, the whole branch against its base.

Three kinds of **reserved directive token** are recognized anywhere in `ARGUMENTS`, case-insensitively, and stripped *before* interpreting the remainder as a target — otherwise `<PR> e2e` would mis-parse as a diff range with `base=e2e`. If only directives remain, fall through to the empty-arg default target.

- `e2e` — forward to `/verify-impl` in every verify gate below.
- `no-commit` — keep every change uncommitted; see **No-commit mode**.
- `lean` / `thorough` — the review profile below.

State a caller hands down in the invocation prose — a plan path, a decision log, settled decisions, the branch and base, its last verify result — is context, not an argument.

Invoking `/loop-revise` (directly or via `/ship`) authorizes the whole loop, including the commits and pushes that addressing findings produces, **and the review subagents of steps 1 and 2** — a default that withholds subagents "unless the user asks" is satisfied by the invocation itself. It authorizes those reviews, not delegation generally; an instruction forbidding subagents outright still wins and is reported per step 1. Do **not** re-confirm each round. Do halt and surface whenever a step fails, is ambiguous, or wants to widen scope beyond resolving the findings.

**Never end a turn mid-loop.** You are done only once you have emitted the step 4 report, or an explicit halt naming its reason — step 4 lists the kinds. A green verify is a gate result, not an endpoint; if you are about to stop and can name neither, you are still mid-loop, so continue.

## Review profile

`lean` and `thorough` set how far the loop goes. This table is the whole rule; the steps below refer back to it rather than restating it.

| | `lean` | `thorough` |
| --- | --- | --- |
| Round 1 | fanned-out cold review | fanned-out cold review |
| Delta round | after a round with material fixes | after a round with material fixes |
| Converged when | a round (round 1 or delta) leaves no material finding unresolved | that, then one final full cold pass leaves none — skipped when round 1 itself was clean |
| Closing full verify | only if code changed since the last full green | always |

A material finding is resolved once fixed or pushed back with reasoning. A material finding in the thorough final pass is addressed, then followed by a delta round and another full pass. Both profiles usually finish in two or three rounds.

An explicit token wins; otherwise `lean` on Claude Opus 5 or newer, `thorough` otherwise — including when the model can't be determined.

## Step 1 — Round 1: fanned-out cold review

Review the target **critically and with fresh eyes**; the goal is to catch what the author (you) is biased not to see, across every dimension in one round.

**Prepare** before spawning anything:

1. **Resolve the base once.** An explicit base in `ARGUMENTS` wins. With a PR, read `gh pr view --json baseRefName,baseRefOid,url`, fetch `baseRefName` from the remote whose `git remote -v` URL contains the `owner/repo` in the PR URL — or straight from `https://github.com/<owner>/<repo>.git` when none does — and use the fetched SHA. Without a PR, fetch the remote default branch. If the fetch fails, fall back to `baseRefOid` when present locally, else the local ref, and note it on `Fallbacks`.
2. **Check out the PR head once** (PR target): the current branch must be the PR's `headRefName`, with HEAD at or ahead of `headRefOid`. Otherwise run `gh pr checkout <N>` on a clean tree, or halt when the tree is dirty.
3. **Start the decision log** — a file outside the worktree (scratchpad or `mktemp -d`), seeded from the `## Decision log` section of a caller-supplied plan, plus the user's settled decisions, each with its reason. Every file this loop creates lives outside the worktree, so no review, hook, or commit picks it up.
4. **Take snapshot 0** of the reviewed state (see **Snapshots**), with parent `HEAD`.

**Fan out.** Spawn cold reviewer subagents in parallel, each with one focus: *Correctness*, *Design*, *Tests and docs* — or two, *Correctness* and *Design + Tests and docs*, for a target under ~500 lines and ~10 files. Each runs `/review-diff` over the whole target, read-only, in the target's mode: a PR or the empty default → `all <resolved-base>`; a range → that range with the resolved base; `staged` / `unstaged` → that mode. `/review-diff` rather than `/review-pr`, because parallel `gh pr checkout` runs race on the git lock and move HEAD under each other.

**Brief** every reviewer with exactly:

- the target, its mode, and the resolved base;
- the change's stated purpose — the PR summary or the commit subjects — and nothing of the author's list of intended changes, which anchors the reviewer to verifying it;
- the decision log file;
- the classes of issue the user has caught by hand before, from memory or feedback files when present;
- its focus, and the exhaustiveness bar: the review skill's inventory sweep, every item accounted for.

Merge the reviews into one numbered list, deduping findings that name the same defect and keeping each `material` / `optional` tag.

If you can't delegate — the harness has no subagents, or a standing instruction forbids them — run one inline pass per focus, sequentially, and record which on the report's `Fallbacks` line; a permission conflict is the user's to resolve, not yours to settle silently. If `/review-diff` isn't installed, review inline against the same three groups — no padding, no invented findings.

## Step 2 — Address findings and re-review the delta (loop)

If no material finding is open, fold in or push back on any optional ones, re-verify if anything changed, and go to step 3.

Otherwise, work the findings:

- If `/address-review` is available, **invoke it** with the merged findings — under `no-commit`, stating that it is addressing on top of existing uncommitted work. It evaluates each finding (accept / push back / clarify with reasoning), implements the accepted ones with its consequence sweep, and leaves changes unstaged. Honor its push-backs — a finding you genuinely disagree with stays unaddressed, with the reasoning recorded.
- Otherwise address them inline with the same discipline, including the consequence sweep: after each fix, read every reference to what it touched — strings, logs, docstrings, fakes, tests, docs, test layout, defaults — and run any new doc example through its validation.
- Optional findings are folded in or pushed back in the same round; they never earn a round of their own.
- Format only through the repo's pinned hooks, on the files you changed — a different local formatter version run over whole directories reformats unrelated files.
- A finding that reverses a plan or user decision in the log stays unapplied: continue with the other findings, count it as resolved for convergence, and list it on the report's `Decisions for user` line. A reviewer re-raising one of this loop's own push-backs with a new argument is evaluated like any other finding.

After changes are made:

1. **Re-verify** the affected scope: from the repo root, `pre-commit run --files <list>` where the list is `git diff --name-only HEAD` plus `git ls-files --others --exclude-standard` — only when the list is non-empty, since an empty `--files` makes pre-commit stash unstaged changes — plus the relevant tests; or `/verify-impl`, forwarding `e2e` when given. Fix and repeat until it passes.
2. **Commit** the fixes with `/make-commits` (or inline following its principles) and **push** — this updates the open PR when there is one. Skip under `no-commit`.
3. **Log** each push-back and each accepted finding that changed an interface, with its reason, in the decision log.
4. **Snapshot** the round's end state (parent: the previous snapshot).
5. **Delta round**, per the profile: one cold reviewer subagent runs `/review-diff <this snapshot> <previous snapshot>` with the resolved base already settled (no fetch), briefed with the previous round's findings and their resolutions to confirm each fix holds, the instruction to read the blast radius of every touched symbol, and the decision log. Its findings re-enter this step.

Loop until the review **converges** per the profile — no hard round cap. Each round must fold in the previous round's findings, so the loop only continues while reviews keep surfacing genuinely new material problems. A material finding in a delta round that isn't a consequence of the previous round's fixes shows a gap in the round-1 brief; record it for the report's `Brief gaps` line. If the loop is **thrashing** — a resolved finding reappears, or reviews contradict each other — **halt and surface that** rather than looping through it, under either profile.

The thorough final full pass is one unfocused cold reviewer running `/review-diff` in the round-1 mode over the whole target, briefed as in step 1.

### Snapshots

A snapshot records the worktree — committed, staged, unstaged, and untracked — as a dangling commit, through a temporary index so the real index and every ref stay untouched:

```bash
idx="$(mktemp -d)/index"    # must not exist yet: git rejects a pre-created empty file
GIT_INDEX_FILE="$idx" git add -A
tree=$(GIT_INDEX_FILE="$idx" git write-tree)
snap=$(git commit-tree "$tree" -p <parent> -m snapshot)
```

Chaining each snapshot to the previous one makes `/review-diff <snapN> <snapN-1>` exactly the round's delta, in both committed and `no-commit` modes.

### No-commit mode

Under `no-commit`: skip every commit and push; keep the index exactly as found — snapshots go through their temporary index, and the loop runs no `git add`, `git rm --cached`, `git stash`, or `git restore --staged`. The report lists files that are both staged and modified (`MM` in `git status --porcelain`) so the user can re-stage them.

## Step 3 — Final verify

After the loop settles, run the project's **full verify** as a closing hard gate — pre-commit / lint / type-check **and** the full test suite (`/verify-impl` or the repo's verify command, forwarding the `e2e` directive when it was given), since each address round only re-checked its own scope. Green → proceed to the report; red → halt and surface it verbatim (fold in and re-run a pure formatter reflow, but anything more is the user's call).

Run it per the profile's closing-verify rule: a loop that changed nothing is already covered by the gate before it, and re-running proves nothing.

## Step 4 — Report

End with a compact summary:

    Revised <target> (<profile>).
      Review: <final verdict>; <R> rounds
      Findings: <N addressed, M pushed back>
      Final verify: <commands> — passed (e2e: <ran N passed / not run — reason>)
      Brief gaps: <none | material delta-round findings that weren't fix consequences>
      Decisions for user: <none | findings that would reverse a logged plan or user decision>
      Re-stage: <MM files>                      (no-commit only)
      Fallbacks: <none | which preferred path you couldn't take, and why>

When the closing run was skipped, the `Final verify` line names the gate the verdict rests on instead — `passed at round 2; no code changed since`. A green verdict never rests on a verify that didn't happen.

If the loop halted (thrashing reviews, red final verify, a dirty tree blocking the PR checkout), report where and why instead — what's resolved, what isn't, and the exact next action the user needs to take.

## Guardrails

- **Fresh eyes, every dimension.** Round 1 fans out cold reviewers so you critique the diff, not your own rationalizations, and design gets the same depth as correctness — a fallback taken silently looks identical to one never needed.
- **Don't suppress your own review.** Findings are addressed or explicitly pushed back with reasoning — never silently dropped to reach "done".
- **Converge, don't cap.** The loop ends when a review stops finding material problems, not on a fixed round count. Surface thrashing — a resolved finding reappearing, or reviews contradicting each other — rather than looping through it.
- **Decisions hold.** A finding that reverses a logged plan or user decision goes to the user, not into the code.
- **The profile tunes effort, not rigor.** `lean` cuts repeated self-verification; it never skips a review, drops a finding, or ships past a red gate.
- **Green at the end.** The final verify is a hard gate — a red result halts and surfaces, it does not get reported as shipped.
- **Don't widen scope.** If addressing a finding tempts a refactor nobody asked for, surface it and ask.
- **Delegate, don't re-implement.** `/review-diff`, `/address-review`, `/verify-impl` are authoritative for their steps when installed; any you fell back from goes on the report's `Fallbacks` line.
