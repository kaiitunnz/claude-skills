# Release prep

A release prep change is reviewable work. It should land through a PR unless the repo's existing release process says otherwise.

## Prep checklist

- Pick the next version from the repo's version policy.
- Update all version-owned files or let the release bot do it.
- Update changelog/release notes if the process is manual.
- Re-lock dependencies when package metadata changes.
- Run release metadata validation.
- Build the release artifacts locally or in CI.
- Smoke-test installs from built artifacts.
- Run the normal verify gate for the repo.

## PR conventions

- Use the repo's required PR title format.
- For release-please repos, ordinary feature/fix PR titles drive the later Release PR. Do not manually bump files unless release-please owns them through `extra-files` or the repo asks for a manual release.
- For explicit release-prep repos, use a release-prep PR title that the repo accepts, such as `chore: release vX.Y.Z`.
- Include commands run and any publish target setup still required.

## What not to include

- Deployment changes unrelated to publishing.
- Secret values or registry tokens.
- Ad hoc version edits that bypass the repo's bump script.
- CI workflow rewrites beyond the release path requested.
