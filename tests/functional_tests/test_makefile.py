"""This module contains functional tests for the Makefile.
Checks if the generated project passes linting and tests."""

import subprocess
from pathlib import Path


def test_linting_passes(project_dir: Path):
    """
    Ensure the project passes linting.

    For this test to pass, we need to:
    1. generate a project using cookiecutter template
    2. initialize a git repository in the generated project directory
    3. run `make lint:ci` in the generated project directory to check if the project passes linting

    This will verify that the project passes linting,
    our pre-commit hooks are working, the reference to pyproject.toml is correct in the pre-commit config,
    which inturn verifies that the pyproject.toml file is set up correctly for linting tools,
    and the project is set up correctly.
    """
    # Running the linting `make lint:ci` command in the project directory.
    subprocess.run(
        ["make", "lint-ci"],
        cwd=project_dir,  # This will make the command run in the project directory.
        check=True,  # This will make subprocess raise an error if the command fails.
    )


def test_tests_passes(project_dir: Path):
    """
    Ensure the project's tests pass.

    For this test to pass, we need to:
    1. generate a project using the defined pytest `project_dir` fixture.
    2. install our test dependencies in the generated project directory
    3. run `make test`/`make test-wheel-locally` in the project dir to check if the tests pass

    `make test` will run the tests against the generated project template, but
    `make test-wheel-locally` will actually build the wheel file and run the tests against that
    wheel file in a separate virtual environment.
    """
    subprocess.run(["make", "install"], cwd=project_dir, check=True)
    subprocess.run(["make", "test-wheel-locally"], cwd=project_dir, check=True)
