---
name: init-python-project
description: Scaffold a new Python project — or align an existing one — onto a uv-based, src-layout, fully-linted baseline (pyproject.toml for py3.12, pre-commit with gitleaks/isort/black/ruff/codespell/mypy, pytest/pytest-asyncio, Pydantic, AGENTS.md + CLAUDE.md routing docs, .env.example, Python .gitignore). Use when the user says "start a new Python project", "set up project tooling", "/init-python-project", or wants an existing repo brought up to the standard layout and lint stack.
---

# Init Python Project

Stand up a Python project on a known-good baseline: **uv** for environment and dependency management, a **src layout** with tests, **pre-commit** enforcing formatting/lint/spelling/types, **Pydantic** for models and settings, and short **agent-facing docs** (`AGENTS.md` + `CLAUDE.md`) that route future agents to the rules. The defaults are opinionated and fit most projects; the few places where a project legitimately needs to differ are surfaced as decisions, not guessed.

This skill scaffolds and configures. It does **not** set up releases, publishing, or CI workflows — leave `release-please`, `RELEASE.md`, GitHub Actions, and version-bump automation out unless the user asks separately.

## When to use

- Starting a new Python project from an empty directory or a fresh `git init`.
- Bringing an existing Python repo up to this layout and lint stack (reconcile, don't clobber).

If the repo already matches the baseline, there's nothing to do — say so rather than rewriting working config.

## Step 1 — Survey before scaffolding

Read before writing.

- `git status` and `ls` the target — empty repo, fresh init, or existing codebase being aligned?
- If `pyproject.toml`, `AGENTS.md`, `CLAUDE.md`, `.pre-commit-config.yaml`, or `src/` already exist, read each. The job becomes *reconcile to the baseline* — preserve existing dependencies, package names, and project-specific config; only add what's missing and flag genuine conflicts.
- Confirm `uv` is installed (`uv --version`). If not, point the user at <https://docs.astral.sh/uv/> and stop — every later step runs through `uv`.

## Step 2 — Settle the decisions

These are the only choices that change the scaffold. Ask the user (use the ask-question tool if available) rather than guessing; bundle them into one prompt. Recommended default is listed first.

| Decision | Options | Default & when to switch |
| --- | --- | --- |
| **Layout** | single package · uv workspace (monorepo) | Single package. Switch to a workspace only when the repo ships several separately-installable distributions (e.g. `sdk` / `cli` / `hook`). |
| **Version source** | static · dynamic (`setuptools-scm`) | Static `version = "0.1.0"`. Use `setuptools-scm` (version from git tags) when the project tags releases and wants it derived automatically. |
| **Async** | yes · no | Match the code. If it uses `asyncio`, add `pytest-asyncio` and configure an async test mode. |
| **CLI entry point** | yes · no | Add `[project.scripts]` only if the package exposes a command (`typer` is a good default dependency). |
| **Security scanning** | minimal · hardened | Minimal (gitleaks in pre-commit). Add `bandit` + a `[tool.bandit]` policy when the project handles untrusted input, subprocesses, or deserialization. |

Project name, package import name (`snake_case`), description, and license also come from the user if not already set.

## Routing

Apply these in order. Each reference holds the canonical file contents and the variations driven by Step 2's decisions.

1. **`pyproject.toml`** — metadata, dependencies, and every tool's config (the single source of truth): `references/pyproject.md`.
2. **pre-commit** — the enforcement layer wiring the same tools to each commit: `references/pre-commit.md`.
3. **Source layout, tests, and async** — the `src/` package, test tree, and async test mode: `references/layout-and-tests.md`.
4. **Project docs** — `AGENTS.md` + `CLAUDE.md` routing docs, `CONTRIBUTING.md`, and the code-style rules to record: `references/project-docs.md`.
5. **Hardened security** (only if chosen) — `bandit` config and the `# nosec` policy: `references/security.md`.
6. **Supporting files** — `.gitignore`, `.env.example`, `.python-version`, `LICENSE`: `references/supporting-files.md`.
7. **Materialize and verify** — `uv sync`, install hooks, run the full check: `references/verify.md`.

## Guardrails

- **Reconcile, don't clobber.** On an existing repo, merge into what's there and preserve project-specific config; surface real conflicts instead of overwriting silently.
- **Pin to current tags.** Fetch the latest released `rev`s for pre-commit hooks and current versions for tools — don't copy stale pins from the templates verbatim.
- **Lower bounds, locked once.** Dependencies use `>=` floors in `pyproject.toml`; `uv.lock` pins the resolved versions and stays tracked in git.
- **Stubs over ignores.** Reach for a `types-*` stub or a narrow per-module mypy override before a blanket `ignore_missing_imports`; never a bare `# type: ignore`.
- **Verify, don't assume.** End on a clean `uv run pre-commit run --all-files` and a passing (even if empty) `uv run pytest`. Report what was created vs. left intact, and name any decision you defaulted.
