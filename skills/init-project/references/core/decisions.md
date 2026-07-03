# Decisions

Infer from the request and repo where possible. Ask only for choices that change generated files and are not knowable from context.

## Required when absent

- Project name.
- Package/import name.
- One-line description.
- License, if the manifest needs one.

## Profile selection

- **Library**: reusable package, no long-running process by default.
- **Service**: networked app or daemon. Add runtime config docs, env examples, service start command, and integration-test notes.
- **CLI**: command entry point, argument parsing dependency, and command examples in docs.
- **Monorepo/workspace**: multiple installable packages or app halves that need independent manifests and shared root docs.

## Defaults

- Static version `0.1.0`.
- Minimal security tier with secret scanning where the stack supports it.
- `src/` layout for Python and TypeScript app/library code unless an existing framework layout says otherwise.
- Lockfiles are tracked.
- Local `.env` files are ignored; example env files are tracked.
