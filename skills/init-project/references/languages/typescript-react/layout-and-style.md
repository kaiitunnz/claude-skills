# TypeScript React layout and style

Use `src/` for application code unless the framework's current convention says otherwise.

## Layout

Common layout:

```text
src/
  app/ or pages/        # framework routes
  components/           # shared UI
  lib/                  # client helpers and API clients
  styles/ or app/*.css  # global styles, framework-dependent
```

For plain React/Vite:

```text
src/
  main.tsx
  App.tsx
  components/
  lib/
  styles/
```

## Style rules to record

- TypeScript uses strict typing, `PascalCase` for components, and `camelCase` for helpers/state.
- Keep comments sparse and focused on non-obvious reasoning.
- Derive colors and dimensions from CSS variables or design tokens in larger apps.
- For apps with themes, keep both themes resolving from tokens and avoid hardcoded one-theme surfaces.
- Do not add visual design systems or animation libraries unless the project needs them.

## Env files

- Browser-exposed variables must use the framework's public prefix (`NEXT_PUBLIC_` for Next.js, `VITE_` for Vite).
- Keep secrets server-only and out of client bundles.
