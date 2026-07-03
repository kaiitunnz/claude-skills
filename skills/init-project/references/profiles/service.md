# Service profile

Use for a long-running API, daemon, or app backend.

- Document the run command, host/port defaults, and health check if present.
- Commit safe env/config examples.
- Record config precedence: CLI flags, env vars, config file, defaults.
- Include focused tests for config loading and API boundaries.
- Add hardened security when the service handles auth, user input, subprocesses, file uploads, archive extraction, or deserialization.
