---
name: loop-dev
description: Run the full autonomous dev loop to ship a request end-to-end — plan (via /loop-plan), branch, implement with commits along the way, verify to green, then ship. Handles both code deliverables (branch → implement → verify → PR) and document deliverables (draft → revise → commit). Runs autonomously; halts only on something breaking or unresolvable. Use when the user says "/loop-dev", "build and ship this", or "take this request all the way out". Distinct from the built-in /loop interval runner.
---

Take a request from words to a shipped deliverable, autonomously. This is an **orchestrator**: plan with `/loop-plan`, then execute and release by delegating to the dedicated skills. Never re-implement a delegated skill's work — invoke it, read its output, move on.

`ARGUMENTS` is the request (any type), plus optional `draft` to pass through to PR creation. If the request is empty, use the conversation's current one; if there is none, stop and ask.

Invoking `/loop-dev` authorizes the whole pipeline — planning, branching, committing, verifying, and shipping. Do **not** re-confirm each step. Do halt and surface whenever a step fails, is ambiguous, or wants to widen scope beyond the request.

## Step 1 — Plan

Run `/loop-plan` on the request. Take its converged plan file, the deliverable type (code vs. document), the execution organization (single-context vs. workqueue crew), and any open concerns. If an open concern is genuinely blocking, halt and surface it; otherwise proceed.

## Step 2 — Branch

For a document deliverable whose location has **no git repo**, skip this step (there's nothing to branch); the draft/revise loop and file-path endpoint cover it. Otherwise:

Determine the base (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, falling back to `main`). If already on the default branch, create a feature branch off HEAD — name it per the repo's existing branch convention (check recent branches / `AGENTS.md`); never build on the default branch. If already on a suitable feature branch, stay on it.

## Step 3 — Implement (verify loop)

Execute the plan. If the plan chose a **workqueue crew**, orchestrate it via `/waypoint-workqueue` — split, dispatch, collect, merge. Otherwise implement in this context.

Commit **along the way** with `/make-commits` at each logical unit — don't accumulate one giant diff.

Then loop by deliverable type:

- **Code:** after each meaningful chunk, run `/verify-python` (or the repo's own verify command). On failure, fix and re-verify. Repeat until green. Reaching step 4 with red checks is not allowed.
- **Document:** revise against the plan's review bar (spawn a fresh-context subagent to critique the draft, then revise). No test gate applies. **Git-tracked by default** — commit drafts with `/make-commits` like any other work. If the document location has no git repo initialized, adapt: keep the draft/revise loop, skip the commit and branch steps, and report the file path as the endpoint.

Bound the fix→re-verify loop sensibly (a few rounds); if checks stay red for a reason you can't resolve, halt and surface the failure verbatim.

## Step 4 — Ship

Run `/ship` (passing `draft` through when given). It drives verify → commit → push → open PR → revise (self-review → address findings → final verify, via `/loop-revise`).

**Adjust the final deliverable to fit the work** — this is the one judgment call the skill makes autonomously:

- **Code in a shared/remote repo** → let `/ship` open (or update) the PR. Default.
- **Personal repo, doc deliverable, or no meaningful remote** → committing on the local branch may be the right endpoint; skip PR creation and report the branch instead.
- **Exploratory / not review-ready** → leave the commits on the branch (or the workspace as-is) and say so, rather than forcing a PR.
- **No git repo** (document location without git) → `/ship` doesn't apply; the endpoint is the finished file(s). Report the path.

Pick the fitting endpoint from repo context; don't ask unless the choice is genuinely ambiguous.

## Step 5 — Final report

End with a compact summary: the plan path, the branch, what was implemented, the verify result, and the endpoint (PR URL / local branch / workspace). If the pipeline halted early, report where, why, and the exact next action.

## Guardrails

- **Autonomous, halt on breakage.** No per-step confirmation; stop and surface any failure, unresolved ambiguity, or scope creep.
- **Delegate, don't re-implement.** `/loop-plan`, `/waypoint-workqueue`, `/make-commits`, `/verify-python`, `/ship` (which itself delegates the revision phase to `/loop-revise`) are authoritative for their steps.
- **Green before ship.** Code reaches `/ship` only with passing checks.
- **Never build on the default branch.**
- **Right-size the endpoint.** PR vs. local branch vs. leave-as-is follows the work, not a fixed default.
- **Don't widen scope.** Stay within the planned request; surface temptations to refactor beyond it.
