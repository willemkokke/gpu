from gpu.dawn import add, get_backend_name


def test_add() -> None:
    assert add(2, 3) == 5


def test_backend_name() -> None:
    assert get_backend_name() == "dawn-dummy"
