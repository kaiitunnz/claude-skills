---
name: release-project
description: Add, repair, or operate a project's release process. Routes between release-please automation, synchronized Python package releases, PyPI/TestPyPI Trusted Publishing, and GHCR/container image releases. Use when the user asks to set up releases, cut a release, prepare a release PR, publish packages/images, add release docs, or recover from a failed release.
---

# Release Project

Set up or run a release process without treating every project like the same package. This skill is a router: survey the repo, choose the release model, load the matching references, then preserve project-specific policy.

Common release models:

- **Automated changelog release**: release-please on `main`, Conventional Commit PR titles, dynamic package versions from root `vX.Y.Z` tags, selected explicit version-file updates, and generated `CHANGELOG.md`.
- **Explicit synchronized release**: multi-package version bump, release prep PR, TestPyPI verification, PyPI Trusted Publishing, container-image verification, and fix-forward recovery.

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

- Automated release-please flow: `references/patterns/release-please/automation.md`
- Tag-derived package versioning: `references/patterns/release-please/tag-derived-versioning.md`
- Synchronized Python packages: `references/patterns/explicit-python/synchronized-packages.md`
- Single Python package publishing: `references/patterns/explicit-python/single-package.md`
- PyPI/TestPyPI Trusted Publishing: `references/patterns/explicit-python/pypi-trusted-publishing.md`
- Container image releases: `references/patterns/explicit-python/container-images.md`
- Release failure recovery: `references/patterns/explicit-python/recovery.md`

## Guardrails

- **Never move or force-update release tags.** If a published tag/version is wrong, fix forward unless the release owner explicitly documents another path.
- **Do not publish implicitly.** Publishing to PyPI, npm, GitHub Releases, or a container registry requires an explicit release/publish request and passing preflight checks.
- **Prefer trusted publishing over long-lived tokens.** Use OIDC/Trusted Publishing when the package host supports it.
- **Verify from artifacts.** Build, metadata-check, install/smoke-test, and image-inspect the thing that will be published.
- **Keep prerelease semantics explicit.** RC/dev/post releases must be deliberate and reflected in tags, package versions, and latest-retag behavior.
- **Recovery is constrained by immutability.** PyPI and many registries do not allow replacing a released version. Yank, post-release, rerun idempotent image steps, or cut the next patch as appropriate.
