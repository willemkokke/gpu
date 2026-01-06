from gpu.wesl import get_version


def test_get_version() -> None:
    assert get_version() == "0.0.0"
