---
name: loop-optimize
description: Autonomously optimize a system or program against codebase-native evaluation signals. Explore the codebase and its existing harness, ask the user to settle unresolved goals, metrics, scope, parameters, constraints, and budget, establish a baseline, then iterate hypothesis → change → validate → evaluate → keep/reject until the stopping condition. Adapts to the project's own metric and result formats; does not impose a fixed schema. Use when the user says "/loop-optimize", "optimize this", "make this faster", "improve this score", or wants repeated measured improvement rather than one implementation pass. Distinct from the built-in /loop interval runner.
---

Improve an existing system against a measurable goal by running a **measured search**: form a hypothesis, change the implementation, validate it, measure it against the repo's own evaluation, and keep only what actually wins. This is not a feature or bug workflow — for that use `/loop-dev`. Here the deliverable is a *confirmed improvement*, left on a branch for the existing shipping workflow.

`ARGUMENTS` is the optimization request. If empty, use the conversation's current request; if there is none, stop and ask what to optimize.

The core loop:

```text
inspect → settle spec → baseline → hypothesize → change → validate → evaluate → keep/reject → repeat → confirm winner
```

Adapt to the codebase at every step. The repository's harness, metrics, workloads, and result formats win over any generic convention — there is **no fixed metric schema, result format, benchmark framework, or scalar objective** this skill imposes.

## Step 1 — Explore before specifying

Read before changing anything. Optimizing a component you don't understand wastes the whole budget on the wrong bottleneck.

**Survey repo state.** `git status`, current branch, current commit; `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and relevant docs; the target component, its surrounding architecture, and the call paths that actually exercise it.

**Discover the existing harness.** Search for tests and correctness checks; benchmark or evaluation scripts; profiling commands; Makefile / justfile / package scripts / task runners; representative workloads, datasets, fixtures, scenarios; CI performance jobs; prior benchmark results or perf docs; configuration parameters and any existing sweep/tuning tool. For anything beyond a couple of files, delegate the breadth to `Explore` / `general-purpose` subagents and keep their conclusions.

From that, determine: what is being changed; how the repo decides it still works; how it measures the target behavior; what workload makes runs comparable; which files are implementation vs. evaluation harness; whether measurements are deterministic or noisy; and the rough cost of one evaluation. **Prefer the repo's existing harness — do not replace it with a generic metric protocol.**

**Isolate the run.** Experiments must never destroy unrelated user work. Use a dedicated optimization branch or an isolated worktree; never reset over uncommitted changes. If the current state can't be isolated safely, resolve that with the user before experimenting.

## Step 2 — Settle the optimization specification

Infer as much as you can from the request and codebase, then be deliberately inquisitive about what remains. Use the harness's ask-question tool (e.g. `AskUserQuestion`) when available, otherwise ask in chat. Ask only about genuinely unresolved decisions, **bundled** rather than one at a time — but do not silently guess a material optimization choice.

Settle enough of the following to make experiments comparable:

- **Goal** — what improves (quality, latency, throughput, memory, cost, binary size, cache hit rate, a repo-specific score, …). For multiple goals, settle how to judge trade-offs: is the secondary metric another objective, a hard constraint, a tie-breaker, or informational? **Never invent a weighted scalar objective** — ask.
- **Evaluation procedure** — the authoritative command; the workload / dataset / scenario / inputs; what output constitutes the result; whether it runs in stages. Use whatever result form the codebase naturally produces — scalar, table, report, benchmark suite, profiler output, success rate, or several unrelated measurements.
- **Correctness and constraints** — what must stay true regardless: tests that must pass, output compatibility, resource ceilings, quality floors, behavioral invariants, platform/dependency limits. These are **gates, not gains**.
- **Editable scope and search space** — which files/subsystems may change vs. which are protected; whether parameters, config, algorithms, architecture, or all of them are in play; known parameter bounds. If the task is mainly a bounded parameter search and the repo already ships a sweep/tuning tool, use it rather than guessing values one at a time.
- **Budget and stopping condition** — how long the loop may run: a number of experiments, a time/compute budget, a target to reach, a stagnation rule, or manual interruption. **Do not begin an open-ended loop without a resolved stopping condition.**

Before experimentation starts, you must know:

```text
what may change · how candidates are evaluated · how candidates are compared · what must not regress · when the loop stops
```

If the repo has no usable evaluation procedure, propose the smallest appropriate harness grounded in the codebase and get the user's sign-off before adopting it.

## Step 3 — Establish baseline and experiment state

Create a persistent run file in the scratchpad recording the resolved spec, the baseline commit and result, the evaluation procedure, and every experiment as it happens. **Don't impose a metric schema** — preserve results in the form most useful for the repo; large raw outputs stay in files with their paths recorded.

Each experiment retains at least:

```text
parent/incumbent · hypothesis · change attempted · evaluation performed · observed result · verdict and reason
```

Establish the baseline from the **unchanged** starting version using the agreed procedure. If evaluation is stochastic or visibly noisy, run enough baseline measurements to tell whether later differences are meaningful — adapt the repeat count to the harness; there is no universal number. If the evaluation procedure changes later, prior results are no longer comparable — **re-establish the baseline**.

## Step 4 — Run the optimization loop

Within the agreed scope and budget, repeat autonomously — do not ask permission after every experiment.

1. **Inspect.** Read the current incumbent, the relevant implementation, profiling/evaluation evidence, and the history of previous experiments and rejected ideas. Don't retry an equivalent failed experiment without a concrete new reason.
2. **Hypothesize.** State what is likely limiting the objective and why the proposed change should help. Prefer evidence-driven changes over arbitrary mutations.
3. **Change.** Make one coherent change within scope. Checkpoint the candidate as a durable snapshot — commit it (via `/make-commits` or inline) so accepting advances the branch, rejecting reverts to the incumbent commit, the eventual winner is already committed for the shipping workflow, and Step 5's ablation can revert individual accepted changes.
4. **Validate through the cheapest useful cascade.** Kill invalid candidates before spending on expensive measurement. Typical ordering — adapt the exact stages to the repo, they are not fixed here:

   ```text
   build/smoke → targeted correctness → cheap evaluation → expensive evaluation → broader verification
   ```
5. **Evaluate.** Run the agreed workload under conditions comparable to the baseline and incumbent. Record the exact command, relevant workload/environment details, and the observed result in its native form. **Never alter the evaluator, workload, or comparison procedure to make a candidate look better.**
6. **Decide.**
   - **Accept** when required correctness and constraints hold, it is better by the agreed comparison rule, and the improvement is credible relative to known measurement noise. Advance it as the new incumbent.
   - **Reject** when it is worse, violates a constraint, or shows no credible improvement. Record the result and restore the incumbent.
   - **Invalid/crash** — fix trivial implementation mistakes and retry while the idea is still valid; otherwise log the failure and move on.
   - For close or noisy results, repeat evaluation before deciding.
7. **Continue.** Use the history to choose the next direction. When progress stalls: profile the bottleneck again, revisit promising near-misses, combine compatible ideas, reconsider assumptions, or explore another in-scope layer. **Do not answer stagnation by silently widening scope, changing the goal, weakening a constraint, or touching the evaluator — ask the user first.**

## Step 5 — Stop and validate the winner

Stop when the target is reached, the budget is exhausted, the stagnation condition is hit, the user interrupts, or the harness becomes unrecoverably broken. Then:

1. Run the best candidate through the representative final evaluation; repeat measurements to confirm a noisy result.
2. Run the repo's full verification with `/verify-impl` when available, otherwise the repo's own full check procedure.
3. Confirm protected evaluation inputs and harness logic were **not** changed.
4. When many accepted changes accumulated, drop any that no longer contribute where that can be tested cheaply.

A candidate that improves the metric but fails required correctness or constraints is **not** the winner.

## Step 6 — Leave and report the best result

Leave the best confirmed candidate on the optimization branch. **Do not auto-ship or open a PR** — the user invokes the existing shipping workflow (`/ship`) separately. Report compactly:

```text
Optimization:   <goal>
Branch/commit:  <best candidate>
Baseline:       <codebase-native result>
Final:          <codebase-native result>
Result:         <meaningful comparison>
Constraints:    <passed / failed>
Experiments:    <count> — <notable accepted and rejected directions>
Confidence:     <noise / confirmation info when relevant>
Final verify:   <result>
Run history:    <scratchpad path>
```

Don't manufacture a percentage improvement the underlying result doesn't support.

## Guardrails

- **Be inquisitive.** Explore first, then resolve material uncertainty with the question tool before optimizing. Never silently guess a material choice.
- **Adapt to the codebase.** Its harness, metrics, workloads, and result formats win over generic conventions. No fixed metric schema — the contract is comparability, not a serialization format.
- **Never invent trade-offs.** Ask how multiple goals are compared; don't fabricate a weighted score.
- **Protect the evaluator.** Evaluation logic and representative workloads are read-only unless explicitly placed in scope. Re-baseline after any evaluation change — never compare across incompatible harness versions.
- **Correctness is a gate.** A faster wrong program is not an improvement. Comparable runs only.
- **Measure, don't assume.** Every claimed improvement comes from an evaluation that actually ran. Log rejected and invalid ideas — they are useful search history.
- **Stay within scope and budget.** Ask before widening either.
- **Don't destroy user work.** Experiment only on an isolated branch or worktree.
- **Optimize, don't ship.** Leave the confirmed winner ready for the existing development and shipping workflow.
