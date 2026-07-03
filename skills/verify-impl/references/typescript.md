# JavaScript / TypeScript — composed fallback

Applies when Step 2 found **no declared verify command** and the project is JavaScript/TypeScript (`package.json`). If a declared command exists — including the project's own `package.json` **scripts** — use that instead; this reference is only the fallback toolchain.

## Runner and project root

Detect the **package manager** from the lockfile and drive every script/tool through it — don't switch managers:

- `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` / `bun.lock` → bun.

Root is the directory owning `package.json`. For a monorepo/workspace (`pnpm-workspace.yaml`, a `workspaces` field, turbo/nx), run at the package that owns the code under test, or use the workspace runner: `pnpm -F <pkg>`, `npm -w <pkg>`, `turbo run <task> --filter <pkg>`.

## Which tools to run

Compose only from the tools the project is actually configured for, read from `package.json` (`scripts` + `devDependencies`) and config files. **Prefer the project's own scripts** — a defined `lint` / `typecheck` / `format:check` / `test` / `test:e2e` script *is* the declared command; run it rather than reconstructing the invocation.

- **Format:** Prettier (`.prettierrc*` / `prettier` dep) → `prettier --check .`; or Biome (`biome.json`) → `biome check`.
- **Lint:** ESLint (`eslint.config.*` flat, or `.eslintrc*` legacy) → `eslint .`. Flat config (ESLint 9 default) derives extensions from its `files` globs; under **legacy `.eslintrc*` on a TS project add `--ext .ts,.tsx`**, or `eslint .` silently skips `.ts` and false-greens. Biome also covers lint.
- **Types:** TypeScript (`tsconfig.json` / `typescript` dep) → `tsc --noEmit`. For composite/project-reference repos, run `tsc --noEmit` **at the package owning the code under test** (it checks that tsconfig's program). Keep `tsc -b` out of the gate — build mode writes artifacts (`.tsbuildinfo`, and `.js` / `.d.ts` absent `--noEmit`), violating verify-don't-mutate; plain `tsc --noEmit` is the side-effect-free check.
- **Test:** the configured runner, always in run/CI mode, never watch — Vitest (`vitest run`), Jest (`jest`), node built-in (`node --test`), Mocha (`mocha`).

Don't introduce a tool the project has never used — e.g. don't run Prettier on a project with no Prettier config or dependency.

## Commands

**Preferred path — the project's own scripts** (run whichever exist, cheap-to-expensive):

```bash
<pm> run format:check   # e.g. npm run / pnpm / yarn / bun run
<pm> run lint
<pm> run typecheck
<pm> run test
```

**Composed path when there's no script** — run the project's **installed, pinned** binaries (from `devDependencies`) via a local-first runner: `npx` (prefers a local install), `pnpm exec`, `yarn exec` / `yarn <bin>`, `bun run`. Not `pnpm dlx` / `yarn dlx`, which fetch the latest unpinned version and would gate against a different toolchain than the project ships.

```bash
<pm> exec prettier --check .     # or: biome check .
<pm> exec eslint .               # legacy config on TS: + --ext .ts,.tsx
<pm> exec tsc --noEmit           # composite: run at the owning package, not tsc -b
<pm> exec vitest run             # or: jest / node --test / mocha
```

The exec form varies: `npx <bin>` (npm), `pnpm exec <bin>`, `yarn <bin>`, `bunx <bin>` (bun — local-first, not `bun exec`).

## End-to-end / integration suite

Detect it and whether the default `test` script runs it:

- **Playwright** — `@playwright/test` in `devDependencies` + a `playwright.config.{ts,js}`.
- **Cypress** — `cypress` dep + `cypress.config.{ts,js}` or a `cypress/` dir.
- A dedicated `test:e2e` / `e2e` script — often a separate CI job, not part of `test` (existence ≠ part of the gate).

When e2e is triggered (Step 3 of the skill), run it the project's own way — its `test:e2e` script, or `<pm> exec playwright test` / `<pm> exec cypress run` — rather than inventing a selection. These drive a real browser but run **through the test runner**, so they stay in this skill's lane (not the built-in `verify`). Playwright needs its browsers (`playwright install`) and Cypress its binary, and both usually need a dev server / backing services up; if those aren't available, report e2e as **not run**, not failed.

## Notes

- Missing / uninstalled tool → install deps once (`<pm> install`, or `npm ci`), then retry before reporting a failure.
- `package.json` scripts **are** the project's declared command — prefer them over reconstructing tool invocations.
- The first Playwright run downloads browsers (slow, not a hang).
