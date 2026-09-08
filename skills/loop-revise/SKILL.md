---
name: loop-revise
description: Critically self-review a just-shipped change, drive every review finding to resolution, then confirm the result is still green. Runs the review → address → re-review loop with fresh eyes until it converges, then closes with a final full-verify gate. Orchestrates /review-pr, /review-diff, /address-review, and the repo's verify skill when installed; falls back inline when they aren't. Optional argument is a PR number/URL or a diff range; defaults to the open PR for the current branch. Add `e2e` to include the end-to-end suite in the verify gates, and `lean` / `thorough` to select how hard the loop works. Use when the user says "/loop-revise", "review and fix what I just shipped", or as the revision phase of /ship.
---

Take a change that's already committed (and usually pushed as a PR) and drive it to a **reviewed, resolved, verified-green** state. This is the **self-review → address findings → re-review** loop, run to convergence and capped with a final verify gate. It's an orchestrator: each sub-step has a dedicated skill; when that skill is installed, invoke it and treat it as authoritative; when it isn't, do the step inline following the principles named here. Never duplicate a delegated skill's work — call it, read its output, move on.

`ARGUMENTS` is optional and names the review target:

- A **PR number or URL** → review the PR.
- A **diff range** `<target> [<base>]`, or `staged` / `unstaged` → review a local diff.
- **Empty** → default to the open PR for the current branch (`gh pr view --json number,url,state`); if there's no open PR, fall back to the local diff `HEAD..<base>` (base from `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `main`).

`e2e` is a **reserved directive token**: recognize it anywhere in `ARGUMENTS` and strip it *before* interpreting the remainder as a target — otherwise `<PR> e2e` would mis-parse as a diff range with `base=e2e`. When present, forward `e2e` to `/verify-impl` in both gates below; if it's the only token, fall through to the empty-arg default target.

Invoking `/loop-revise` (directly or via `/ship`) authorizes the whole loop, including the commits and pushes that addressing findings produces, **and the step 1 review subagent** — a default that withholds subagents "unless the user asks" is satisfied by the invocation itself. It authorizes that review, not delegation generally; an instruction forbidding subagents outright still wins and is reported per step 1. Do **not** re-confirm each round. Do halt and surface whenever a step fails, is ambiguous, or wants to widen scope beyond resolving the findings.

**Never end a turn mid-loop.** You are done only once you have emitted the step 4 report, or an explicit halt naming its reason — step 4 lists the kinds. A green verify is a gate result, not an endpoint; if you are about to stop and can name neither, you are still mid-loop, so continue.

## Review profile

`lean` and `thorough` are **reserved directive tokens** — recognize either anywhere in `ARGUMENTS`, case-insensitively, and strip it before interpreting the remainder as a target. This table is the whole rule; the steps below refer back to it rather than restating it.

| | `lean` | `thorough` |
| --- | --- | --- |
| Converged when | first review with no material findings | that, or two consecutive rounds surfacing nothing new |
| Re-review after addressing | only after a change beyond a formatter reflow | every round |
| Cold subagent, where available | one, for the initial review | one per round |
| Closing full verify | only if code changed since the last full green | always |

An explicit token wins; otherwise `lean` on Claude Opus 5 or newer, `thorough` otherwise — including when the model can't be determined.

## Step 1 — Critical self-review

Review the target **critically and with fresh eyes**. The goal is to catch what the author (you) is biased not to see.

- **Prefer a subagent.** If your harness can spawn a sub-agent with its own context, delegate the review to one so it reads the diff cold rather than reusing your justifications. Instruct it to run `/review-pr <N>` (or `/review-diff <target> <base>` when the PR isn't reviewable yet) and return the structured verdict + findings. If you can't delegate — the harness has no subagents, or a standing instruction forbids them — review inline and record which on the report's `Fallbacks` line; a permission conflict is the user's to resolve, not yours to settle silently. The profile sets how many rounds get one — one cold read is what removes author bias, and repeating it doesn't remove it twice.
- Use `/review-pr` (PR is open) when available; fall back to `/review-diff <target> <base>` for a local range review. If neither skill is installed, review inline against correctness, project coding conventions, and other concrete issues — no padding, no invented findings.

Capture the verdict and the per-finding list verbatim.

## Step 2 — Address findings (loop)

If the review verdict is **clean** ("Ready to merge" / "Looks good") with no actionable findings, skip to step 3.

Otherwise, work the findings:

- If `/address-review` is available, **invoke it** with the review text. It evaluates each finding (accept / push back / clarify with reasoning), implements the accepted ones, and leaves changes staged. Honor its push-backs — a finding you genuinely disagree with stays unaddressed, with the reasoning recorded.
- Otherwise address them inline with the same discipline: fix what's genuinely right, push back with reasoning on what isn't, don't widen scope.

After changes are made:

1. **Re-verify** the affected scope (relevant tests/lint, or the full suite if changes were broad) with `/verify-impl` or the repo's verify command — forwarding the `e2e` directive when it was given; fix and repeat until it passes before committing.
2. **Commit** the fixes with `/make-commits` (or inline following its principles) and **push** — this updates the open PR when there is one.
3. **Re-review** (step 1) to confirm the findings are resolved and nothing regressed, per the profile's re-review rule — a round that changed nothing substantive has nothing new to review.

Loop until the review **converges** — no hard round cap; the profile's convergence rule says when. Each round must fold in the previous round's findings, so the loop only continues while reviews keep surfacing genuinely new material problems. Genuine disagreements (push-backs) don't count as unresolved; record them and move on. If the loop is **thrashing** — a resolved finding reappears, or reviews contradict each other — **halt and surface that** rather than looping through it, under either profile.

## Step 3 — Final verify

After the loop settles, run the project's **full verify** as a closing hard gate — pre-commit / lint / type-check **and** the full test suite (`/verify-impl` or the repo's verify command, forwarding the `e2e` directive when it was given), since each address round only re-checked its own scope. Green → proceed to the report; red → halt and surface it verbatim (fold in and re-run a pure formatter reflow, but anything more is the user's call).

Run it per the profile's closing-verify rule: a loop that changed nothing is already covered by the gate before it, and re-running proves nothing.

## Step 4 — Report

End with a compact summary:

    Revised <target> (<profile>).
      Review: <final verdict>
      Findings: <N addressed, M pushed back>
      Final verify: <commands> — passed (e2e: <ran N passed / not run — reason>)
      Fallbacks: <none | which preferred path you couldn't take, and why>

When the closing run was skipped, the `Final verify` line names the gate the verdict rests on instead — `passed at round 2; no code changed since`. A green verdict never rests on a verify that didn't happen.

If the loop halted (thrashing reviews, red final verify), report where and why instead — what's resolved, what isn't, and the exact next action the user needs to take.

## Guardrails

- **Fresh eyes.** Prefer a cold-context subagent for the review so you critique the diff, not your own rationalizations — a fallback taken silently looks identical to one never needed.
- **Don't suppress your own review.** Findings are addressed or explicitly pushed back with reasoning — never silently dropped to reach "done".
- **Converge, don't cap.** The loop ends when a review stops finding material problems, not on a fixed round count. Surface thrashing — a resolved finding reappearing, or reviews contradicting each other — rather than looping through it.
- **The profile tunes effort, not rigor.** `lean` cuts repeated self-verification; it never skips a review, drops a finding, or ships past a red gate.
- **Green at the end.** The final verify is a hard gate — a red result halts and surfaces, it does not get reported as shipped.
- **Don't widen scope.** If addressing a finding tempts a refactor nobody asked for, surface it and ask.
- **Delegate, don't re-implement.** `/review-pr`, `/review-diff`, `/address-review`, `/verify-impl` are authoritative for their steps when installed; any you fell back from goes on the report's `Fallbacks` line.
