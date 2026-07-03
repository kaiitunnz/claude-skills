# TypeScript React verify

Use the repo's declared commands when present. For a new npm-based app, run:

```bash
npm install
npm run lint
npm run typecheck
npm run build
```

If the project has tests, also run the test script:

```bash
npm test
```

## Framework notes

- Next.js: `npm run build` is the production-quality gate. It catches many route, server/client boundary, and type integration issues.
- React/Vite: run `npm run build`; if `start` maps to `vite preview`, do not use it as a static gate unless you are manually verifying runtime behavior.
- If there is no test harness, say that explicitly rather than inventing one during init.
