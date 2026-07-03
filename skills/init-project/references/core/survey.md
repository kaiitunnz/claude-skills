# Survey and reconciliation

Classify the target before writing.

## Empty or fresh repo

- Create the requested baseline from scratch.
- Initialize only files needed for the selected stack and profile.
- Do not add CI, release automation, deployment config, or publishing metadata unless the user asked.

## Existing repo

- Read the manifests and docs before editing.
- Preserve package names, import paths, scripts, dependencies, and test layout.
- Merge tool config into existing files instead of replacing them.
- If a project already has a different but coherent toolchain, ask before replacing it.

## Stack signals

- Python: `pyproject.toml`, `uv.lock`, `src/`, `tests/`, `.python-version`.
- FastAPI: `fastapi`, `uvicorn`, `pydantic`, API routers, app factory, service config.
- TypeScript React: `package.json`, `tsconfig.json`, `src/`, `.tsx`, React deps.
- Next.js: `next`, `next.config.*`, `src/app/` or `pages/`, `next-env.d.ts`.
- Vite React: `vite`, `@vitejs/plugin-react`, `vite.config.*`, `index.html`.
- Monorepo: multiple manifests, workspace config, package/member directories.

## Conflict handling

Surface conflicts rather than silently flattening them:

- Multiple package managers with lockfiles.
- Existing lint/type config that disagrees with the requested baseline.
- Non-src Python layout in a repo with import-sensitive tests.
- Framework version constraints that make the template commands invalid.
