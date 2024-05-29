import shutil
from pathlib import Path

import pytest
from tests.utils.project import generate_project


def test_can_generate_project(project_dir: Path):
    """
    Ensure the project  directory exists.
    """
    assert project_dir.exists()
