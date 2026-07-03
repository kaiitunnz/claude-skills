---
name: init-project
description: Scaffold a new project, or align an existing one, using a routed baseline by language, framework, and project profile. Supports Python/uv, TypeScript React, Next.js, and FastAPI from nested references. Use when the user says "start a new project", "set up project tooling", "/init-project", "/init-python-project", or wants a repo brought onto a clean lint/test/docs baseline.
---

# Init Project

Stand up a project on a known-good baseline without forcing every stack through the same template. This skill is a router: keep the workflow and decisions here, then load only the relevant nested references for the selected language, framework, and profile.

This skill scaffolds and configures. It does **not** set up releases, publishing, deployment, or CI workflows unless the user asks separately.

## When to use

- Starting a new project from an empty directory or a fresh `git init`.
- Bringing an existing repo up to a consistent layout, lint/type/test stack, and agent-facing docs.
- Replacing the narrower Python-only flow; Python projects route to `references/languages/python/`.

If the repo already matches the requested baseline, say so rather than rewriting working config.

## Step 1 - Survey before scaffolding

Read before writing.

- Check `git status` and list the target directory.
- Detect existing manifests and framework signals: `pyproject.toml`, `uv.lock`, `package.json`, `tsconfig.json`, `next.config.*`, `vite.config.*`, `src/`, `tests/`, `app/`, `pages/`, `.pre-commit-config.yaml`, `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`.
- If any target file already exists, reconcile into it. Preserve dependencies, package names, app routes, and project-specific config; only add what is missing and flag real conflicts.
- Confirm required package managers before continuing: `uv` for Python/FastAPI, and the repo's chosen Node package manager for React/Next.js.

## Step 2 - Settle the decisions

Ask only when a decision cannot be inferred safely. Bundle unknowns into one prompt.

| Decision | Options | Default |
| --- | --- | --- |
| Language | Python, TypeScript/React, both | Infer from user request or existing manifests. |
| Framework | none, FastAPI, React/Vite, Next.js | Infer from request; use none for a library. |
| Profile | library, service, CLI, monorepo/workspace | Single-package library unless the request says app/service/CLI/monorepo. |
| Version source | static, dynamic from tags | Static `0.1.0`; use dynamic only for tag-driven releases. |
| Async / networked runtime | yes, no | Yes for FastAPI and async code; otherwise match existing code. |
| Security tier | minimal, hardened | Minimal; hardened for untrusted input, subprocesses, deserialization, auth, or exposed services. |

Project name, import/package name, description, and license come from the user if not already present.

## Routing

Always read the relevant core files:

1. Survey and reconciliation: `references/core/survey.md`.
2. Decision handling: `references/core/decisions.md`.
3. Agent and contributor docs: `references/core/agent-docs.md`.
4. Supporting files: `references/core/supporting-files.md`.
5. Final verification: `references/core/verify.md`.

Then load only the matching stack references:

- **Python**: `references/languages/python/pyproject.md`, `references/languages/python/pre-commit.md`, `references/languages/python/layout-and-tests.md`, `references/languages/python/project-docs.md`, `references/languages/python/supporting-files.md`, `references/languages/python/verify.md`.
- **Hardened Python security**: additionally `references/languages/python/security.md`.
- **TypeScript React**: `references/languages/typescript-react/package-and-tooling.md`, `references/languages/typescript-react/layout-and-style.md`, `references/languages/typescript-react/verify.md`.
- **FastAPI**: Python references plus `references/frameworks/python/fastapi.md`.
- **React/Vite**: TypeScript React references plus `references/frameworks/typescript-react/react-vite.md`.
- **Next.js**: TypeScript React references plus `references/frameworks/typescript-react/nextjs.md`.
- **Profiles**: add one of `references/profiles/library.md`, `service.md`, `cli.md`, or `monorepo.md` when the project shape needs it.

The Python baseline comes from the previous Python-only skill. The React, Next.js, and FastAPI overlays use the public Waypoint repository as the template model: `backend/` is a `uv` FastAPI service and `frontend/` is a strict TypeScript Next.js app with `npm` scripts for `dev`, `build`, `start`, and `lint`.

## Guardrails

- **Reconcile, don't clobber.** Existing projects keep their names, dependencies, structure, and project-specific conventions unless they conflict with the requested baseline.
- **One canonical tool owner.** Avoid duplicate formatters or import sorters fighting each other.
- **Pin tools intentionally.** Use current released hook/tool versions when creating new config; do not copy stale pins blindly.
- **Lower bounds, locked once.** Runtime/tool dependencies use compatibility floors in manifests; lockfiles pin resolved versions and stay tracked.
- **Docs route agents.** Keep `AGENTS.md` short, command-focused, and honest about how to verify the repo.
- **Verify, don't assume.** End with the selected stack's lint/type/test/build commands and report what ran.
