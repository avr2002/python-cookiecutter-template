"""
This module contains utility functions for generating and initializing a project using a cookiecutter template.

The functions in this module provide the necessary functionality to generate a project based on a
specified cookiecutter template. It includes functions to initialize a git repository in
the generated project directory and generate the project using the cookiecutter template.

Functions:
- initialize_git_repo(repo_dir: Path) -> None:
    Initializes a git repository in the generated project directory.

- generate_project(template_values: Dict[str, str], test_session_id: str) -> Path:
    Generates a project using the cookiecutter template.

Note: The `generate_project` function runs the `cookiecutter` command in a subprocess to generate the project.
It creates a configuration file with the desired context and passes it to the `cookiecutter` command.
"""

import json
import subprocess
from copy import deepcopy
from pathlib import Path
from typing import Dict

from tests.consts import PROJECT_DIR


def initialize_git_repo(repo_dir: Path) -> None:
    """
    Initialize a git repository in the generated project directory
    for pre-commit(.pre-commit-config.yaml) to work.
    """
    # intialize git repository
    subprocess.run(["git", "init"], cwd=repo_dir, check=True)
    # create a main branch
    subprocess.run(["git", "branch", "-m", "main"], cwd=repo_dir, check=True)
    # add all files to the git repository
    subprocess.run(["git", "add", "--all"], cwd=repo_dir, check=True)
    # commit the changes
    subprocess.run(["git", "commit", "-m", "'feat: initial commit by pytest'"], cwd=repo_dir, check=True)


def generate_project(template_values: Dict[str, str], test_session_id: str) -> Path:  # type: ignore
    """
    Generates a project using the cookiecutter template.

    This function runs the `cookiecutter` command in a subprocess to generate a project based on
    the specified template. It creates a configuration file with the desired context and passes it
    to the `cookiecutter` command.
    """
    # When dealing with mutable objects, such as lists and dictionaries, Python passes a reference to
    # the object instead of copying its value.
    # This means changes within the function are reflected outside it.

    # so it's better to create a deepcopy of the object within the function to avoid
    # changing the original object
    template_values: Dict[str, str] = deepcopy(template_values)  # type: ignore[no-redef]
    cookiecutter_config = {"default_context": template_values}

    # creating this config file is necessary to pass the context to cookiecutter without user input
    # which is required for running tests otherwise it will try to prompt for user input and our
    # automated tests will fail

    cookiecutter_config_fpath = (
        PROJECT_DIR / f"tests/cookiecutter_test_configs/cookiecutter-test-config-{test_session_id}.json"
    )
    # create the parent directory(cookiecutter_test_configs) of the config file, if it doesn't exist
    cookiecutter_config_fpath.parent.mkdir(parents=True, exist_ok=True)
    cookiecutter_config_fpath.write_text(json.dumps(cookiecutter_config))

    cmd = [
        "cookiecutter",
        str(PROJECT_DIR),
        "--output-dir",
        str(PROJECT_DIR / "sample"),
        "--no-input",
        "--config-file",
        str(cookiecutter_config_fpath),
    ]
    print("COMMAND:", " ".join(cmd))
    subprocess.run(cmd, check=True)

    generated_repo_dir = PROJECT_DIR / "sample" / cookiecutter_config["default_context"]["repo_name"]
    return generated_repo_dir
