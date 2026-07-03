# Supporting files

Apply these across stacks, then add language-specific files from the selected language reference.

## Ignore files

- Ignore local env files and keep examples tracked: `.env*` plus `!*.env*.example`.
- Ignore editor/system files such as `.DS_Store` and `.vscode/` unless the repo intentionally tracks editor settings.
- Ignore local build outputs and caches for the selected stack.
- Keep lockfiles tracked unless the repo has an explicit policy not to.

## Env examples

Commit safe examples for runtime configuration:

- `.env.example` at the repo root for shared config.
- Framework-local examples such as `frontend/.env.example` or `backend/.env.example` when apps run independently.

Every variable read by the app should be represented with a safe placeholder or documented default.

## License

Create `LICENSE` only when the user chose a license and the repo does not already have one.
