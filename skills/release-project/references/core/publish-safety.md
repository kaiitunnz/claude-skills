# Publish safety

Publishing is irreversible enough to require explicit intent.

## Before publishing

- Confirm the exact tag, version, target registry/index, and artifact set.
- Confirm the tag points at the intended commit and is reachable from `main`.
- Confirm the release prep PR is merged.
- Confirm the normal CI/release validation is green.
- For production indexes, verify the TestPyPI/test-registry run first when the repo supports it.
- Confirm required GitHub environments and trusted publishers exist.

## Safer defaults

- Use TestPyPI or a dry-run artifact build before production PyPI.
- Use GitHub environment approval for production publish jobs.
- Use OIDC/Trusted Publishing instead of API tokens.
- Use annotated tags for manual release flows.
- Keep image `latest` retagging behind a separate approval or version guard.

## Hard stops

- Dirty worktree while tagging.
- Tag not reachable from `main`.
- Version validation fails.
- Artifact smoke tests fail.
- Any production publish target cannot be verified.
- Request requires deleting or reusing an already-published version.
