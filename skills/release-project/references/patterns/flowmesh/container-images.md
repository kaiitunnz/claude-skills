# Container image releases

Use this when release tags also publish OCI images.

## Build/push requirements

- Build images from the release tag or exact release commit.
- Pass the image tag explicitly, usually `vX.Y.Z`.
- Pass the build revision explicitly, usually `git rev-parse HEAD`.
- Write OCI labels for version and revision.
- Publish every expected image/tag variant.

## Verification workflow

After images are pushed, a release-images workflow should:

- Checkout the release tag.
- Verify the tag is reachable from `origin/main`.
- Inspect each image manifest.
- Confirm image labels match the release tag and commit.
- Confirm expected platforms exist.
- Write a digest table artifact or release-note section.

## Latest retag

Retagging `:latest` should be a separate approved job.

- Skip latest for prereleases such as rc/dev tags.
- Allow post releases to move latest only if that is the documented policy.
- Add downgrade protection unless the workflow has an explicit `force_latest` input.

## Registry setup

For GHCR, first-time setup may need:

- Public package visibility if anonymous pulls are expected.
- Repository Actions access with write permission for retag jobs.
- A protected environment, such as `ghcr`, for latest retag approval.
