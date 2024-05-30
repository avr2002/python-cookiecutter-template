import subprocess
from pathlib import Path



def test_linting_passes(project_dir: Path):
    """
    Ensure the project passes linting.
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
