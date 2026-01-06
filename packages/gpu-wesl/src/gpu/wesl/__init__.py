"""WESL extension for WGSL manipulation.

This package provides tools for working with WESL (WebGPU Extended Shader Language),
an extension of WGSL that adds preprocessing and manipulation capabilities.
"""

__version__ = "0.0.0"


def get_version() -> str:
    """Get the package version."""
    return __version__


__all__ = ["get_version"]
