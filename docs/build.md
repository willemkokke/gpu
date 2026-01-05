# Build Documentation

This document covers the development environment setup and build process.

## Quick Start

```bash
# macOS/Linux
source activate.sh

# Windows PowerShell
. .\activate.ps1
```

The activate script will automatically install all managed tools (uv, cmake, ninja, emscripten, python, node) into the `.tools` folder.

## Shared Tools Folder

By default, tools are installed into `.tools/` within the repository. For multiple checkouts or projects, you can share a common tools folder to save disk space and download time.

Create a `.env.local` file (not committed to git, already in .gitignore):

```bash
# Share tools across multiple checkouts
TOOLS_FOLDER=~/.shared-tools
```

With this configuration:
- All checkouts share the same tools installation
- Saves significant disk space (emscripten alone is ~1GB)
- Reduces initial setup time on new checkouts

## Automatic Version Management

Tool versions are tracked in `.env`:

```bash
TOOLS_VERSION_UV=0.9.18
TOOLS_VERSION_CMAKE=4.2.1
TOOLS_VERSION_NINJA=1.13.2
TOOLS_VERSION_EMSDK=4.0.9
```

When checking out different commits:
- Each commit has its own `.env` with the versions used at that time
- Running `source activate.sh` installs those specific versions
- Multiple versions coexist: `.tools/cmake@4.2.1/`, `.tools/cmake@3.28.0/`, etc.
- Enables reproducible builds across git history

## CI Caching

The tools folder structure is designed for efficient CI caching:

### GitHub Actions

```yaml
- name: Cache tools
  uses: actions/cache@v4
  with:
    path: .tools
    key: tools-${{ runner.os }}

- name: Activate environment
  run: source activate.sh
  shell: bash
```

Benefits:

- Shared cache across workflow runs
- Significant CI time savings (emscripten clone alone takes minutes)
- Version changes are handled automatically (new versions install alongside existing ones)

## Pyodide Builds

For WebAssembly/Pyodide builds, the project targets the pyodide_2025_0 ABI:

| ABI | Python | Emscripten |
|-----|--------|------------|
| pyodide_2025_0 | 3.13 | 4.0.9 |

The emscripten version in `.env` (4.0.9) matches this ABI.

## Python Version Support

| Platform            | Python Versions              |
|---------------------|------------------------------|
| Windows/Linux/macOS | 3.10, 3.11, 3.12, 3.13, 3.14 |
| Pyodide 2025        | 3.13                         |

The project uses [cibuildwheel](https://cibuildwheel.readthedocs.io/) for cross-platform wheel builds.

## Directory Structure

```
.tools/                      # Managed tools (git-ignored)
├── uv@0.9.18/              # uv package manager
├── cmake@4.2.1/            # CMake build system
├── ninja@1.13.2/           # Ninja build system
├── emsdk@4.0.9/            # Emscripten SDK
│   └── upstream/
│       └── emscripten/     # emcc, em++, etc.
└── uv/                     # uv data directories
    ├── cache/
    ├── tools/
    └── python/
```

## Troubleshooting

### Tools not found after activation

Ensure you're sourcing (not executing) the activate script:

```bash
# Correct
source activate.sh

# Incorrect (runs in subshell, changes don't persist)
./activate.sh
bash activate.sh
```
