# Monorepo/workspace profile

Use only when the repo ships multiple separately installable packages or independent apps.

## Rules

- Keep shared docs and verification commands at the root.
- Keep each package/app manifest in its own directory.
- Prefer one package manager per language area.
- Scope hooks and commands so they run from the correct workspace root.
- Document how to verify each package and how to run the full repo gate.

## Common shape

```text
backend/
frontend/
packages/
AGENTS.md
```

For a Python + Next.js app like the Waypoint template model, use Python/FastAPI references for `backend/` and TypeScript/Next.js references for `frontend/`, then document both command sets in the root `AGENTS.md`.
