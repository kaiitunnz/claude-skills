# FastAPI overlay

Use this with the Python language references when the project is a FastAPI service. The template model is Waypoint's backend: a `uv` Python package, `src/` layout, `pytest-asyncio`, Pydantic, Uvicorn, and pre-commit as the lint/type gate.

## Dependencies

Add runtime dependencies:

```toml
dependencies = [
  "fastapi>=0.139.0",
  "pydantic>=2.11.0",
  "uvicorn>=0.35.0",
]
```

Add these when the service needs them:

- `python-multipart` for form/file uploads.
- `PyYAML` for YAML config.
- `websockets` for WebSocket APIs.
- `httpx` in the dev group for API tests.
- `pytest-asyncio` in the dev group and `asyncio_mode = "auto"` for async tests.

## Layout

Prefer explicit modules by concern:

```text
src/<package>/
  __init__.py
  app.py          # create_app() or app instance
  api/            # routers
  config.py       # settings/config loading
  models.py       # Pydantic models when small; split when large
  cli.py          # optional service command
tests/
  test_<feature>.py
```

For larger services, split `auth/`, `storage/`, `runtime/`, or external integrations by ownership rather than putting backend-specific branches in central dispatch code.

## Commands

Document commands in `AGENTS.md`:

```bash
uv sync --group dev
uv run pre-commit install
uv run pytest
uv run pre-commit run --all-files
uv run uvicorn <package>.app:app --reload
```

If the project exposes a Typer CLI, add a `[project.scripts]` entry and document the service command instead.

## Configuration

- Commit an example env/config file with safe placeholders.
- Define config precedence explicitly: CLI flags, env vars, config file, defaults.
- Never commit real secrets.

## Verification

Run:

```bash
uv sync --group dev
uv run pre-commit run --all-files
uv run pytest
```
