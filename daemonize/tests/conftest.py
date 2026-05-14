import io
import sys
import pytest

@pytest.fixture(autouse=True)
def _fix_stdin():
    """Replace pytest's DontReadFromInput with a real flushable stdin stub."""
    sys.stdin = io.TextIOWrapper(io.BufferedReader(io.BytesIO()))
    yield
    sys.stdin = sys.__stdin__
