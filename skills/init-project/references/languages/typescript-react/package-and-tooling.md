# TypeScript React package and tooling

Use this for React app baselines, including Next.js and Vite. Reconcile into an existing `package.json` instead of replacing it.

The default model follows Waypoint's frontend: `npm` scripts for development, production build/start where applicable, strict TypeScript, and ESLint as the lint gate.

## Package manager

- Preserve the existing package manager and lockfile.
- For a new project, use `npm` unless the user asks for `pnpm`, `yarn`, or `bun`.
- Track the lockfile (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, or `bun.lockb`).

## Scripts

Provide predictable scripts:

```json
{
  "scripts": {
    "dev": "<framework dev command>",
    "build": "<framework build command>",
    "start": "<framework start/preview command>",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  }
}
```

For Next.js, `build` runs the framework type/build pipeline; still keep `typecheck` when a separate TypeScript gate is useful.

## TypeScript

Default `tsconfig.json` rules:

- `strict: true`.
- `noEmit: true` for app projects.
- `moduleResolution: "bundler"`.
- `jsx: "react-jsx"` unless the framework overrides it.
- Path alias `@/*` to `./src/*` for app projects.

## ESLint

- Use the framework's recommended config when one exists.
- For Next.js, use `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`.
- Avoid adding Prettier unless the repo already uses it or the user asks; do not introduce two formatting owners.

## Dependencies

- Keep React and framework versions aligned.
- Add `@types/node`, `@types/react`, and `@types/react-dom` as dev dependencies for TypeScript React apps.
- Add test libraries only when the user asks for a test harness or the existing repo already has tests.
