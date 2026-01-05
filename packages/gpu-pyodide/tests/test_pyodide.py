import sys

import pytest

# Skip all tests if not running in Pyodide
pytestmark = pytest.mark.skipif(
    sys.platform != "emscripten",
    reason="gpu-pyodide only works in Pyodide/browser environments",
)


def test_add() -> None:
    from gpu.pyodide import add

    assert add(2, 3) == 5


def test_backend_name() -> None:
    from gpu.pyodide import get_backend_name

    assert get_backend_name() == "dawn-emscripten-dummy"


def test_import_error_on_native() -> None:
    """Test that importing on native platforms raises ImportError."""
    if sys.platform == "emscripten":
        pytest.skip("This test is for native platforms only")

    with pytest.raises(ImportError, match="only available in Pyodide"):
        import gpu.pyodide  # noqa: F401
