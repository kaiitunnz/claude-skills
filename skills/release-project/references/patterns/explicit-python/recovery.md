# Release recovery

Use fix-forward recovery unless the release owner has a documented exception.

## Package index immutability

PyPI versions are immutable. Once a version is published:

- Do not delete and reuse the version.
- Do not move the release tag to new source.
- Do not attempt to replace the artifact.

Recovery options:

- Yank the bad release when installers should skip it unless explicitly pinned.
- Cut the next patch release for code or dependency bugs.
- Use a `.postN` release only for metadata/package-only fixes where source behavior did not change.

## Image-only failures

If packages published but images failed:

- Push images again from the tagged checkout with the same image tag and build ref.
- Rerun the image verification/retag workflow.
- Keep PyPI/GitHub Release artifacts unchanged unless their metadata was wrong.

## Release workflow failures

- Build failure: fix in a new release prep PR before tagging or publishing.
- TestPyPI publish failure: fix setup/workflow, rerun TestPyPI before production.
- Production publish approval missed: rerun or approve the existing workflow if artifacts are unchanged.
- Latest retag failure: rerun the retag job after image verification passes.

Every recovery note should record what published, what did not, and the next immutable version if a fix-forward release is needed.
