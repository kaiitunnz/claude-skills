---
name: verify-impl
description: Run a project's static checks and tests as a pre-push / pre-PR gate — formatting, lint, type-check, and the test suite — and report a clear green/red verdict, in any language. Prefers the repo's own declared verify command (pre-commit, a CONTRIBUTING/AGENTS step, a Makefile/justfile target, a CI script); when none is declared, composes one from the project's configured toolchain via a per-language reference (Python today; add a reference per new language). Surfaces failures faithfully; does not fix them. Use when the user says "verify my changes", "run the checks", "is it green", "/verify-impl", or before committing/pushing. Not for confirming runtime behavior by launching the app — that's the built-in `verify` skill.
---

# Verify Implementation

Confirm a working tree is **green** before it goes anywhere: formatting, lint, types, and tests all pass. This is a *gate*, not a fixer — it runs the project's checks the way the project itself runs them, reports exactly what failed, and gives a clear verdict. Getting from red to green is a separate step (and a separate skill).

The gate is defined the same way in every language: **prefer the repo's own declared verify command**, and only when none exists compose one from the tools the project is actually configured for. Steps 1–4 below are language-agnostic; the composed-fallback specifics (which tools, which runner, which commands) live in a per-language reference loaded on demand.

`ARGUMENTS` is optional: one or more paths to scope the **test run** (e.g. `tests/unit`); default is the whole project. Lint, types, and formatting always run project-wide regardless — narrowing those would let a failure elsewhere slip the gate. A bare `e2e` directive (a flag, not a path) additionally requests the **end-to-end suite** — a `/loop-dev` spec forwards it here when the plan calls for e2e.

## When to use vs. the built-in `verify`

- **This skill** — static checks + test suite. The "did I break the build" gate before commit, push, or PR.
- **Built-in `verify`** — launches the app and observes real runtime behavior to confirm a change *does what it should*. Use that when the question is "does the feature actually work", not "do the checks pass".

They compose: `verify-impl` for green, built-in `verify` for *correct*.

End-to-end / integration tests count as *tests* — automated, run through the test runner — so they live on **this** side of the line. **Manually driving the app** is the built-in `verify`'s job, not this skill's, even when an e2e suite would exercise the same flow.

## Step 1 — Survey the project

Run in parallel:

- `git status` and `git diff --stat` — what changed (so the report can scope to it).
- **Identify the ecosystem** from its manifest, so you know where the project root is and which reference applies if you fall back: `pyproject.toml` / `uv.lock` → Python; `package.json` → Node/TS; `Cargo.toml` → Rust; `go.mod` → Go; and so on. Note monorepo/workspace roots (multiple manifests) — each may own its own checks.
- Read the project's **declared check workflow** before composing your own. Check, in order:
  - `.pre-commit-config.yaml` — the canonical lint/format/type stack if present (language-agnostic).
  - `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` — a "before opening a PR" / "running tests" section often names the exact commands. **Prefer these over guessing.**
  - `Makefile` / `justfile` / a task runner (`nox`/`tox`, npm scripts, `cargo`, `mage`, …) — a `check` / `lint` / `test` target.
  - `.github/workflows/*` — only to learn *which* checks CI runs (not to replicate release/publish jobs). Releases and deploy steps are out of scope.
- **Detect any e2e / integration suite** and whether the project's gate includes or excludes it: a separate `tests/e2e` / `tests/integration` dir, `@pytest.mark.e2e` / `integration` markers (often deselected via `-m "not e2e"` in `addopts`), a dedicated `make e2e` / `test:e2e` script, or a CI-only e2e job. Note both that it exists **and** whether the default test command runs it — Step 3 needs both facts.

If you can't identify the ecosystem **and** there's no declared command to run, stop and say so — there's nothing to gate against.

## Step 2 — Resolve the check command

- **If the project declares a canonical command** (a documented PR-prep command, a Makefile/justfile/task-runner target, or a pre-commit config), use it. The repo's own definition of "green" wins over a generic one. This path is language-agnostic — no reference file needed.
- **Otherwise compose** from the tools the project is actually configured for, following the matching language reference (see **Routing**). Only run a tool the project is set up for — don't introduce a checker the project has never used.

For a subdirectory/workspace project, resolve the right root and scope the run to it, per the language reference.

## Step 3 — Run the checks

Run them in cheap-to-expensive order so the fastest failures surface first, and run **all** of them even if an early one fails — a single combined report beats stopping at the first red. The exact commands and runner come from the declared command (Step 2) or the language reference.

- `--check` / report-only modes only — never let a formatter rewrite files as a side effect of verifying. A tool that reports it *would* reformat is a failure to report, not to silently apply.
- If a tool is missing from the environment, sync dependencies once (the way the language reference specifies) and retry before reporting it as a failure.
- Some first-run steps bootstrap their environment and are slow (e.g. pre-commit installing hooks); that's expected, not a hang.

**End-to-end / integration tests.** The default test run above is whatever the project runs by default — which often *excludes* a slow or service-dependent e2e suite. Run e2e **in addition** when either: (a) the caller explicitly asks (the `e2e` directive, or a `/loop-dev` spec that calls for it) — this **overrides** a default exclusion; or (b) the project's own gate already includes e2e. A suite the project deliberately excludes is **not** force-run without an explicit ask. Invoke e2e the project's own way (its marker, dir, or dedicated command); don't fake it. If e2e can't run because required services or fixtures aren't available, report that — it counts as **not run**, not as a failure. A failure of an e2e run that *did* execute is RED like any other test.

## Step 4 — Report the verdict

Summarize each check as pass/fail, then a single overall verdict. Quote the actual failing output (failing test names + assertion, type-checker `error:` lines, lint codes) — enough for the user to act, not the entire log. Always include an **`e2e`** line stating its status — `✓ N passed`, `✗ ...`, or `— not run (<reason>)` (`excluded from gate` / `no e2e suite` / `services unavailable`) — so a green verdict never silently implies e2e coverage it doesn't have.

```
verify-impl — <project / subdir> (<language>)
  format   ✓
  lint     ✗  <tool>: <code / message> (<path:line>), ...
  types    ✓
  tests    ✗  2 failed: test_x, test_y
            <key assertion / error line>
  e2e      —  not run (excluded from gate)
Verdict: RED — lint + tests failing.
```

When everything passes, keep it short but still state e2e: `Verdict: GREEN — N tests passed, lint/types/format clean; e2e N passed.` — or `; e2e not run — excluded from gate` when it wasn't run.

Do **not** start fixing findings. Report and stop — fixing is the user's call (and `address-ci-failures` / a follow-up edit pass is the place for it).

## Routing

The four steps above are language-agnostic. Each language's **composed-fallback** toolchain — the exact tools, runner, and commands used when Step 2 finds no declared command — lives in a reference, loaded only when the fallback fires for that language:

- **Python** — uv + `ruff` / `mypy` / `pytest`, pre-commit vs. composed path, workspace handling: `references/python.md`.
- **JavaScript / TypeScript** — package-manager-driven (`npm` / `pnpm` / `yarn` / `bun`): `prettier` / `eslint` (or Biome) / `tsc` / the test runner, with Playwright / Cypress for e2e: `references/typescript.md`.

Adding support for a new language means adding one `references/<lang>.md` and a row here — Steps 1–4 don't change.

## Guardrails

- **Verify, don't mutate.** No formatter writes, no `--fix`, no `--no-verify`, no edits. Use `--check`/report modes only; a tool that *would* change files is a red, reported with its diff/summary.
- **Use the project's definition of green.** Prefer its declared command and only run tools it's configured for; don't impose checks the project doesn't use. **One stated exception:** an explicit `e2e` ask may run the end-to-end suite beyond the project's default gate — report it as run outside the default gate.
- **Surface e2e coverage.** Always report whether e2e ran; a GREEN verdict must never imply e2e passed when it wasn't run.
- **Run all checks, then report once.** Don't bail at the first failure — collect every result into one verdict.
- **Ground the verdict in real output.** Every pass/fail claim comes from a command that actually ran; never infer green from "it looks fine."
- **Stay in the verify lane.** This is static checks + tests. It doesn't launch the app (built-in `verify`), commit (`make-commits`), or push.
