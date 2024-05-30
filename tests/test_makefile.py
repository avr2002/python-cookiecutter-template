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


def test_tests_pass():
    """
    Ensure the project's tests pass.
    """
    ...


def test_install_succeeds():
    """
    Ensure the project installs successfully.
    """
    ...


# """
# Setup:
# 1. generate a project using cookiecutter template
# 2. create a virtual environment and intall project dependencies

# Tests:
# 3. run test
# 4. run linting

# Cleanup/Teardown:
# 5. remove virtual environment
# 6. remove generated project
# """
