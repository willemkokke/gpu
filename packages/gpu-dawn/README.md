# gpu-dawn

Dawn WebGPU bindings for Python.

## Installation

```bash
pip install gpu-dawn
```

## Usage

```python
from gpu.dawn import add, get_backend_name

result = add(2, 3)  # 5
backend = get_backend_name()  # "dawn-dummy"
```
