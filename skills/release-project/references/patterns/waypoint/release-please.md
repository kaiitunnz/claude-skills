# Waypoint-style release-please

Use this model when releases should be generated from Conventional Commit history on `main`.

## Files

Create or reconcile:

- `release-please-config.json`
- `.release-please-manifest.json`
- `.github/workflows/release-please.yml`
- `CHANGELOG.md`
- PR-title validation workflow or script
- `CONTRIBUTING.md` release section
- `docs/RELEASING.md`

## Config shape

Waypoint uses a single root package with `release-type: "simple"`, `bump-minor-pre-major: true`, `include-component-in-tag: false`, and `CHANGELOG.md` as the changelog path. It also updates selected extra files, such as `frontend/package.json`, through `extra-files`.

Use this pattern when:

- The repository releases one product version across multiple components.
- Python packages can derive versions from tags.
- A frontend or other manifest still needs an explicit version field updated.

## Workflow

Run release-please on pushes to `main` with:

- `contents: write`
- `pull-requests: write`
- `googleapis/release-please-action`
- config and manifest file paths wired explicitly

Release operation:

1. Merge PRs to `main` with Conventional Commit titles.
2. release-please opens or updates a Release PR.
3. Review the Release PR's changelog and version-file changes.
4. Merge the Release PR.
5. release-please creates the `vX.Y.Z` tag and GitHub Release.

## PR title contract

Require Conventional Commit PR titles because squash-merge turns the PR title into the commit on `main`.

Recommended types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.

Version effects:

- `feat:` bumps minor.
- `fix:` bumps patch.
- `feat!:` or `BREAKING CHANGE:` bumps major, or minor while pre-1.0 when configured.
- `docs:`, `chore:`, `test:`, `ci:`, `refactor:` usually do not release unless configured otherwise.

Do not manually edit the changelog/version files owned by release-please except through a Release PR.
