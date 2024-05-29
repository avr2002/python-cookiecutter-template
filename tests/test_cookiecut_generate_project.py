import json
import re
import subprocess
from copy import deepcopy
from pathlib import Path
from typing import Dict
import pytest
import shutil


THIS_DIR = Path(__file__).parent
PROJECT_DIR = (THIS_DIR / "../").resolve()


@pytest.fixture(scope="session")
def project_dir() -> Path:
    # Setup
    template_values = {"repo_name": "test-repo"}
    generated_project_dir: Path = generate_project(template_values=template_values)
    yield generated_project_dir
    
    # Teardown
    shutil.rmtree(generated_project_dir.parent)
    


def generate_project(template_values: Dict[str, str]) -> Path:  # type: ignore
    """
    Generates a project using the cookiecutter template.

    This function runs the `cookiecutter` command in a subprocess to generate a project based on the specified template.
    It creates a configuration file with the desired context and passes it to the `cookiecutter` command.
    """
    # When dealing with mutable objects, such as lists and dictionaries, Python passes a reference to 
    # the object instead of copying its value. 
    # This means changes within the function are reflected outside it.
    
    # so it's better to create a deepcopy of the object within the function to avoid 
    # changing the original object
    template_values: Dict[str, str] = deepcopy(template_values)  # type: ignore[no-redef]
    cookiecutter_config = {"default_context": template_values}
    cookiecutter_config_fpath = PROJECT_DIR / "cookiecutter-test-config.json"
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


def test_can_generate_project(project_dir: Path):
    """
    Ensure the project  directory exists.
    """
    assert project_dir.exists()

