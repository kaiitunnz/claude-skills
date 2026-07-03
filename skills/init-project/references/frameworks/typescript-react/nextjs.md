# Next.js overlay

Use this with the TypeScript React references. The template model is Waypoint's frontend: a strict TypeScript Next.js app, `src/app/` routes, `eslint-config-next`, and `npm` scripts for `dev`, `build`, `start`, and `lint`.

## Package scripts

For a new npm project:

```json
{
  "scripts": {
    "dev": "next dev --hostname 0.0.0.0",
    "build": "next build",
    "start": "next start --hostname 0.0.0.0",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  }
}
```

Bind dev/start to `0.0.0.0` only when phone, LAN, container, or remote-device testing is expected. Otherwise the standard `next dev` and `next start` are fine.

## Dependencies

Add:

- `next`
- `react`
- `react-dom`
- `typescript`
- `eslint`
- `eslint-config-next`
- `@types/node`
- `@types/react`
- `@types/react-dom`

Keep versions compatible; do not mix unrelated React and Next major versions.

## Files

Use:

```text
src/app/
src/components/
src/lib/
src/app/globals.css
next.config.ts
tsconfig.json
eslint.config.mjs
```

In `next.config.ts`, set `reactStrictMode: true`. Add `allowedDevOrigins` only when the app needs access from phones, Tailscale, containers, or non-localhost hosts; if added, derive hosts from environment or local interfaces rather than hardcoding machine-specific addresses.

## Verification

Run:

```bash
npm install
npm run lint
npm run typecheck
npm run build
```

If there is no automated frontend test harness, record that in the report.
