---
name: release-project
description: Add, repair, or operate a project's release process. Routes between release-please automation, synchronized Python package releases, PyPI/TestPyPI Trusted Publishing, and GHCR/container image releases. Use when the user asks to set up releases, cut a release, prepare a release PR, publish packages/images, add release docs, or recover from a failed release.
---

# Release Project

Set up or run a release process without treating every project like the same package. This skill is a router: survey the repo, choose the release model, load the matching references, then preserve project-specific policy.

Template models:

- **Waypoint**: release-please on `main`, Conventional Commit PR titles, dynamic Python package versions from root `vX.Y.Z` tags, selected file updates such as frontend `package.json`, and generated `CHANGELOG.md`.
- **FlowMesh**: explicit synchronized multi-package version bump, release prep PR, TestPyPI verification, PyPI Trusted Publishing, GHCR image verification, and fix-forward recovery.

## When to use

- Adding release automation or release docs to a repo.
- Preparing a release PR or checking that a pending release is ready.
- Publishing Python distributions to TestPyPI/PyPI.
- Publishing or verifying release container images.
- Recovering from a failed or bad release.

Do not use this for ordinary CI, deployment, or package initialization unless the requested change is specifically release-related.

## Step 1 - Survey

Read before changing anything:

- Release docs: `docs/RELEASE.md`, `docs/RELEASING.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `AGENTS.md`.
- Version files: `pyproject.toml`, nested package `pyproject.toml` files, `package.json`, `_version.py`, manifest files.
- Release automation: `.github/workflows/*release*.yml`, `release-please-config.json`, `.release-please-manifest.json`, release scripts under `scripts/ci/` and `scripts/dev/`.
- Publishing targets: PyPI/TestPyPI, npm, GitHub Releases, GHCR or another container registry.
- Tag shape and branch policy: `vX.Y.Z`, component tags, protected environments, manual approvals.

If a release process already exists, reconcile. Do not replace it wholesale unless the user explicitly asks.

## Step 2 - Choose the model

Ask only when the model cannot be inferred.

| Model | Use when |
| --- | --- |
| release-please | The project wants automated changelog/version PRs from Conventional Commit history. |
| synchronized Python packages | Multiple Python distributions must share one explicit version and publish together. |
| single Python package | One package is manually bumped, built, and published. |
| container images | Release tags also produce or verify OCI images. |
| docs-only release policy | The task is to document an existing manual process without adding automation. |

## Routing

Always read:

1. `references/core/survey.md`
2. `references/core/release-prep.md`
3. `references/core/verification.md`
4. `references/core/publish-safety.md`

Then load only the matching pattern:

- Waypoint-style release-please: `references/patterns/waypoint/release-please.md`
- Waypoint-style versioning: `references/patterns/waypoint/versioning.md`
- FlowMesh-style synchronized packages: `references/patterns/flowmesh/synchronized-python-packages.md`
- Single Python package publishing: `references/patterns/flowmesh/single-python-package.md`
- FlowMesh-style PyPI/TestPyPI publishing: `references/patterns/flowmesh/pypi-trusted-publishing.md`
- FlowMesh-style GHCR images: `references/patterns/flowmesh/container-images.md`
- Release failure recovery: `references/patterns/flowmesh/recovery.md`

## Guardrails

- **Never move or force-update release tags.** If a published tag/version is wrong, fix forward unless the release owner explicitly documents another path.
- **Do not publish implicitly.** Publishing to PyPI, npm, GitHub Releases, or a container registry requires an explicit release/publish request and passing preflight checks.
- **Prefer trusted publishing over long-lived tokens.** Use OIDC/Trusted Publishing when the package host supports it.
- **Verify from artifacts.** Build, metadata-check, install/smoke-test, and image-inspect the thing that will be published.
- **Keep prerelease semantics explicit.** RC/dev/post releases must be deliberate and reflected in tags, package versions, and latest-retag behavior.
- **Recovery is constrained by immutability.** PyPI and many registries do not allow replacing a released version. Yank, post-release, rerun idempotent image steps, or cut the next patch as appropriate.
