import shutil
from pathlib import Path

import pytest
from tests.utils.project import generate_project


@pytest.fixture(scope="session")
def project_dir() -> Path:
    # Setup
    template_values = {"repo_name": "test-repo"}
    generated_project_dir: Path = generate_project(template_values=template_values)
    yield generated_project_dir

    # Teardown
    shutil.rmtree(generated_project_dir.parent)


def test_can_generate_project(project_dir: Path):
    """
    Ensure the project  directory exists.
    """
    assert project_dir.exists()
