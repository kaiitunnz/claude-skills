---
name: write-rfc
description: Expand a user's rough feature, architecture, product, process, or technical request into a concrete RFC/design proposal as a single Markdown file. Use when the user says "/write-rfc", "write an RFC", "draft an RFC", "turn this into a spec", "survey approaches", or asks the agent to concretize a vague request before implementation. Produces an untracked-by-default rfc-*.md file in the repo's RFC/documentation location.
---

Turn a request into a self-contained RFC that a fresh implementer or reviewer can use to make decisions. The output is a **single Markdown file** whose basename starts with `rfc-`.

`ARGUMENTS` is the user's request. If empty, use the current conversation request. If no request exists, stop and ask what the RFC should cover.

## Workflow

1. **Understand the request.** Identify the user-visible outcome, stakeholders, constraints, what "done" means, and the intended decision: choose an approach, approve a project, unblock implementation, or record tradeoffs.
2. **Inspect local context.** Read only the relevant project docs, existing RFCs, code paths, issue notes, or conventions needed to make the RFC concrete. Prefer repo evidence over assumptions. If the request depends on current external facts, use browsing only when the user requested it or the facts are time-sensitive and materially affect the RFC.
3. **Concretize the specification.** Convert vague intent into explicit requirements, non-goals, acceptance criteria, interfaces, data shapes, lifecycle behavior, rollout/migration steps, and validation signals. Make assumptions visible instead of burying them.
4. **Survey approaches.** Present at least two credible options when there is a meaningful design choice. Include the recommended approach and the reasons it wins. If only one approach is realistic, say why and still document rejected variants or constraints.
5. **Write the RFC file.** Use the location and naming rules below. Do not implement the RFC unless the user separately asks.
6. **Report concisely.** Return the RFC path, the recommended approach, and any open questions that need user review.

Be inquisitive before locking the scope. Ask the user for explicit confirmation of important inferences, scope boundaries, and product/technical intent when the answer cannot be discovered from local context and a groundless assumption would materially change the RFC. Use the ask-question tool when it is available; otherwise ask concise plain-text questions. Proceed with labeled assumptions only for low-impact gaps or when the user has already authorized assumption-driven drafting.

## File Location

Place the RFC in the first existing directory from this list:

1. `./tmp/docs/rfcs`
2. `./docs/rfcs`
3. `./rfcs`
4. `.`

If none of the RFC directories exists, write to the repo root. Do not create one of the preferred directories unless the user asks or project docs require it.

Name the file:

```text
rfc-<short-kebab-title>.md
```

Keep the title stable and descriptive, for example `rfc-worktree-aware-ship-flow.md`. If a file with that name exists, append a short distinguishing suffix rather than overwriting it.

## Git Handling

Prefer the RFC to remain **untracked**:

- Do not `git add` the RFC.
- If the target repo is under git, check status before and after writing so the final report can distinguish the new RFC from unrelated worktree changes.
- Track or commit the RFC only when the user explicitly asks, or when established project precedent requires RFCs to be tracked as part of the requested workflow. Precedence must come from repo docs, existing automation, or an explicit convention in existing RFC files; mention that reason in the report.

Never revert or modify unrelated user changes while drafting the RFC.

## RFC Template

Use this structure unless an existing project RFC template clearly supersedes it:

```markdown
# RFC: <Title>

- Status: Draft
- Author: <author>
- Created: <YYYY-MM-DD>
- Target audience: <reviewers/implementers/users>

## Summary

## Motivation

## Goals

## Non-Goals

## Background / Current State

## Requirements

### Functional Requirements

### Non-Functional Requirements

## Proposed Design

## Detailed Specification

## Approach Survey

### Option 1: <Name>

### Option 2: <Name>

### Recommendation

## Rollout / Migration Plan

## Validation Plan

## Risks and Mitigations

## Security, Privacy, and Compliance

## Operational Considerations

## Open Questions

## Appendix
```

Omit sections only when they are genuinely irrelevant, and prefer `Not applicable` for sections whose absence might otherwise look accidental. Add domain-specific sections when useful, such as API shape, UX flows, data model, compatibility, performance, accessibility, observability, or backwards compatibility.

## Quality Bar

- Make the RFC decision-ready, not merely descriptive.
- Tie recommendations to evidence, constraints, and tradeoffs.
- Use concrete examples, command names, file paths, schemas, or interface sketches when they clarify the proposal.
- Separate requirements from design choices.
- Record rejected alternatives fairly enough that a reviewer can see why they lost.
- Keep open questions actionable and bounded; avoid using them as a substitute for investigation.
- Preserve uncertainty explicitly with `Assumption:` or `Open question:` labels.
