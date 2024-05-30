"""Example fixture for the test session."""

import subprocess
from uuid import uuid4

import pytest

from tests.consts import PROJECT_DIR


@pytest.fixture(scope="session")
def test_session_id() -> str:
    """Generate a unique session id for the test session."""
    test_session_id = str(PROJECT_DIR) + str(uuid4())[:6]

    subprocess.run(
        ["make", "lint-ci"],
        cwd=PROJECT_DIR,  # This will make the command run in the project directory.
        check=False,  # we expect this to fail due to formatting errors
    )

    return test_session_id
