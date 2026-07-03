# Waypoint-style versioning

Use this when multiple project parts share one repo-level version but only some files need explicit edits.

## Dynamic Python versions

For Python packages under subdirectories, use `setuptools-scm` with:

- `dynamic = ["version"]`
- `[tool.setuptools_scm] root = ".."` for packages one level below repo root
- root tags shaped as `vX.Y.Z`

This lets backend/control-plane Python packages read the same root tag at build time without manual version edits.

## Explicit version files

Keep explicit versions only where the ecosystem requires them, such as a frontend `package.json`.

Have release-please update these via `extra-files` rather than asking humans to keep them in sync.

## Docs to add

Document:

- Which commits create version bumps.
- Which files release-please owns.
- That no manual tag/version edit is needed.
- How users upgrade to a tagged release if the project has an updater.

## Validation

Before enabling this model:

- Confirm all Python packages can build from a root tag.
- Confirm generated or explicit version files are either derived or in `extra-files`.
- Confirm PR-title checks match the Conventional Commit types named in docs.
