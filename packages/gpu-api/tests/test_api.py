"""Tests for gpu.api module."""

from gpu import api


def test_hello_returns_string() -> None:
    """Test that hello() returns the expected greeting."""
    result = api.hello()
    assert result == "Hello from gpu.api!"
