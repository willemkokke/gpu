# gpu

GPU access from Python.

## Vision

The goal of this project is to provide GPU access to as wide as the Python ecosystem as possible:

- **Native Python** - Windows, Linux, macOS (Python 3.10-3.14)
- **WebAssembly** - Pyodide, JupyterLite, browser-based Python (Python 3.12-3.13)
- **Multiple backends** - WebGPU, and potentially others in the future

## Status

This project is in the **planning stage**. The current package reserves the `gpu` namespace on PyPI while the architecture and implementation are being designed.

There is no functional code yet.

## Development

See [docs/build.md](docs/build.md) for detailed build documentation.

### Quick Start

```bash
# macOS/Linux
source activate.sh

# Windows PowerShell
. .\activate.ps1
```

The activate script automatically installs all development tools (uv, cmake, ninja, emscripten) into the `.tools` folder.

### Prerequisites

See [PREREQUISITES.md](PREREQUISITES.md) for system-level requirements (compiler toolchains, etc.).

## License

MIT
