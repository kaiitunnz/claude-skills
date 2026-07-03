# Source layout, tests, and async

## src layout

Package lives under `src/`, not at the repo root, so imports resolve through the packaged layout and tests can't accidentally pick up stray top-level modules sitting in the repo root.

```
src/my_project/__init__.py
tests/__init__.py
tests/conftest.py        # only if there's shared fixture/marker setup
README.md
```

This pairs with `pythonpath = ["src"]` and `testpaths = ["tests"]` in `[tool.pytest.ini_options]` and `where = ["src"]` in setuptools' package discovery.

## Async test mode (only if async was chosen)

Pick one convention and configure it:

- **pytest-asyncio, auto mode** — least ceremony. Add to `[tool.pytest.ini_options]`:
  ```toml
  asyncio_mode = "auto"
  ```
  Every `async def test_*` then runs without per-test decorators.
- **anyio backend fixture** — when the code already uses anyio. Add a `conftest.py` fixture and mark tests with `@pytest.mark.anyio`:
  ```python
  @pytest.fixture
  def anyio_backend() -> str:
      return "asyncio"
  ```

## `conftest.py`

Add one when the suite needs shared setup. Common, justified uses:

- **Register custom markers** so `--strict-markers` doesn't error:
  ```python
  def pytest_configure(config):
      config.addinivalue_line("markers", "gpu: requires GPU/CUDA hardware")
  ```
- **Default env isolation** for tests that must not touch real hardware/services, e.g. `os.environ.setdefault("CUDA_VISIBLE_DEVICES", "")`.
- **Import-time stubs** for third-party SDKs that do network I/O on import — insert a minimal stub module into `sys.modules` before any project module is imported, so the suite never makes real calls.

Keep `conftest.py` minimal — it exists for cross-cutting fixtures and collection config, not as a dumping ground.
