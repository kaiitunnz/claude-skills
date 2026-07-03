# Python — composed fallback

Applies when Step 2 found **no declared verify command** and the project is Python (`pyproject.toml` / `uv.lock`). If a declared command exists, use that instead — this reference is only the fallback toolchain.

## Runner and project root

Every command runs through **`uv run`** from the directory that owns the relevant `pyproject.toml`. Locate it first:

- Single package → the repo root (or the one dir with a `pyproject.toml`).
- Subdirectory / uv workspace (multiple `pyproject.toml`) → the directory that owns the code under test. Prefix tool runs with `uv run --directory <dir>` and point pytest at the right tests.

## Which tools to run

Compose only from the tools the project is actually configured for, read from `pyproject.toml`:

- `[tool.ruff]` → `ruff format --check` + `ruff check` (ruff owns import order when `I` is enabled).
- `[tool.black]` / `[tool.isort]` → `black --check` / `isort --check` if ruff isn't the formatter.
- `[tool.mypy]` → `mypy` (honors its own `files` config).
- `[tool.pytest.ini_options]` → `pytest`.

Don't introduce a tool the project has never used — e.g. don't run mypy on a project that has never type-checked.

## Commands

**Preferred path when `.pre-commit-config.yaml` is present** (one pass covers format, import order, lint, spelling, and mypy):

```bash
uv run pre-commit run --all-files
uv run pytest <paths-or-empty>
```

**Composed path when there's no pre-commit config** — run each configured tool, cheap-to-expensive:

```bash
uv run ruff format --check .     # formatting (or: black --check .)
uv run ruff check .              # lint (+ import order if ruff owns I)
uv run mypy                      # types — honors [tool.mypy] files
uv run pytest <paths-or-empty>   # tests
```

## Notes

- First `pre-commit run` of a session bootstraps hook environments (slow, not a hang).
- Missing tool → `uv sync` once, then retry before reporting a failure.
