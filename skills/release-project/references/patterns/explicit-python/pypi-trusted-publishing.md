# PyPI and TestPyPI Trusted Publishing

Use this when publishing Python distributions through GitHub Actions.

## Repository setup

Prefer PyPI Trusted Publishing over long-lived API tokens.

For every distribution:

- Create matching publishers on TestPyPI and PyPI.
- Configure owner, repository, workflow filename, and environment name.
- Create GitHub environments such as `testpypi` and `pypi`.
- Require manual approval for production PyPI.

## Workflow shape

Split into build and publish jobs.

Build job:

- Checkout the release tag with full history.
- Verify the tag is reachable from `origin/main`.
- Set up the package manager.
- Install with lockfile frozen.
- Validate release versions.
- Build all distributions.
- Check metadata.
- Smoke-test distributions.
- Upload `dist/` as an artifact.

Publish job:

- Needs the build job.
- Uses environment `testpypi` for manual test runs and `pypi` for real releases.
- Requests `id-token: write`.
- Downloads the exact build artifact.
- Publishes with the package host's trusted-publishing action.

## Operation

1. Merge the release prep PR.
2. Create and push an annotated tag, for example `vX.Y.Z`.
3. Run the release workflow manually against TestPyPI.
4. Verify installs from TestPyPI in a fresh environment.
5. Create/publish the GitHub Release or run the production publish workflow.
6. Verify installs from PyPI in a fresh environment.

Never upload packages manually unless the workflow is unavailable and the release owner documents the fallback.
