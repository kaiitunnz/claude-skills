# Materialize and verify

Run, don't assume. From the project root:

```bash
uv sync --group dev                 # create .venv, install runtime + dev deps, write uv.lock
uv run pre-commit install           # wire the git hooks
uv run pre-commit run --all-files   # format/lint/spell/type the whole tree
uv run pytest                       # confirm the (possibly empty) suite collects and passes
```

- **Workspace (monorepo)**: use `uv sync --all-packages`, adding `--group ci` or the relevant runtime groups for a full environment.
- **DCO/extra hook stages**: if the pre-commit config adds `prepare-commit-msg` / `commit-msg` hooks, install them too:
  `uv run pre-commit install -t pre-commit -t prepare-commit-msg -t commit-msg`.

Fix anything the hooks flag — a clean first `pre-commit run --all-files` is the bar. The first run also bootstraps each hook's environment, so it's slower than later runs.

## Report

When done, tell the user:

- What was **created** vs. what already existed and was **left intact**.
- Any decision you **defaulted** because they didn't specify (layout, version source, async, CLI, security tier).
- The result of the verification run — green, or the specific failures still open.
