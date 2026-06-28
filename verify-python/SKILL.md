---
name: verify-python
description: Run a Python project's static checks and tests as a pre-push / pre-PR gate — formatting, lint, type-check, and the test suite — and report a clear green/red verdict. Prefers the repo's own declared verify command (pre-commit, a CONTRIBUTING/AGENTS step, a Makefile or CI script) and falls back to composing ruff + mypy + pytest through uv. Surfaces failures faithfully; does not fix them. Use when the user says "verify my changes", "run the checks", "is it green", "/verify-python", or before committing/pushing. Not for confirming runtime behavior by launching the app — that's the built-in `verify` skill.
---

# Verify Python

Confirm a Python working tree is **green** before it goes anywhere: formatting, lint, types, and tests all pass. This is a *gate*, not a fixer — it runs the project's checks the way the project itself runs them, reports exactly what failed, and gives a clear verdict. Getting from red to green is a separate step (and a separate skill).

`ARGUMENTS` is optional: one or more paths to scope the **test run** (e.g. `tests/unit`); default is the whole project. Lint, types, and formatting always run project-wide regardless — narrowing those would let a failure elsewhere slip the gate.

## When to use vs. the built-in `verify`

- **This skill** — static checks + test suite (ruff / mypy / pytest). The "did I break the build" gate before commit, push, or PR.
- **Built-in `verify`** — launches the app and observes real runtime behavior to confirm a change *does what it should*. Use that when the question is "does the feature actually work", not "do the checks pass".

They compose: `verify-python` for green, built-in `verify` for *correct*.

## Step 1 — Survey the project

Run in parallel:

- `git status` and `git diff --stat` — what changed (so the report can scope to it).
- Locate the package manager and project root: is there a `pyproject.toml`? a `uv.lock`? Is the project at the repo root or under a subdirectory / uv workspace (multiple `pyproject.toml`)? Every command below runs through `uv run` from the directory that owns the `pyproject.toml`.
- Read the project's declared check workflow before composing your own. Check, in order:
  - `.pre-commit-config.yaml` — the canonical lint/format/type stack if present.
  - `AGENTS.md` / `CLAUDE.md` / `CONTRIBUTING.md` — a "before opening a PR" / "running tests" section often names the exact commands. **Prefer these over guessing.**
  - `Makefile` / `justfile` / `noxfile.py` / `tox.ini` — a `check` / `lint` / `test` target.
  - `.github/workflows/*` — only to learn *which* checks CI runs (not to replicate release/publish jobs). Releases and deploy steps are out of scope.

If there is no `pyproject.toml` and no recognizable Python tooling, stop and say so — this skill is for Python projects.

## Step 2 — Resolve the check command

- **If the project declares a canonical command** (a documented PR-prep command, a Makefile target, or a pre-commit config), use it. The repo's own definition of "green" wins over a generic one.
- **Otherwise compose** from the tools actually configured in `pyproject.toml` (`[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]`, `[tool.black]`, `[tool.isort]`). Only run a tool the project is set up for — don't introduce mypy to a project that has never type-checked.

For a subdirectory/workspace project, prefix tool runs with `uv run --directory <dir>` and point pytest at the right tests.

## Step 3 — Run the checks

Run them in cheap-to-expensive order so the fastest failures surface first, and run **all** of them even if an early one fails — a single combined report beats stopping at the first red.

Preferred path when pre-commit is configured (covers format, import order, lint, spelling, and mypy in one pass):

```bash
uv run pre-commit run --all-files
uv run pytest <paths-or-empty>
```

Composed path when there's no pre-commit config — run each configured tool:

```bash
uv run ruff format --check .     # formatting (or: black --check .)
uv run ruff check .              # lint (+ import order if ruff owns I)
uv run mypy                      # types — honors [tool.mypy] files
uv run pytest <paths-or-empty>   # tests
```

Notes:
- `--check` / report-only modes only — never let a formatter rewrite files as a side effect of verifying. If `ruff format --check` reports it *would* reformat, that's a failure to report, not to silently apply.
- The first `pre-commit run` of a session bootstraps hook environments and is slow; that's expected, not a hang.
- If a tool is missing from the environment, run `uv sync` once and retry before reporting it as a failure.

## Step 4 — Report the verdict

Summarize each check as pass/fail, then a single overall verdict. Quote the actual failing output (the failing test names + assertion, the mypy `error:` lines, the ruff codes) — enough for the user to act, not the entire log.

```
verify-python — <project / subdir>
  format   ✓
  lint     ✗  ruff: F401 unused import (src/foo.py:3), ...
  types    ✓
  tests    ✗  2 failed: test_x, test_y
            <key assertion / error line>
Verdict: RED — lint + tests failing.
```

When everything passes, keep it short: `Verdict: GREEN — N tests passed, lint/types/format clean.`

Do **not** start fixing findings. Report and stop — fixing is the user's call (and `address-ci-failures` / a follow-up edit pass is the place for it). If asked to fix afterward, that's a separate action.

## Guardrails

- **Verify, don't mutate.** No formatter writes, no `ruff --fix`, no `--no-verify`, no edits. Use `--check`/report modes only; a tool that *would* change files is a red, reported with its diff/summary.
- **Use the project's definition of green.** Prefer its declared command and only run tools it's configured for; don't impose checks the project doesn't use.
- **Run all checks, then report once.** Don't bail at the first failure — collect every result into one verdict.
- **Ground the verdict in real output.** Every pass/fail claim comes from a command that actually ran; never infer green from "it looks fine."
- **Stay in the Python lane.** This is static checks + tests. It doesn't launch the app (built-in `verify`), commit (`make-commits`), or push.
