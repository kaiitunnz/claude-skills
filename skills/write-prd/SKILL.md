---
name: write-prd
description: Turn a rough product idea, customer problem, or feature request into a concrete product requirements document (PRD) as a single Markdown file. Use when the user says "/write-prd", "write a PRD", "draft a product requirements document", "define the product requirements", or needs a product brief before technical design or implementation. Produces an untracked-by-default prd-*.md file in the repo's documentation location.
---

Turn a request into a self-contained product requirements document that aligns product, design, and engineering on the problem, intended users, scope, requirements, and measures of success. The output is a **single Markdown file** whose basename starts with `prd-`. A PRD defines the product outcome and the constraints around it; it does not prescribe the implementation. A downstream RFC or technical plan can make implementation decisions when needed.

`ARGUMENTS` is the user's request. If empty, use the current conversation request. If no request exists, stop and ask what product or feature the PRD should cover.

## Workflow

1. **Understand the product request.** Identify the problem or opportunity, intended users and stakeholders, user-visible outcome, constraints, what success means, and the decision the PRD should enable: scope a feature, align a launch, prioritize a problem, or hand off to design and engineering.
2. **Inspect local context.** Read only the relevant product docs, existing PRDs, roadmaps, issue notes, research, code paths, or project conventions needed to ground the document. Prefer repository evidence over assumptions. If the request depends on current external facts, use browsing only when the user requested it or the facts are time-sensitive and materially affect the PRD.
3. **Concretize the product specification.** Make the problem, target users, goals, non-goals, and scope explicit. Prioritize scope into an MVP, later work, and out-of-scope work. Write user journeys or stories, functional and non-functional requirements, and testable acceptance criteria. Define success metrics, dependencies, rollout needs, risks, and validation signals. Make assumptions visible instead of burying them.
4. **Resolve meaningful product choices.** When a product decision has credible alternatives (for example, target audience, MVP scope, or rollout strategy), document the options, recommendation, and tradeoffs. Do not manufacture an approach survey when the request has no real product choice to make.
5. **Write the PRD file.** Use the location and naming rules below. Do not implement the product or produce a technical design unless the user separately asks.
6. **Report concisely.** Return the PRD path, the proposed MVP, the success measure, and any open questions that need user review.

Be inquisitive before locking the scope. Ask the user for explicit confirmation of important inferences about users, desired outcomes, scope boundaries, success metrics, or product intent when the answer cannot be discovered from local context and a groundless assumption would materially change the PRD. Use the ask-question tool when it is available; otherwise ask concise plain-text questions. Proceed with labeled assumptions only for low-impact gaps or when the user has already authorized assumption-driven drafting.

## File Location

Place the PRD in the first existing directory from this list:

1. `./tmp/docs/prds`
2. `./tmp/docs`
3. `./tmp/prds`
4. `./tmp`
5. `./docs/prds`
6. `./docs`
7. `./prds`
8. `.`

If none of the PRD directories exists, write to the repo root. Do not create one of the preferred directories unless the user asks or project docs require it.

Name the file:

```text
prd-<short-kebab-title>.md
```

Keep the title stable and descriptive, for example `prd-worktree-aware-ship-flow.md`. If a file with that name exists, append a short distinguishing suffix rather than overwriting it.

## Git Handling

Prefer the PRD to remain **untracked**:

- Do not `git add` the PRD.
- If the target repo is under git, check status before and after writing so the final report can distinguish the new PRD from unrelated worktree changes.
- Track or commit the PRD only when the user explicitly asks, or when established project precedent requires PRDs to be tracked as part of the requested workflow. Precedence must come from repo docs, existing automation, or an explicit convention in existing PRD files; mention that reason in the report.

Never revert or modify unrelated user changes while drafting the PRD.

## PRD Template

Use this structure unless an existing project PRD template clearly supersedes it:

```markdown
# PRD: <Title>

- Status: Draft
- Owner: <product owner>
- Created: <YYYY-MM-DD>
- Target audience: <product/design/engineering/stakeholders>

## Summary

## Problem / Opportunity

## Target Users and Stakeholders

## Goals

## Non-Goals

## Background / Current State

## Scope and Prioritization

### MVP

### Later

### Out of Scope

## User Journeys / Stories

## Requirements

### Functional Requirements

For each requirement, include an identifier, priority, user or business need, and testable acceptance criteria.

### Non-Functional Requirements

## Product Decisions and Alternatives

## Success Metrics

## Dependencies and Constraints

## Rollout / Launch Plan

## Validation Plan

## Risks and Mitigations

## Open Questions

## Appendix
```

Omit sections only when they are genuinely irrelevant, and prefer `Not applicable` for sections whose absence might otherwise look accidental. Add domain-specific sections when useful, such as personas, UX/content guidance, accessibility, localization, pricing, support readiness, analytics, or legal/compliance requirements. Keep technical architecture and implementation detail out of the PRD except where they are material constraints; record a follow-up RFC or technical plan when a decision needs that depth.

## Quality Bar

- Make the PRD outcome- and user-centered, not a list of implementation tasks.
- State the problem, target users, and user value before proposing scope.
- Distinguish MVP from later work and non-goals so delivery teams can make tradeoffs.
- Give every functional requirement a priority and observable acceptance criteria.
- Tie success metrics to the intended user or business outcome; distinguish leading and lagging measures when useful.
- Separate product requirements from design or technical choices, and record material constraints explicitly.
- Keep assumptions and open questions actionable and bounded; avoid using them as a substitute for investigation.
- Preserve uncertainty explicitly with `Assumption:` or `Open question:` labels.
