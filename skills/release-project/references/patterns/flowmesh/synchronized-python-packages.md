# FlowMesh-style synchronized Python packages

Use this model when several Python distributions must publish together with one explicit version.

## Version ownership

Maintain one synchronized version across:

- Root metapackage `pyproject.toml`.
- Each public package `pyproject.toml`.
- First-party exact pins between those packages.
- Runtime version modules such as SDK, CLI, or shared constants.

Do not rely on humans editing each file by hand. Add or use a bump script that updates all version owners and internal pins together.

## Validation script

Add or use a release-version check that:

- Parses the release tag as PEP 440 after removing a leading `v`.
- Confirms all package versions are identical.
- Confirms every first-party exact pin matches the release version.
- Confirms runtime version modules match.
- Fails if the tag version differs from any manifest.

## Release prep commands

Template flow:

```bash
uv run scripts/dev/bump_version.py X.Y.Z
uv lock
uv run scripts/ci/check_release_version.py --tag vX.Y.Z
uv sync --all-packages --group dev --frozen
uv build --all-packages --out-dir dist
uvx twine check dist/*
uv run scripts/ci/check_package_build.py --dist dist
uv run pre-commit run --all-files
uv run pytest tests/
```

Adjust test exclusions only when the repo documents them, such as hardware-only tests.

## Artifact smoke tests

Build all distributions from the release checkout. In fresh environments, install the built root/umbrella package with each public extra or subpackage path and run public imports or CLI help commands.

For a metapackage, verify it does not accidentally include private runtime source modules.
