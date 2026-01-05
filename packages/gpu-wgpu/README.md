# gpu-wgpu

wgpu-native WebGPU bindings for Python.

## Installation

```bash
pip install gpu-wgpu
```

## Usage

```python
from gpu.wgpu import add, get_backend_name

result = add(2, 3)  # 5
backend = get_backend_name()  # "wgpu-native-dummy"
```
