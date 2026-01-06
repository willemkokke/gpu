"""Windowing system integration for GPU.

This package provides cross-platform windowing integration:
- Native platforms: interfaces with OS windowing (GLFW, SDL, etc.)
- Pyodide/browser: interfaces with browser canvas/DOM
"""

import sys

__version__ = "0.0.0"


def get_version() -> str:
    """Get the package version."""
    return __version__


def get_platform() -> str:
    """Get the current platform type.

    Returns:
        "browser" if running in Pyodide/browser,
        "native" otherwise.
    """
    if sys.platform == "emscripten":
        return "browser"
    return "native"


__all__ = ["get_platform", "get_version"]
