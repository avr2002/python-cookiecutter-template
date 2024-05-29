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