# Supporting files

## `.gitignore`

Start from GitHub's Python template (covers `__pycache__/`, `build/`, `dist/`, `*.egg-info/`, `.venv/`, `.mypy_cache/`, `.pytest_cache/`, `.coverage`, etc.). Then add:

- Env files with a negated example: `.env*` followed by `!*.env*.example` so the template stays tracked.
- Project artifact dirs (`results/`, `metrics/`, `tmp*`) and editor cruft (`.vscode`, `.DS_Store`).

Keep **`uv.lock` tracked** — it's the reproducibility lock, not generated cruft.

## `.env.example`

Commit a documented template of every env var the app reads, with safe placeholder values and a header comment (`# Copy to .env and adjust`). Group vars into commented sections. The real `.env` stays gitignored. As the project grows, a small check (script or test) that every env var referenced in code appears in `.env.example` keeps it from rotting.

## `.python-version`

The interpreter version, so uv and pyenv agree:

```
3.12
```

## `LICENSE`

Add the license file matching the `license` field in `pyproject.toml` (MIT and Apache-2.0 are common choices). Add `license-files = ["LICENSE"]` under `[project]` if the build backend should bundle it.
