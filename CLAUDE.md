# Claude Code Instructions

This file provides context for Claude Code when working in this repository.

## Project Overview

GPU access from Python - a unified WebGPU API for Python across all platforms:

- **Native Python**: Windows, Linux, macOS (Python 3.10-3.14)
- **WebAssembly**: Pyodide, JupyterLite, browser-based Python (Python 3.12-3.13)

## Package Structure

Monorepo with uv workspace. All packages are in `packages/`:

| Package | Description | Type |
|---------|-------------|------|
| `gpu-api` | Abstract WebGPU API (backend-agnostic) | Pure Python |
| `gpu-dawn` | Dawn (Google Chrome) WebGPU backend | Native extension |
| `gpu-wgpu` | wgpu-native (Rust) WebGPU backend | Native extension |
| `gpu-pyodide` | Dawn Emscripten build for Pyodide/browser | WASM only |
| `gpu-canvas` | Cross-platform windowing | Mixed |
| `gpu-wesl` | WESL shader preprocessing | Pure Python |

## Environment Setup

**Always source the activate script before running any commands:**

```bash
# macOS/Linux
source activate.sh

# Windows PowerShell
. .\activate.ps1
```

The activate script:
1. Installs development tools (uv, cmake, ninja, emscripten, act) into `.tools/`
2. Sets up PATH and environment variables
3. Creates/syncs the Python virtual environment (`.venv/`)

Note: The venv is NOT automatically activated to allow working with different Python versions. Use `uv run` to execute commands in the venv.

## Commands

After `source activate.sh`, use `uv run` to execute Python tools:

### Linting and Type Checking

```bash
source activate.sh

# Run ruff linting
uv run ruff check .

# Run ruff formatting check
uv run ruff format --check .

# Fix formatting issues
uv run ruff format .

# Run basedpyright type checking
uv run basedpyright
```

### Testing

```bash
source activate.sh

# Run all tests
uv run pytest packages/*/tests -v

# Run tests for a specific package
uv run pytest packages/gpu-dawn/tests -v

# Run tests via duty
uv run duty test
```

### Building

```bash
source activate.sh

# Build a specific package
uv build packages/gpu-api

# Build WASM/Pyodide wheel (requires emscripten)
uv run duty build_wasm

# Build native wheels with cibuildwheel
uv run duty wheels
```

### CI

```bash
source activate.sh

# Run GitHub Actions locally (requires Docker)
uv run duty ci

# Run without offline mode
uv run duty ci --no-offline
```

## Type Checking Configuration

- Uses `basedpyright` (not standard pyright)
- Configuration in `pyproject.toml` under `[tool.basedpyright]`
- Only checks authored code via explicit `include` paths
- Native extensions use `.pyi` stub files for type hints

## Key Files

- `pyproject.toml` - Workspace configuration, tool settings
- `duties.py` - Development tasks (test, build, release)
- `activate.sh` / `activate.ps1` - Environment setup scripts
- `docs/PLATFORMS.md` - Platform support matrix
- `.github/workflows/` - CI/CD configuration

## Native Extensions

The `gpu-dawn` and `gpu-wgpu` packages contain native extensions:
- Source in `src/gpu/{package}/_*.pyx` (Cython) or C/C++
- Type stubs in `src/gpu/{package}/_*.pyi`
- Build with scikit-build-core

For `gpu-pyodide`:
- Only runs in Pyodide/Emscripten environment (`sys.platform == "emscripten"`)
- Type stubs in `src/gpu/pyodide/_pyodide.pyi`

## Git Commit Rules

Never add the following to commit messages:

- "Co-Authored-By" lines
- "Generated with" lines or badges
- Any AI attribution

This is a hard rule with no exceptions.
