import json
import subprocess
from pathlib import Path

THIS_DIR = Path(__file__).parent
PROJECT_DIR = (THIS_DIR / "../").resolve()


def test_can_generate_project():
    """
    Make test run automatically when cookie-cutting the project.
    execute: `cookiecutter <template directory> ...`
    """
    # Run cookiecutter in a subprocess, to generate automated tests
    # subprocess.run([]) and pass in a list of strings where each string in the
    # list is one of the items/arguments passed inside of our command.

    cookiecutter_config = {"default_context": {"repo_name": "test-repo"}}
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

    generated_project_dir = PROJECT_DIR / "sample" / cookiecutter_config["default_context"]["repo_name"]

    assert generated_project_dir.exists()


