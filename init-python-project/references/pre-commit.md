# `.pre-commit-config.yaml`

The enforcement layer — the same tools as the `pyproject.toml` config, wired to run on every commit. mypy runs as a **local** hook through `uv run` so it sees the project's resolved environment (the mirrored hooks don't). Pin every hook `rev` to a current released tag — don't copy these verbatim if they've gone stale.

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.30.1
    hooks:
      - id: gitleaks

  - repo: https://github.com/pycqa/isort
    rev: 8.0.1
    hooks:
      - id: isort

  - repo: https://github.com/psf/black
    rev: 26.3.1
    hooks:
      - id: black
        language_version: python3.12

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.15.10
    hooks:
      - id: ruff-check

  - repo: https://github.com/codespell-project/codespell
    rev: v2.4.2
    hooks:
      - id: codespell

  - repo: local
    hooks:
      - id: mypy
        name: mypy
        entry: uv run mypy
        language: system
        types: [python]
        pass_filenames: false
        require_serial: true
```

## Notes

- **mypy as a local hook**: `pass_filenames: false` + `require_serial: true` type-check the whole configured tree as one pass, not file-by-file — cross-file inference would otherwise break. `language: system` runs it through the project's `uv` environment.
- **gitleaks** is the minimal-tier secret scanner; it stays even when bandit (hardened tier) isn't added.
- **Monorepo / subdirectory project**: scope hooks with `files: ^subdir/`, run mypy via `uv run --directory subdir mypy`, and point codespell at the right config with `args: ["--toml=subdir/pyproject.toml"]`.
- **Optional local hooks** worth knowing: a `sync-requirements` hook (regenerates pinned `requirements.txt` from `uv.lock` when `pyproject.toml`/`uv.lock` change) and DCO sign-off hooks (`prepare-commit-msg` to append `Signed-off-by`, `commit-msg` to verify). Add these only if the project actually needs pinned requirement exports or DCO.
