# Agent and contributor docs

Create or update `AGENTS.md` as the cross-agent routing doc. Add a thin `CLAUDE.md` that imports it when the user wants Claude Code compatibility.

## `AGENTS.md`

Keep it short and operational:

- What the project is.
- Project structure by package/app area.
- Setup, dev, lint/type, test, build, and verify commands.
- Stack-specific style rules that reviewers should enforce.
- Commit and PR conventions if the repo has them.
- Security/config notes, especially env files and secrets.

For larger projects, link to deeper docs rather than loading every rule into `AGENTS.md`.

## `CLAUDE.md`

Use a one-line import when the repo follows the cross-agent convention:

```markdown
@AGENTS.md
```

## `CONTRIBUTING.md`

Add only when useful for humans. Cover setup, dependency sync, hooks, tests, and commit/PR conventions.
