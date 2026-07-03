# `pyproject.toml`

Single source of truth for metadata, dependencies, and every tool's config. Write it, or merge into an existing one. Replace `myproject` / `my_project` with the real distribution and import names.

```toml
[build-system]
requires = ["setuptools>=77", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "myproject"
version = "0.1.0"
description = "<one line>"
readme = "README.md"
requires-python = ">=3.12"
license = "MIT"
dependencies = [
  "pydantic>=2.11.0",
]

[dependency-groups]
dev = [
  "mypy>=1.13.0",
  "pre-commit>=4.0.0",
  "pytest>=8.4.0",
  "ruff>=0.6.0",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]

[tool.black]
target-version = ["py312"]

[tool.isort]
profile = "black"
src_paths = ["src", "tests"]
known_first_party = ["my_project"]

[tool.ruff]
target-version = "py312"
extend-exclude = [".venv", "build", "dist"]

[tool.ruff.lint]
select = ["E", "F", "B", "UP"]
ignore = [
  "E501",  # line length — black owns wrapping; long string literals stay
]

[tool.codespell]
skip = "*.lock,*.png,*.jsonl,*.log"

[tool.mypy]
python_version = "3.12"
files = ["src", "tests"]
mypy_path = "src"
plugins = ["pydantic.mypy"]
check_untyped_defs = true
warn_unused_ignores = true
warn_redundant_casts = true
ignore_missing_imports = true
```

## Conventions baked in

- **Runtime deps** go in `[project.dependencies]`; **tooling** in `[dependency-groups]` (PEP 735), installed by `uv sync`. Use `>=X.Y.Z` lower bounds — a compatibility floor, not an exact pin; `uv.lock` pins the resolved versions.
- **Ruff lint set** `E,F,B,UP` = pyflakes/pycodestyle + bugbear + pyupgrade. `E501` is ignored because black handles wrapping.
- **One import-sort owner.** The default keeps isort as the import sorter (its own pre-commit hook + `[tool.isort]`), so `I` is deliberately left out of the ruff select to stop the two from fighting. To consolidate on ruff instead, drop the isort hook and `[tool.isort]`, add `"I"` to the select, and use `ruff format` in place of black — pick exactly one owner.
- **mypy** runs over `src` and `tests`, loads the Pydantic plugin, and enables `check_untyped_defs` / `warn_unused_ignores` / `warn_redundant_casts`. Tighten further (`disallow_untyped_defs`, `warn_unused_configs`) per appetite. Once stubs exist, scope `ignore_missing_imports` narrowly with per-module `[[tool.mypy.overrides]]` instead of globally.
- **Add `types-*` stub packages** to the `dev` group as imports demand them (`types-PyYAML`, `pandas-stubs`, …) — prefer a stub over a blanket ignore.

## Variations (driven by Step 2 decisions)

- **Dynamic version**: drop `version`, add `dynamic = ["version"]`, put `setuptools-scm` in `[build-system].requires`, add `[tool.setuptools_scm]` with a `fallback_version` for shallow checkouts.
- **CLI**: add `typer` to deps and
  ```toml
  [project.scripts]
  myproject = "my_project.cli:main"
  ```
- **Async**: add `pytest-asyncio` to `dev`; set the async mode in `[tool.pytest.ini_options]` (see `references/languages/python/layout-and-tests.md`).
- **Workspace (monorepo)**: the root adds
  ```toml
  [tool.uv.workspace]
  members = ["sdk", "cli", "hook"]

  [tool.uv.sources]
  myproject-sdk = { workspace = true }
  ```
  Each member is a full project with its own `pyproject.toml` and `[tool.setuptools.packages.find] where = ["src"]`. Keep all `[tool.*]` lint/type config at the **root** so every member shares it, and point `[tool.mypy].files` at each member's `src`. Group runtime extras with named `[dependency-groups]` (e.g. `runtime-server`, `runtime-worker`) and aggregate them into a `ci` group via `{ include-group = "..." }` for full-environment installs.
