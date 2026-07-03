# Single Python package releases

Use this when one Python distribution owns one explicit version.

## Version ownership

- Keep the canonical version in `pyproject.toml` unless the repo already derives it from tags.
- If runtime code exposes `__version__` or a `_version.py` file, add a validation script so it cannot drift from `pyproject.toml`.
- Use a `vX.Y.Z` tag unless the repo already has a different documented tag shape.

## Prep commands

Template flow:

```bash
uv lock
uv sync --group dev --frozen
uv build --out-dir dist
uvx twine check dist/*
uv run pytest
uv run pre-commit run --all-files
```

If the package has CLI entry points, smoke-test the built wheel in a fresh environment and run `command --help`.

## Publish

Use the PyPI/TestPyPI Trusted Publishing reference for the workflow shape. Even for one package, production PyPI should publish the exact artifact built and verified by the release workflow.
