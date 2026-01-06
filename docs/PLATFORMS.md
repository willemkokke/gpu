# Platform Support

This document describes the platform coverage for the GPU project packages.

## Overview

The GPU project provides a unified WebGPU API for Python across all platforms where Python runs - native desktop, servers, and web browsers via Pyodide.

**End users choose the backend:**

- **Native Desktop/Server**: Dawn (Google) or wgpu-native (Rust)
- **Browser/Pyodide**: Dawn Emscripten build via gpu-pyodide

## Platform Tiers

| Tier       | Platforms                                                         | Priority    |
|------------|-------------------------------------------------------------------|-------------|
| **Tier 1** | Linux x64/ARM64, Windows x64/ARM64, macOS x64/ARM64, Pyodide/WASM | Must have   |
| **Tier 2** | Android, iOS, 32-bit (Linux i686, Windows x86)                    | If interest |

## Package x Platform Matrix

| Package | Linux x64 | Linux ARM64 | Win x64 | Win ARM64 | macOS x64 | macOS ARM64 | Pyodide |
|---------|-----------|-------------|---------|-----------|-----------|-------------|---------|
| gpu-api | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| gpu-dawn | Yes | Yes | Yes | Yes | Yes | Yes | No |
| gpu-wgpu | Yes | Yes | Yes | Yes | Yes | Yes | No |
| gpu-pyodide | No | No | No | No | No | No | Yes |
| gpu-canvas | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| gpu-wesl | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

## Binary Sources

### Dawn (Google's WebGPU)

**Primary: [eliemichel/dawn-prebuilt](https://github.com/eliemichel/dawn-prebuilt/releases)**

- Platforms: Windows/Linux/macOS x64, macOS ARM64, Emscripten
- Versioning: Chromium revisions (e.g., chromium/7187)
- Format: Shared libraries (.dll, .so, .dylib) + Emscripten packages

**Secondary: [mmozeiko/build-dawn](https://github.com/mmozeiko/build-dawn/releases)** (Windows ARM64)

- Weekly automated builds
- Windows ARM64 support

### wgpu-native (Rust WebGPU)

**Official: [gfx-rs/wgpu-native](https://github.com/gfx-rs/wgpu-native/releases)**

- Platforms: All Tier 1 native + Windows ARM64
- Versioning: Semantic (e.g., v27.0.2.0)
- Format: Static + shared libraries with headers

## Wheels Built

### Pure Python Packages

- `gpu-api`: `py3-none-any`
- `gpu-wesl`: `py3-none-any`

### Native Extension Packages

**gpu-dawn and gpu-wgpu:**

- `cp310-cp314 x manylinux_2_28_x86_64`
- `cp310-cp314 x manylinux_2_28_aarch64`
- `cp310-cp314 x win_amd64`
- `cp311-cp314 x win_arm64` (Python 3.11+ only)
- `cp310-cp314 x macosx_10_14_x86_64`
- `cp310-cp314 x macosx_11_0_arm64`

**gpu-pyodide:**

- `cp312-cp313 x emscripten_wasm32`

**gpu-canvas:**

- TBD (depends on windowing approach)

## Testing Matrix

| Package | Native Linux | Native Windows | Native macOS | Pyodide |
|---------|--------------|----------------|--------------|---------|
| gpu-api | Yes | Yes | Yes | Yes |
| gpu-dawn | Yes | Yes | Yes | No |
| gpu-wgpu | Yes | Yes | Yes | No |
| gpu-pyodide | No | No | No | Yes |
| gpu-canvas | Yes | Yes | Yes | Yes |
| gpu-wesl | Yes | Yes | Yes | Yes |
