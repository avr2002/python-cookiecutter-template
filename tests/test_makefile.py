import pytest


@pytest.fixture(scope="session")
def project():
    print("Setup")
    yield "is it yeilding?" # even if any test fails, teardown will run when yeild is used
    # return "is it returning?" # but using return will not run the teardown #noqa:ERA001
    print("Teardown")


def test_linting_passes(project):
    """
    Ensure the project passes linting.
    """
    print(project)
    assert False


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
