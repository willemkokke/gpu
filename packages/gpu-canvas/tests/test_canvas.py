import sys

from gpu.canvas import get_platform, get_version


def test_get_version() -> None:
    assert get_version() == "0.0.0"


def test_get_platform() -> None:
    platform = get_platform()
    if sys.platform == "emscripten":
        assert platform == "browser"
    else:
        assert platform == "native"
