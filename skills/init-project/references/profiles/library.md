# Library profile

Use for reusable packages without a default long-running process.

- Keep runtime dependencies minimal.
- Document public API entry points in `README.md`.
- Include tests for importability and public behavior.
- Avoid app/server config files unless examples require them.
- For Python, use `src/<package>/` and `tests/`.
- For TypeScript, expose library entry points only if the package is intended for publishing; otherwise keep app-local helpers under `src/lib/`.
