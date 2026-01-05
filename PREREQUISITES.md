# Prerequisites

This document lists the system-level prerequisites that must be installed before using the development environment. The activate scripts will automatically install managed tools (uv, cmake, ninja, emscripten, python, node).

## All Platforms

| Tool | Purpose |
|------|---------|
| git | Clone repositories, version control |

## Optional (for local CI testing)

| Tool   | Purpose                   | Install                                                     |
|--------|---------------------------|-------------------------------------------------------------|
| Docker | Container runtime for act | [docker.com/get-docker](https://docs.docker.com/get-docker/) |

## Windows

| Tool | Purpose | Install |
|------|---------|---------|
| MSVC Build Tools | C/C++ compiler | `winget install Microsoft.VisualStudio.2022.BuildTools` |
| Windows SDK | Platform headers/libs | Included with Build Tools |

### Installation

```powershell
# Option 1: winget (recommended)
winget install Microsoft.VisualStudio.2022.BuildTools

# Option 2: Silent install with specific workload
vs_BuildTools.exe --quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
```

### Notes

- MinGW is NOT supported for Python extensions (C runtime mismatch since Python 3.5)
- Download size: ~2-6GB
- Requires the "Desktop development with C++" workload

## Linux

| Tool | Purpose | Install |
|------|---------|---------|
| GCC/G++ | C/C++ compiler | Package manager |
| python3-dev | Python headers | Package manager |

### Installation by Distribution

```bash
# Debian/Ubuntu
sudo apt install build-essential python3-dev

# Fedora/RHEL/CentOS
sudo dnf install gcc gcc-c++ python3-devel

# Arch Linux (headers included with python)
sudo pacman -S base-devel
```

## macOS

| Tool | Purpose | Install |
|------|---------|---------|
| Xcode Command Line Tools | Apple Clang + macOS SDK | `xcode-select --install` |

### Installation

```bash
xcode-select --install
```

### Notes

- Requires user interaction (license agreement dialog)
- Full Xcode is NOT required (only Command Line Tools)
- Python headers are included with Command Line Tools

## Verification

After installing prerequisites, verify your setup:

```bash
# All platforms
git --version

# Windows (PowerShell)
cl  # Should show MSVC version

# Linux
gcc --version
python3-config --includes

# macOS
clang --version
```

## Managed Tools

The following tools are automatically installed by the activate scripts:

| Tool | Version | Purpose |
|------|---------|---------|
| uv | 0.9.18 | Python package manager |
| cmake | 4.2.1 | Build system generator |
| ninja | 1.13.2 | Fast build system |
| emscripten | 4.0.9 | WebAssembly compiler |
| python | 3.13.3 | Python interpreter (from emsdk) |
| node | 22.16.0 | Node.js runtime (from emsdk) |
| act | 0.2.83 | GitHub Actions runner (optional, requires Docker) |
