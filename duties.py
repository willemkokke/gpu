"""Development tasks for the gpu project."""

from __future__ import annotations

from typing import TYPE_CHECKING

import os
import shutil
import time

from duty import duty

if TYPE_CHECKING:
    from duty import Context


@duty
def test(ctx: Context) -> None:
    """Run tests against installed packages."""
    ctx.run(
        (
            "uv run pytest "
            "packages/gpu-api/tests "
            "packages/gpu-dawn/tests "
            "packages/gpu-wgpu/tests "
            "packages/gpu-wesl/tests "
            "packages/gpu-canvas/tests "
            "-v"
        ),
        title="Running tests",
    )


@duty
def build(ctx: Context) -> None:
    """Build wheel for gpu-api."""
    ctx.run("uv build packages/gpu-api", title="Building gpu-api wheel")


PYPI_CONFIG = {
    "testpypi": {
        "url": "https://test.pypi.org/legacy/",
        "token_env": "TEST_PYPI_TOKEN",
    },
    "pypi": {
        "url": "https://upload.pypi.org/legacy/",
        "token_env": "PYPI_TOKEN",
    },
}


@duty
def release(ctx: Context, repository: str = "testpypi") -> None:
    """Release to PyPI (default: test.pypi.org).

    Args:
        ctx: Duty context.
        repository: PyPI repository (testpypi or pypi).
    """
    config = PYPI_CONFIG.get(repository)
    if config:
        url = config["url"]
        token = os.environ.get(config["token_env"])
        if token:
            os.environ["UV_PUBLISH_TOKEN"] = token
    else:
        url = repository

    ctx.run("uv build packages/gpu-api", title="Building wheel")
    ctx.run(
        f"uv publish --publish-url {url}",
        title=f"Publishing to {repository}",
    )


@duty
def ci(ctx: Context, *, offline: bool = True) -> None:
    """Run GitHub Actions locally using act.

    Args:
        ctx: Duty context.
        offline: Run in offline mode (default: True). Set to False to pull images.
    """
    start = time.time()
    cmd = "act --action-offline-mode" if offline else "act"
    try:
        ctx.run(cmd, title="Running GitHub Actions locally", capture=False)
    finally:
        duration = time.time() - start
        minutes, seconds = divmod(int(duration), 60)
        print(f"\nTotal duration: {minutes}m {seconds}s")


@duty
def build_wasm(ctx: Context) -> None:
    """Build gpu-dawn wheel for Pyodide/WebAssembly."""
    shutil.rmtree("dist/wasm", ignore_errors=True)
    ctx.run(
        "uv run pyodide build packages/gpu-dawn --outdir dist/wasm",
        title="Building gpu-dawn for Pyodide",
    )
    # Workaround: scikit-build-core <0.11.7 on macOS produces wrong platform tag
    # (macosx instead of emscripten). Fixed in PR #1196, will be in 0.11.7.
    # See: https://github.com/scikit-build/scikit-build-core/issues/920
    # TODO: Remove when scikit-build-core>=0.11.7 is released
    ctx.run(
        'uv run python -c "'
        + "import glob, subprocess; "
        + "wheels = glob.glob('dist/wasm/*.whl'); "
        + "[subprocess.run(['uv', 'run', 'wheel', 'tags', '--remove', "
        + "'--platform-tag', 'emscripten_4_0_9_wasm32', w]) for w in wheels]"
        + '"',
        title="Fixing wheel platform tag",
    )


@duty
def test_wasm(ctx: Context) -> None:
    """Run tests in Pyodide virtual environment."""
    # Clean and recreate pyodide venv
    shutil.rmtree(".venv-pyodide", ignore_errors=True)
    ctx.run("uv run pyodide venv .venv-pyodide", title="Creating Pyodide venv")
    ctx.run(
        ".venv-pyodide/bin/pip install dist/wasm/*.whl pytest",
        title="Installing wheel in Pyodide venv",
    )
    ctx.run(
        ".venv-pyodide/bin/python -m pytest packages/gpu-dawn/tests -v",
        title="Running tests in Pyodide",
    )


@duty
def build_all(ctx: Context) -> None:
    """Build both native and Pyodide wheels."""
    ctx.run("uv build packages/gpu-dawn", title="Building native wheel")
    build_wasm(ctx)


@duty
def wheels(ctx: Context, platform: str = "") -> None:
    """Build wheels using cibuildwheel locally.

    Args:
        ctx: Duty context.
        platform: Target platform (linux, macos, windows, pyodide). Empty for current.
    """
    cmd = "uv run cibuildwheel packages/gpu-dawn --output-dir wheelhouse"
    if platform:
        cmd += f" --platform {platform}"
    ctx.run(cmd, title="Building wheels with cibuildwheel")
