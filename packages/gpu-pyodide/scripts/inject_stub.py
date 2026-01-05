#!/usr/bin/env python3
"""Inject nanobind-generated stub into a Pyodide wheel.

This script:
1. Checks if stub already exists in source directory (from cp313 build)
2. If not, creates a Pyodide venv and generates the stub
3. Injects the stub into the wheel

Usage:
    python scripts/inject_stub.py path/to/wheel.whl
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path


def find_pyodide() -> str:
    """Find pyodide executable."""
    pyodide = shutil.which("pyodide")
    if pyodide:
        return pyodide
    raise FileNotFoundError("pyodide executable not found in PATH")


def main() -> int:
    """Inject stub into wheel."""
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <wheel_path>", file=sys.stderr)
        return 1

    wheel_path = Path(sys.argv[1]).resolve()
    if not wheel_path.exists():
        print(f"Error: Wheel not found: {wheel_path}", file=sys.stderr)
        return 1

    print(f"Injecting stub into: {wheel_path}")

    # Check if stub already exists in source directory (from cp313 build or native)
    script_dir = Path(__file__).resolve().parent
    source_stub = script_dir.parent / "src" / "gpu" / "pyodide" / "_pyodide.pyi"

    if source_stub.exists() and source_stub.stat().st_size > 0:
        stub_size = source_stub.stat().st_size
        print(f"Using existing stub from {source_stub} ({stub_size} bytes)")
        stub_content = source_stub.read_text()
    else:
        # Generate stub inside Pyodide
        print("No existing stub found, generating...")
        pyodide = find_pyodide()
        print(f"Using pyodide: {pyodide}")

        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir = Path(tmpdir)
            venv_path = tmpdir / ".venv-pyodide"
            stub_path = tmpdir / "_pyodide.pyi"

            # Create Pyodide venv
            print("Creating Pyodide venv...")
            subprocess.run(
                [pyodide, "venv", str(venv_path)],
                check=True,
                capture_output=True,
            )

            # Install wheel + nanobind
            print("Installing wheel and nanobind...")
            python = venv_path / "bin" / "python"
            result = subprocess.run(
                [str(python), "-m", "pip", "install", str(wheel_path), "nanobind"],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                print(f"pip install failed: {result.stderr}", file=sys.stderr)
                return 1

            # Generate stub using nanobind CLI
            print("Generating stub...")
            result = subprocess.run(
                [
                    str(python),
                    "-m",
                    "nanobind.stubgen",
                    "-m",
                    "gpu.pyodide._pyodide",
                    "-o",
                    str(stub_path),
                ],
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                print(f"Stubgen failed: {result.stderr}", file=sys.stderr)
                return 1

            if not stub_path.exists() or stub_path.stat().st_size == 0:
                print("Error: Stub generation produced empty file", file=sys.stderr)
                return 1

            stub_content = stub_path.read_text()
            print(f"Generated stub ({len(stub_content)} bytes)")

            # Copy to source directory for future builds
            print(f"Copying stub to {source_stub}")
            source_stub.write_text(stub_content)

    # Check if stub already exists in wheel (included from source during build)
    stub_in_wheel = "gpu/pyodide/_pyodide.pyi"
    with zipfile.ZipFile(wheel_path, "r") as whl:
        if stub_in_wheel in whl.namelist():
            print("Stub already exists in wheel, skipping injection")
            print("Done!")
            return 0

    # Inject stub into wheel
    print("Injecting stub into wheel...")
    with zipfile.ZipFile(wheel_path, "a") as whl:
        whl.writestr(stub_in_wheel, stub_content)

    print("Done!")
    return 0


if __name__ == "__main__":
    sys.exit(main())
