# gpu-pyodide

Dawn WebGPU bindings for Pyodide/browser environments.

This package uses the Dawn Emscripten build to provide WebGPU bindings specifically for Pyodide. For native platforms (Linux, Windows, macOS), use `gpu-dawn` or `gpu-wgpu` instead.

## Installation

In a Pyodide environment:

```python
import micropip
await micropip.install("gpu-pyodide")
```

## Usage

```python
from gpu.pyodide import add, get_backend_name

result = add(2, 3)  # 5
backend = get_backend_name()  # "dawn-emscripten-dummy"
```

## Note

This package will raise an `ImportError` if imported on native platforms. Use the appropriate native backend package instead:

- `gpu-dawn` - Dawn backend for native platforms
- `gpu-wgpu` - wgpu-native backend for native platforms
