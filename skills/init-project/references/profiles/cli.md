# CLI profile

Use when the project exposes a command-line interface.

- Add a package entry point (`[project.scripts]` for Python or `bin` for Node packages).
- Prefer Typer for Python CLIs unless the project already uses another CLI library.
- Keep command parsing thin; put behavior in testable functions.
- Document common commands in `AGENTS.md` and `README.md`.
- Add tests for argument parsing and exit behavior where practical.
