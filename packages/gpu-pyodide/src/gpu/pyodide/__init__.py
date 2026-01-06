"""Dawn WebGPU bindings for Pyodide/browser.

This package provides WebGPU bindings using the Dawn Emscripten build,
specifically for use in Pyodide/browser environments.
"""

import sys

# Check if running in Pyodide
if sys.platform != "emscripten":
    raise ImportError(
        "gpu-pyodide is only available in Pyodide/browser environments. "
        "For native platforms, use gpu-dawn or gpu-wgpu instead."
    )

from gpu.pyodide._pyodide import add, get_backend_name

__all__ = ["add", "get_backend_name"]
