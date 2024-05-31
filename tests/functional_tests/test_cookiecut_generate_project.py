"""Tests if the project directory is generated successfully."""

from pathlib import Path


def test_can_generate_project(project_dir: Path):
    """
    Ensure the project  directory exists.
    """
    assert project_dir.exists()
