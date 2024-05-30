"""conftest.py is a file that is used to configure pytest."""

import sys
from pathlib import Path

# conftest.py is the first file that gets executed by pytest.

# Appending this directory to the sys.path allows us to import modules from the parent directory.
# when running pytest on a targeted test like:
# `pytest tests/test_cookiecut_generate_project.py::test_can_generate_project`
THIS_DIR = Path(__file__).parent
sys.path.insert(0, str(THIS_DIR.parent))

# "pytest_plugins" is a list of plugins/import paths that will be automatically loaded by pytest.
# Also we do not need to add __init__.py files in the fixtures directory.
pytest_plugins = [
    "tests.fixtures.example_fixture",
]
