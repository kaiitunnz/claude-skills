# Hardened security (only if chosen)

Add this tier when the project handles untrusted input, subprocesses, or deserialization. It layers `bandit` source auditing on top of the gitleaks secret scan that the minimal tier already provides.

## Setup

- Add `bandit` to the `dev` dependency group.
- Add a `[tool.bandit]` block to `pyproject.toml` listing project-wide `skips`, each with a one-line comment justifying why it's safe **for this codebase**. Don't copy another project's skip list verbatim — every skip must be true here.

```toml
[tool.bandit]
skips = [
  "B101",  # assert: internal invariants, not shipped with -O
  # ... only skips that genuinely apply to this project
]
```

## Policy

Every bandit finding gets one of: a source-level fix, a documented `[tool.bandit]` skip, or a per-line `# nosec BXXX` with a one-line written rationale at the call site. A bare `# nosec` (no rule code, no reason) is disallowed. When a documented skip stops being true, remove it and fix the call sites — don't widen the skip list silently.

## Recurring rules to record in `docs/CODE_STYLE.md`

- **B113** — every `requests.get/post/...` passes `timeout=`. Hung connections are a DoS.
- **B202** — `tarfile.extractall(..., filter="data")` (3.12+). For zipfile, validate each member resolves under the destination and extract per-member; never `extractall` an untrusted archive.
- **B310** — don't `urllib.request.urlopen`; use `requests` and validate the URL scheme (`http`/`https`) first.
- **B324** — `hashlib.md5(..., usedforsecurity=False)` for cache-key/fingerprint use; never MD5 across a security boundary.
- **B506** — `yaml.safe_load`, never `yaml.load(..., Loader=FullLoader)`.
- **B603/B607** — every `subprocess.*` call: argv list, no `shell=True`, absolute path (via `shutil.which()`); per-line `# nosec B603` with a rationale. Prefer a vendored SDK over shelling out.
- **B614** — `torch.load(..., weights_only=True)`. Pickle deserialization is RCE waiting to happen.
- **B701** — `Environment(autoescape=select_autoescape())`; the default `False` is unsafe even for non-HTML templates.
- **B108** — use `tempfile.gettempdir()` / `tempfile.NamedTemporaryFile`; the literal `"/tmp"` in source is forbidden.

If the project exports pinned `requirements.txt` files, also run `pip-audit` against them for CVE scanning, and track any `--ignore-vuln` advisory with a written upgrade-blocker.
