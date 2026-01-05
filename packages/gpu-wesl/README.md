# gpu-wesl

WESL extension for WGSL manipulation.

This package provides tools for working with WESL (WebGPU Extended Shader Language), an extension of WGSL that adds preprocessing and manipulation capabilities.

## Installation

```bash
pip install gpu-wesl
```

## Usage

```python
from gpu.wesl import get_version

version = get_version()  # "0.0.0"
```

## Features

- WGSL file parsing and manipulation
- WESL preprocessing extensions
- Shader composition and includes
- Works on all platforms (pure Python)
