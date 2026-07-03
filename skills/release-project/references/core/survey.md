# Release survey

Classify the current release system before editing.

## Files to inspect

- `docs/RELEASE.md`, `docs/RELEASING.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `AGENTS.md`.
- `release-please-config.json` and `.release-please-manifest.json`.
- `.github/workflows/*release*.yml`, PR-title checks, DCO checks, publish workflows.
- Package manifests: root and nested `pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`.
- Version modules such as `_version.py` or generated runtime version constants.
- Scripts that bump, validate, build, filter, publish, or verify artifacts.

## Questions to answer

- Is the release automatic from commit history, explicit/manual, or hybrid?
- What is the tag format?
- Which files own the version?
- Which artifacts ship: Python wheels/sdists, npm package, GitHub Release, images, docs?
- Which checks must pass before release prep, before tagging, and after publish?
- Which GitHub environments or registry publisher settings must exist?
- Are releases signed, annotated, protected by approvals, or tied to `main`?

## Red flags

- Version numbers are duplicated without a validation script.
- Release tags can be created from branches not reachable from `main`.
- Publish workflow uses long-lived tokens where trusted publishing is available.
- Build and smoke tests run on source files but not on built artifacts.
- Recovery docs suggest deleting/reusing published versions.
