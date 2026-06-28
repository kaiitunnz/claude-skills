# Project docs and code style

Route agents through a short `AGENTS.md` (the cross-agent convention) with a thin `CLAUDE.md` that imports it, plus a `CONTRIBUTING.md` for humans. The code-style rules live where review can enforce them, not just tooling.

## `CLAUDE.md`

A single line so Claude Code picks up the shared rules:

```
@AGENTS.md
```

## `AGENTS.md`

A *routing doc*, not an essay — it points at where the real rules live and surfaces the few that come up most. Include:

- One-paragraph description of what the project is.
- **Project structure**: where source, tests, and any subpackages live, organized by concern.
- **Build / test / dev commands**: `uv sync --group dev`, `uv run pre-commit install`, `uv run pytest`, `uv run pre-commit run --all-files`.
- **Code style** essentials (below), or a pointer to `docs/CODE_STYLE.md` if the project keeps a dedicated one.
- **Commit / PR conventions**: Conventional-Commit subjects and PR titles (`feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`), one logical change per commit, and DCO sign-off (`git commit -s`) if the project requires it.

For a larger project, split detail into `docs/` (`ARCHITECTURE.md`, `CODE_STYLE.md`, …) and have `AGENTS.md` link to them and `@`-import the few that should always load.

## `CONTRIBUTING.md`

Covers, for humans: setup (`uv sync`), installing hooks (`uv run pre-commit install`), running tests, the dependency-bump workflow, and the commit/PR conventions — so the rules aren't only in agent-facing files.

## Code-style rules to record

Capture these in `AGENTS.md` or `docs/CODE_STYLE.md`.

- Python 3.12+. **Top-level imports only**; inline imports only to break a circular import.
- Prefer `typing.Any` over `object`; `X | Y` and `X | None` over `Union` / `Optional`.
- Don't write `from __future__ import annotations` — use `typing.Self` or quoted forward refs.
- No `hasattr` / `getattr` that bypasses the type checker — use `isinstance` guards. (`getattr` is fine for dynamic dispatch, a default value, or genuinely untyped third-party APIs.)
- `# type: ignore[<error-code>]` only after exhausting fixes — never a bare `# type: ignore`.
- **Comments**: default to none; names self-document. Comment only when *why* is non-obvious. Docstrings describe what the code *does*, never what it replaced or "added for X" — no changelog prose in code.
- When serializing a `Path` to a string for internal use (data, APIs, storage, test assertions), use `path.as_posix()`; use `str(path)` only for user-facing output where an OS-native path reads better.
