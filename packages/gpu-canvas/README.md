# gpu-canvas

Windowing system integration for GPU.

This package provides cross-platform windowing integration for WebGPU applications:

- **Native platforms** (Linux, Windows, macOS): Interfaces with OS windowing systems (GLFW, SDL, etc.)
- **Browser/Pyodide**: Interfaces with browser canvas and DOM APIs

## Installation

```bash
pip install gpu-canvas
```

## Usage

```python
from gpu.canvas import get_version, get_platform

version = get_version()  # "0.0.0"
platform = get_platform()  # "native" or "browser"
```

## Platforms

| Platform | Windowing Backend |
|----------|-------------------|
| Linux | GLFW / SDL |
| Windows | GLFW / SDL |
| macOS | GLFW / SDL |
| Browser/Pyodide | Canvas / DOM |
