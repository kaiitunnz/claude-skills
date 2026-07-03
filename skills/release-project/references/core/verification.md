# Release verification

Release verification checks the artifacts that users will install, not just the source tree.

## Common gates

- Source gate: lint, type-check, tests, security checks.
- Version gate: tag and manifest versions match, internal pins are synchronized.
- Build gate: package build succeeds from a clean checkout.
- Metadata gate: package metadata validates (`twine check`, npm pack checks, equivalent).
- Artifact smoke gate: install the built package into a fresh environment and import or run its public command.
- Tag gate: the release tag is reachable from `origin/main`.
- Image gate: image labels, tag, revision, platforms, and digest match the release.

## Reporting

Report each gate as pass/fail/not-run. For not-run, give the reason: no artifact type, missing credentials, service unavailable, or user did not ask to publish.

Do not collapse "built successfully" and "published successfully" into one result. They fail differently and recover differently.
