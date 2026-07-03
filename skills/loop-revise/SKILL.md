---
name: loop-revise
description: Critically self-review a just-shipped change, drive every review finding to resolution, then confirm the result is still green. Runs the review → address → re-review loop with fresh eyes until it converges, then closes with a final full-verify gate. Orchestrates /review-pr, /review-diff, /address-review, and the repo's verify skill when installed; falls back inline when they aren't. Optional argument is a PR number/URL or a diff range; defaults to the open PR for the current branch. Add `e2e` to include the end-to-end suite in the verify gates. Use when the user says "/loop-revise", "review and fix what I just shipped", or as the revision phase of /ship.
---

Take a change that's already committed (and usually pushed as a PR) and drive it to a **reviewed, resolved, verified-green** state. This is the **self-review → address findings → re-review** loop, run to convergence and capped with a final verify gate. It's an orchestrator: each sub-step has a dedicated skill; when that skill is installed, invoke it and treat it as authoritative; when it isn't, do the step inline following the principles named here. Never duplicate a delegated skill's work — call it, read its output, move on.

`ARGUMENTS` is optional and names the review target:

- A **PR number or URL** → review the PR.
- A **diff range** `<target> [<base>]`, or `staged` / `unstaged` → review a local diff.
- **Empty** → default to the open PR for the current branch (`gh pr view --json number,url,state`); if there's no open PR, fall back to the local diff `HEAD..<base>` (base from `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, else `main`).

`e2e` is a **reserved directive token**: recognize it anywhere in `ARGUMENTS` and strip it *before* interpreting the remainder as a target — otherwise `<PR> e2e` would mis-parse as a diff range with `base=e2e`. When present, forward `e2e` to `/verify-impl` in both gates below; if it's the only token, fall through to the empty-arg default target.

Invoking `/loop-revise` (directly or via `/ship`) authorizes the whole loop, including the commits and pushes that addressing findings produces. Do **not** re-confirm each round. Do halt and surface whenever a step fails, is ambiguous, or wants to widen scope beyond resolving the findings.

## Step 1 — Critical self-review

Review the target **critically and with fresh eyes**. The goal is to catch what the author (you) is biased not to see.

- **Prefer a subagent.** If your harness can spawn a sub-agent with its own context, delegate the review to one so it reads the diff cold rather than reusing your justifications. Instruct it to run `/review-pr <N>` (or `/review-diff <target> <base>` when the PR isn't reviewable yet) and return the structured verdict + findings. If no subagent capability exists, do the review inline.
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
3. **Re-review** once more (step 1) to confirm the findings are resolved and nothing regressed.

Loop until the review **converges** — no hard round cap. **Converged** when a review returns no material findings, or two consecutive rounds surface nothing new. Each round must fold in the previous round's findings, so the loop only continues while reviews keep surfacing genuinely new material problems — a clean review ends it. Genuine disagreements (push-backs) don't count as unresolved; record them and move on. If the loop is **thrashing** — a resolved finding reappears, or reviews contradict each other — **halt and surface that** rather than looping through it.

## Step 3 — Final verify

After the loop settles, run the project's **full verify once more** as a closing hard gate — pre-commit / lint / type-check **and** the full test suite (`/verify-impl` or the repo's verify command, forwarding the `e2e` directive when it was given), since each address round only re-checked its own scope. Green → proceed to the report; red → halt and surface it verbatim (fold in and re-run a pure formatter reflow, but anything more is the user's call).

## Step 4 — Report

End with a compact summary:

    Revised <target>.
      Review: <final verdict>
      Findings: <N addressed, M pushed back>
      Final verify: <commands> — passed (e2e: <ran N passed / not run — reason>)

If the loop halted (thrashing reviews, red final verify), report where and why instead — what's resolved, what isn't, and the exact next action the user needs to take.

## Guardrails

- **Fresh eyes.** Prefer a cold-context subagent for the review so you critique the diff, not your own rationalizations.
- **Don't suppress your own review.** Findings are addressed or explicitly pushed back with reasoning — never silently dropped to reach "done".
- **Converge, don't cap.** The loop ends when a review stops finding material problems (or two rounds surface nothing new), not on a fixed round count. Surface thrashing — a resolved finding reappearing, or reviews contradicting each other — rather than looping through it.
- **Green at the end.** The final verify is a hard gate — a red result halts and surfaces, it does not get reported as shipped.
- **Don't widen scope.** If addressing a finding tempts a refactor nobody asked for, surface it and ask.
- **Delegate, don't re-implement.** `/review-pr`, `/review-diff`, `/address-review`, `/verify-impl` are authoritative for their steps when installed.
