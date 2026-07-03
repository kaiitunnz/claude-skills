# React/Vite overlay

Use this with the TypeScript React references for a client-rendered React app that does not need Next.js routing, server components, or framework server behavior.

## Package scripts

For a new npm project:

```json
{
  "scripts": {
    "dev": "vite --host 0.0.0.0",
    "build": "tsc --noEmit && vite build",
    "start": "vite preview --host 0.0.0.0",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  }
}
```

Use `--host 0.0.0.0` only when the dev server must be reachable from another device or container.

## Dependencies

Add:

- `@vitejs/plugin-react`
- `vite`
- `react`
- `react-dom`
- `typescript`
- `eslint`
- React/TypeScript ESLint config packages chosen by the current Vite ecosystem.

## Files

Use:

```text
index.html
vite.config.ts
src/main.tsx
src/App.tsx
src/components/
src/lib/
src/styles/
```

## Verification

Run:

```bash
npm install
npm run lint
npm run typecheck
npm run build
```
