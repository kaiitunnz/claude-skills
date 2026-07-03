---
name: loop-plan
description: Iterate a request into a converged, written plan through a self-review loop — break down intent, explore the codebase, draft a plan to a file, then have a fresh-context subagent critique it and revise until no material issues remain. Handles any request type (bug fix, feature, redesign, paper draft). Runs autonomously; does not enter plan mode and does not pause for approval. Use when the user says "/loop-plan", "plan this out", or as the planning phase of /loop-dev. Distinct from the built-in /loop interval runner.
---

Turn a request into a **converged, written plan** — one that a fresh reviewer signs off on — without entering plan mode and without pausing for approval. This runs autonomously: work the loop to convergence, then report. Only halt on something genuinely breaking or an ambiguity you cannot resolve by investigating.

`ARGUMENTS` is the request: a bug fix, new feature, redesign, paper draft, or anything else. If empty, use the conversation's current request. If there is none, stop and ask what to plan.

## Step 1 — Understand the request

- Restate the request as concrete **goals and intents** — what "done" means, the constraints, the acceptance signals. Separate what was asked from what you're inferring.
- Classify the **deliverable type** — code (fix / feature / redesign) vs. document (paper / design doc / prose). This drives how `/loop-dev` executes later; record it in the plan.
- Read project conventions: `AGENTS.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `CONTRIBUTING.md`.

## Step 2 — Explore

Investigate as far as the request needs — no further. For anything beyond a couple of files, delegate broad search to `Explore` / `general-purpose` subagents and keep their conclusions, not the file dumps. Resolve unknowns by reading code, not by guessing; if a fact is unknowable from the repo and blocks the plan, that is a halt-and-ask.

## Step 3 — Draft the plan to a file

Write the plan to a **file** (in your scratchpad directory, or in the repo if the plan is itself a deliverable). A file is required — step 4's reviewer runs in a fresh context and can only review what's written down. Capture the path; it's the handoff to `/loop-dev`.

The plan states: the goals from step 1, the deliverable type, the ordered steps, the files/sections touched, the verification signal (tests to pass, or the review bar for prose), and the risks/open questions.

**Multi-agent organization.** Decide whether the work should fan out. If `/waypoint-workqueue` is available *and* the work is a batch of largely independent tasks at a scale one context can't hold well (migration, codemod, broad audit, many parallel edits), plan the crew split — lead vs. workers, task boundaries, how results merge — and record it in the plan. Otherwise plan for a single context. Don't reach for a workqueue for tightly-coupled feature work.

## Step 4 — Converge (review → revise loop)

Loop until the plan converges — no hard round cap:

1. **Review in a subagent.** Spawn a fresh subagent, point it at the plan file, and ask it to find *material* problems only — wrong approach, missed goals, unhandled cases, ordering hazards, unrealistic steps, risky assumptions. Explicitly tell it to skip nitpicks and style. Have it return a verdict plus a concrete findings list.
2. **Revise.** Fold every material finding into the plan file. Push back (in the plan's notes) on findings you disagree with, with reasoning — don't silently drop them.

**Converged** when a review returns no material issues, or two consecutive rounds surface nothing new. Each round must fold in the previous round's findings, so the loop only continues while reviews are still finding real problems — a stable plan ends it. Keep going as long as rounds keep surfacing genuinely new material issues. If the loop is **thrashing** — a resolved finding reappears, or reviews contradict each other — halt and surface that rather than looping through it.

## Step 5 — Report

Report back compactly: the plan file path, a short summary of the approach, the chosen execution organization (single-context vs. workqueue crew), and any open concerns. When invoked standalone this is the final output; when invoked by `/loop-dev`, this is the handoff — return the plan path and proceed.

## Guardrails

- **Autonomous, not silent-on-breakage.** No approval gates, but halt and surface anything genuinely breaking or an ambiguity investigation can't resolve.
- **The plan is a file.** Never rely on in-context-only plans — the reviewer can't see them.
- **Material findings only.** Keep the convergence loop from spinning on nitpicks — it converges when reviews stop finding real problems, not on a fixed round count. Surface thrashing rather than looping through it.
- **Don't over-explore.** Investigate to the depth the plan needs; delegate breadth to subagents.
- **Right-size the crew.** Only plan a workqueue fan-out when the work genuinely warrants it.
