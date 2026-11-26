---
name: loop-revise
description: Critically self-review a just-shipped change, drive every review finding to resolution, then confirm the result is still green. Runs a cold review, addresses findings, and re-reviews each round's fixes until it converges, then closes with a final full-verify gate. Orchestrates /review-diff, /address-review, and the repo's verify skill when installed; falls back inline when they aren't. Optional argument is a PR number/URL or a diff range; defaults to the open PR for the current branch. Add `e2e` to include the end-to-end suite in the verify gates, `no-commit` to keep every change uncommitted, and `lean` / `thorough` to select how hard the loop works. Use when the user says "/loop-revise", "review and fix what I just shipped", or as the revision phase of /ship-pr.
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

Invoking `/loop-revise` (directly or via `/ship-pr`) authorizes the whole loop, including the commits and pushes that addressing findings produces, **and the review subagents of steps 1 and 2** — a default that withholds subagents "unless the user asks" is satisfied by the invocation itself. It authorizes those reviews, not delegation generally; an instruction forbidding subagents outright still wins and is reported per step 1. Do **not** re-confirm each round. Do halt and surface whenever a step fails, is ambiguous, or wants to widen scope beyond resolving the findings.

**Never end a turn mid-loop.** You are done only once you have emitted the step 4 report, or an explicit halt naming its reason — step 4 lists the kinds. A green verify is a gate result, not an endpoint; if you are about to stop and can name neither, you are still mid-loop, so continue.

## Review profile

`lean` and `thorough` set how far the loop goes. This table is the whole rule; the steps below refer back to it rather than restating it.

| | `lean` | `thorough` |
| --- | --- | --- |
| Round 1 | cold review | cold review |
| Delta round | after a round with material fixes | after a round with material fixes |
| Converged when | a round produces no material fix — none found, or each pushed back or left for the user | that, once the latest full-target review (round 1 or a final pass) found no material finding; otherwise a final full cold pass runs first |
| Closing full verify | only if code changed since the last full green | always |

Both profiles usually finish in two or three rounds.

An explicit token wins; otherwise `lean` on Claude Opus 5 or newer, or on Claude Sonnet 5.5 or newer, `thorough` otherwise — including when the model can't be determined.

## Step 1 — Round 1: cold review

Review the target **critically and with fresh eyes**; the goal is to catch what the author (you) is biased not to see, across every dimension in one round.

**Prepare** before spawning anything:

1. **Resolve the base once.** An explicit base in `ARGUMENTS` wins. With a PR, read `gh pr view --json baseRefName,baseRefOid,headRefName,headRefOid,url`, fetch `baseRefName` from the remote whose `git remote -v` URL contains the `owner/repo` in the PR URL — or straight from `https://github.com/<owner>/<repo>.git` when none does — and use the fetched SHA. Without a PR, fetch the remote default branch. If the fetch fails, fall back to `baseRefOid` when present locally, else the local ref, and note it on `Fallbacks`.
2. **Check out the PR head once** (PR target): the current branch must be the PR's `headRefName`, with HEAD at or ahead of `headRefOid`. Otherwise run `gh pr checkout <N>` on a clean tree, or halt when the tree is dirty.
3. **Start the decision log** — a file outside the worktree (scratchpad or `mktemp -d`), seeded from the Decision log section of a caller-supplied plan, plus the user's settled decisions, each with its reason and whether the user or the plan made it.
4. **Under `no-commit`, take snapshot 0** (see **No-commit mode**), with parent `HEAD`.

Every file this loop creates lives outside the worktree, so no review, hook, or commit picks it up.

**Review.** Spawn one cold reviewer subagent running `/review-diff` over the whole target, read-only, in the target's mode: a PR or the empty default → `HEAD <resolved-base>` (under `no-commit`, `all <resolved-base>`); a range → that range with the resolved base; `staged` / `unstaged` → that mode. For a large target (≥ ~500 lines or ≥ ~10 files), spawn three in parallel instead, one per focus — *Correctness*, *Design*, *Tests and docs* — and merge their findings into one numbered list, deduping ones that name the same defect and keeping each `material` / `optional` tag. Reviewers use `/review-diff` rather than `/review-pr`, which checks the PR out and would race its siblings on the git lock.

**Brief** every reviewer with exactly:

- the target, its mode, and the resolved base;
- the change's stated purpose — the PR summary or the commit subjects — and nothing of the author's list of intended changes, which anchors the reviewer to verifying it;
- the decision log file;
- the classes of issue the user has caught by hand before, from memory or feedback files when present;
- its focus, when fanned out.

If you can't delegate — the harness has no subagents, or a standing instruction forbids them — run each review this loop specifies as one inline pass, and record which on the report's `Fallbacks` line; a permission conflict is the user's to resolve, not yours to settle silently. If `/review-diff` isn't installed, review inline against the same three groups — no padding, no invented findings.

## Step 2 — Address findings and re-review (loop)

Each review's findings come here — round 1's, then each later round's.

Work the findings:

- If `/address-review` is available, **invoke it** with the findings — under `no-commit`, stating that it is addressing on top of existing uncommitted work. It evaluates each finding (accept / push back / clarify with reasoning), implements the accepted ones with its consequence sweep, and leaves changes unstaged. Honor its push-backs — a finding you genuinely disagree with stays unaddressed, with the reasoning recorded.
- Otherwise address them inline with the same discipline, including a consequence sweep: after each fix, read every reference to what it touched and update what it made stale.
- Optional findings are folded in or pushed back in the same round; they never earn a round of their own.
- Format only the files you changed, with the project's own pinned formatter version.
- A finding that reverses a **user** decision stays unapplied: continue with the other findings and list it on the report's `Decisions for user` line. One that reverses a **plan** decision, with a new argument against its logged reason, is evaluated like any other finding; an accepted reversal is logged and listed on `Decisions for user` as applied.

After any change, material or optional:

1. **Re-verify** the affected scope — `/verify-impl` (forwarding `e2e` when given), or inline: the project's lint, format, and type checks on the changed and untracked files plus the relevant tests. Fix and repeat until it passes.
2. **Commit** the fixes with `/make-commits` (or inline following its principles) and **push** — this updates the open PR when there is one. Skip under `no-commit`.
3. **Log** each push-back and each accepted plan-decision reversal, with its reason, in the decision log.

Then pick the next review, per the profile:

- **The round produced a material fix** → run a **delta round**: one cold reviewer runs `/review-diff HEAD <HEAD at the round's start>` (under `no-commit`, `/review-diff <this snapshot> <previous snapshot>`), briefed with the stated purpose "the round's fixes to the listed findings", the previous round's findings and resolutions to confirm each fix holds, and the decision log.
- **No material fix, `thorough`, and the latest full-target review found material findings** → run the **final full pass**: one unfocused cold reviewer running `/review-diff` in the round-1 mode over the whole target, briefed as in step 1.
- **Otherwise** → converged; go to step 3.

The next review's findings re-enter this step. Loop until converged — no hard round cap. Each round must fold in the previous round's findings, so the loop only continues while reviews keep surfacing genuinely new material problems. If the loop is **thrashing** — a resolved finding reappears, or reviews contradict each other — **halt and surface that** rather than looping through it, under either profile.

### No-commit mode

Under `no-commit`, skip every commit and push and keep the index exactly as found. The report lists files that are both staged and modified (`MM` in `git status --porcelain`) so the user can re-stage them.

With no commits to diff, delta rounds review **snapshots**: the worktree — staged, unstaged, and untracked — recorded as a dangling commit through a temporary index, so the real index and every ref stay untouched. Take one at round 1 and at the end of each round with a material fix:

```bash
idx="$(mktemp -d)/index"    # must not exist yet: git rejects a pre-created empty file
GIT_INDEX_FILE="$idx" git read-tree HEAD    # keeps tracked files that match .gitignore
GIT_INDEX_FILE="$idx" git add -A
tree=$(GIT_INDEX_FILE="$idx" git write-tree)
snap=$(git commit-tree "$tree" -p <previous snapshot, or HEAD for the first> -m snapshot)
```

Chaining each snapshot to the previous one makes `/review-diff <snapN> <snapN-1>` exactly the round's delta.

## Step 3 — Final verify

After the loop settles, run the project's **full verify** as a closing hard gate — pre-commit / lint / type-check **and** the full test suite (`/verify-impl` or the repo's verify command, forwarding the `e2e` directive when it was given), since each address round only re-checked its own scope. Green → proceed to the report; red → halt and surface it verbatim (fold in and re-run a pure formatter reflow, but anything more is the user's call).

Run it per the profile's closing-verify rule: a loop that changed nothing is already covered by the gate before it, and re-running proves nothing.

## Step 4 — Report

End with a compact summary:

    Revised <target> (<profile>).
      Review: <final verdict>; <R> rounds
      Findings: <N addressed, M pushed back>
      Final verify: <commands> — passed (e2e: <ran N passed / not run — reason>)
      Decisions for user: <none | user decisions a finding would reverse; plan decisions reversed>
      Re-stage: <MM files>                      (no-commit only)
      Fallbacks: <none | which preferred path you couldn't take, and why>

When the closing run was skipped, the `Final verify` line names the gate the verdict rests on instead — `passed at round 2; no code changed since`. A green verdict never rests on a verify that didn't happen.

If the loop halted (thrashing reviews, red final verify, a dirty tree blocking the PR checkout), report where and why instead — what's resolved, what isn't, and the exact next action the user needs to take.

## Guardrails

- **Fresh eyes, every dimension.** A cold reviewer critiques the diff, not your own rationalizations, and gives design the same depth as correctness — a fallback taken silently looks identical to one never needed.
- **Don't suppress your own review.** Findings are addressed or explicitly pushed back with reasoning — never silently dropped to reach "done".
- **Converge, don't cap.** The loop ends when a review stops finding material problems, not on a fixed round count. Surface thrashing — a resolved finding reappearing, or reviews contradicting each other — rather than looping through it.
- **User decisions hold.** A finding that reverses one goes to the user, not into the code; plan decisions yield to a better argument, reported.
- **The profile tunes effort, not rigor.** `lean` cuts repeated self-verification; it never skips a review, drops a finding, or ships past a red gate.
- **Green at the end.** The final verify is a hard gate — a red result halts and surfaces, it does not get reported as shipped.
- **Don't widen scope.** If addressing a finding tempts a refactor nobody asked for, surface it and ask.
- **Delegate, don't re-implement.** `/review-diff`, `/address-review`, `/verify-impl` are authoritative for their steps when installed; any you fell back from goes on the report's `Fallbacks` line.
