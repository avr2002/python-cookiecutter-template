#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # IS_PUBLIC_REPO: boolean; if true, the repository will be public, else private
    # REPO_DESCRIPTION: description of the repository
function create-repository-if-not-exists {
    local IS_PUBLIC_REPO=${IS_PUBLIC_REPO:-false}

    # Check to see if the repo. already exists; if yes, return
    echo "Checking if repository $GITHUB_USERNAME/$REPO_NAME exists..."
    gh repo view "$GITHUB_USERNAME/$REPO_NAME" &> /dev/null \
        && {
            echo "Repository $GITHUB_USERNAME/$REPO_NAME already exists. Exiting..."
            return 0
        }

    # else create the repository
    echo "Repository $GITHUB_USERNAME/$REPO_NAME does not exist, Creating..."

    if [[ "$IS_PUBLIC_REPO" == true ]]; then
        PUBLIC_OR_PRIVATE="public"
    else
        PUBLIC_OR_PRIVATE="private"
    fi

    # Check if repo name is available; if not, prompt user to enter a new name
    DEFAULT_REPO_DESCRIPTION="A repository created using the python-cookiecutter-template"
    REPO_DESC=${REPO_DESCRIPTION:-$DEFAULT_REPO_DESCRIPTION}
    gh repo create "$GITHUB_USERNAME/$REPO_NAME" "--$PUBLIC_OR_PRIVATE" --description "$REPO_DESC"
    # || {
    #     echo "Repository with name $REPO_NAME already exists."
    #     echo "Please enter a new repository name: "
    #     read -r REPO_NAME
    #     create-repository-if-not-exists
    # }

    # Create a trivial file and create an initial commit to main branch
    # This is required to open a PR to the main branch
    push-initial-readme-to-repo

    # Enable write permissions for the default workflow so that push tags can be used in github actions workflows
    # echo "Enabling write permissions for the default workflow..."
    # enable-write-workflow-permissions
    # commented above because in yaml file we can achieve the same by
    # setting the permissions as `permissions: contents: write`
}

# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # TEST_PYPI_TOKEN, PROD_PYPI_TOKEN: PyPI tokens for test-PyPI and PyPI.
    # UPSERT_PYPI_SECRETS: boolean[default=false]; if true, the PyPI secrets will be updated in the repository
function configure-repository {
    # Configure the repository with the following settings:
    # 1. Github Actions Secrets for publishing to PyPI
    local UPSERT_PYPI_SECRETS=${UPSERT_PYPI_SECRETS:-false}

    if [[ "$UPSERT_PYPI_SECRETS" == true ]]; then
        upsert-pypi-secrets
    fi

    # https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection
    # 2. Enable branch protection for the main branch, enforcing passing build on feature branches before merging
    BRANCH_NAME="main"
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/$GITHUB_USERNAME/$REPO_NAME/branches/$BRANCH_NAME/protection \
        -F "required_status_checks[strict]=true" \
        -F "required_status_checks[checks][][context]=check-version-txt" \
        -F "required_status_checks[checks][][context]=lint-format-and-static-code-checks" \
        -F "required_status_checks[checks][][context]=build-wheel-and-sdist" \
        -F "required_status_checks[checks][][context]=execute-tests" \
        -F "required_pull_request_reviews[required_approving_review_count]=0" \
        -F "enforce_admins=null" \
        -F "restrictions=null" &> /dev/null
}


# INFO: Opening a PR is not a git concept, but a GitHub concept or a Git hosting service provider concept.
# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # PACKAGE_IMPORT_NAME: e.g. if "my_package" then "import my_package"
    # AUTHOR_NAME: author name; e.g. "My Name"
    # AUTHOR_EMAIL: author email; e.g. "test@gmail.com"
function open-pull-request-with-generated-project {
    rm -rf "$REPO_NAME" ./outdir # remove the repository if it exists
    install # install the dependencies

    # To open a PR to a repository,
    # 1. Clone the repository
    gh repo clone "$GITHUB_USERNAME/$REPO_NAME"

    # 1.1 Delete existing contents of the repository
    # 1.1.1 Move the .git folder present in the cloned repository to a current directory so that
    #       we can delete the repository contents without deleting the .git folder
    mv "./$REPO_NAME/.git" "./$REPO_NAME.git.bak"

    # 1.1.2 Delete the contents of the repository
    rm -rf "./$REPO_NAME"

    # 1.1.3 Create a new directory with the same name as the repository and move the .git folder back
    mkdir "$REPO_NAME"
    mv "./$REPO_NAME.git.bak" "./$REPO_NAME/.git"

    # 1.2 Generate the project template into the repository using our cookiecutter template
    OUTDIR="./outdir"
    CONFIG_FILE_PATH="./$REPO_NAME.yaml"
    cat <<EOF > "$CONFIG_FILE_PATH"
default_context:
    repo_name: "$REPO_NAME"
    package_import_name: "$PACKAGE_IMPORT_NAME"
    author_name: "${AUTHOR_NAME:-'<Your Name>'}"
    author_email: "${AUTHOR_EMAIL:-'<Your Email>'}"
EOF
    # Run cookiecutter with the configuration file
    cookiecutter ./ \
        --output-dir "$OUTDIR" \
        --no-input \
        --config-file "$CONFIG_FILE_PATH"

    rm "$CONFIG_FILE_PATH"  # delete the configuration file
    mv "./$REPO_NAME/.git" "$OUTDIR/$REPO_NAME" # move the .git folder to the generated project
    rm -rf "$REPO_NAME" # remove the folder created in step 1.1.3

    # 2. Stage the generated files on a new feature branch, pre-commit requires the files to be staged
    cd "$OUTDIR/$REPO_NAME"

    # Create a new branch with a unique name
    UUID=$(cat /proc/sys/kernel/random/uuid)
    UNIQUE_BRANCH_NAME=feat/populating-from-cookiecutter-template-${UUID:0:6}

    git checkout -b "$UNIQUE_BRANCH_NAME"
    git add --all

    # 2.1 Apply formatting, linting autofixes to the generated files (pre-commit hooks to the staged files)
    make lint-ci || true

    # 2.2 Re-stage the modified files after applying the pre-commit hooks
    git add --all

    # 2.3 Commit the changes and push to the remote feature branch
    git commit -m "feat: populated the repository from the \`python-cookiecutter-template\`"

    # Set the remote URL with the GH_TOKEN if it exists, to work in github workflow CI environment
    if [[ -n "$GH_TOKEN" ]]; then
        git remote set-url origin "https://$GITHUB_USERNAME:$GH_TOKEN@github.com/$GITHUB_USERNAME/$REPO_NAME"
    fi

    git push origin "$UNIQUE_BRANCH_NAME"

    # 3. Open a PR to main branch using GitHub CLI
    gh pr create \
        --title "feat: populated the repository from the \`python-cookiecutter-template\`" \
        --body "Populated the repository from the \`python-cookiecutter-template\`" \
        --base main \
        --head "$UNIQUE_BRANCH_NAME" \
        --repo "$GITHUB_USERNAME/$REPO_NAME"
}

# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
function push-initial-readme-to-repo {
    rm -rf "$REPO_NAME" # remove the repository if it exists
    gh repo clone "$GITHUB_USERNAME/$REPO_NAME"
    cd "$REPO_NAME/"
    echo "# $REPO_NAME" > "README.md"
    git branch -m main || true
    git add --all
    git commit -m "feat: initial commit, repository created"

    # Set the remote URL with the GH_TOKEN if it exists, to work in github workflow CI environment
    if [[ -n "$GH_TOKEN" ]]; then
        git remote set-url origin "https://$GITHUB_USERNAME:$GH_TOKEN@github.com/$GITHUB_USERNAME/$REPO_NAME"
    fi

    git push origin main
    cd ..
    rm -rf "$REPO_NAME" # remove the cloned repository after pushing the initial commit
}


# INFO: This function is used to update the PyPI secrets in the repository.
# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # TEST_PYPI_TOKEN: PyPI token for test-PyPI
    # PROD_PYPI_TOKEN: PyPI token for PyPI
function upsert-pypi-secrets {
    local TEST_PYPI_TOKEN=${TEST_PYPI_TOKEN:-"sample_test_token"}
    local PROD_PYPI_TOKEN=${PROD_PYPI_TOKEN:-"sample_prod_token"}

    # Run the create-or-update-repo.yaml workflow to update the repository settings with PyPI secrets
    gh secret set TEST_PYPI_TOKEN \
        --body "$TEST_PYPI_TOKEN" \
        --repo "$GITHUB_USERNAME/$REPO_NAME"

    gh secret set PROD_PYPI_TOKEN \
        --body "$PROD_PYPI_TOKEN" \
        --repo "$GITHUB_USERNAME/$REPO_NAME"
}


# docs.github.com/en/rest/actions/permissions?apiVersion=2022-11-28#set-default-workflow-permissions-for-a-repository
function enable-write-workflow-permissions {
    # Enable write permissions for the default workflow so that push tags can be used in github actions workflows
    gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        /repos/$GITHUB_USERNAME/$REPO_NAME/actions/permissions/workflow \
        -f "default_workflow_permissions=write" &> /dev/null
}

# Function to create a sample repository using the create-or-update-repo.yaml workflow.
function create-sample-repository {
    git add .github/ \
    && git commit -m "fix: debugging the create-or-update-repo.yaml workflow" \
    && git push origin main || true

    gh workflow run .github/workflows/create-or-update-repo.yaml \
        -f repo_name="generated-demo-repo" \
        -f package_import_name="sample_py_package" \
        -f is_public_repo=true \
        --ref main
}


# cookie-cuts the project into sample directory, and initializes a git repository
# in the generated project, and make an initial commit, so that pre-commit hooks
# can be tested and run.
function generate-project {
    cookiecutter ./ \
        --output-dir "$THIS_DIR/sample"

    cd "$THIS_DIR/sample"
    cd $(ls)
    git init
    git branch -m main
    git add --all
    git commit -m "feat: generated sample project with python-cookiecutter-template"
}

# install core and development Python dependencies into the currently activated venv
function install {
    python -m pip install --upgrade pip
    python -m pip install cookiecutter pre-commit pytest pytest-xdist
}

# run linting, formatting, and other static code quality tools
function lint {
    pre-commit run --all-files
}

# same as `lint` but with any special considerations for CI
function lint:ci {
    # We skip no-commit-to-branch since that blocks commits to `main`.
    # All merged PRs are commits to `main` so this must be disabled.
    SKIP=no-commit-to-branch pre-commit run --all-files
}

# (example) ./run.sh test tests/test_makefile.py::test_linting_passes
function run-tests {
    python -m pytest ${@:-"$THIS_DIR/tests/"}
}

# uses pytest-xdist to run tests in parallel, `pytest -n auto`
function run-tests:parallel {
    PYTEST_EXIT_STATUS=0
    python -m pytest -n auto ${@:-"$THIS_DIR/tests/"}
}

# remove all files generated by tests, builds, or operating this codebase
function clean {
    rm -rf dist build coverage.xml test-reports sample/ tests/cookiecutter_test_configs/
    find . \
      -type d \
      \( \
        -name "*cache*" \
        -o -name "*.dist-info" \
        -o -name "*.egg-info" \
        -o -name "*htmlcov" \
      \) \
      -not -path "*env/*" \
      -exec rm -r {} + || true

    find . \
      -type f \
      -name "*.pyc" \
      -not -path "*env/*" \
      -exec rm {} +
}

# export the contents of .env as environment variables
function try-load-dotenv {
    if [ ! -f "$THIS_DIR/.env" ]; then
        echo "No .env file found"
        return 1
    fi

    while read -r line; do
        export "$line"
    done < <(grep -v '^#' "$THIS_DIR/.env" | grep -v '^$')
}

# print all functions in this file
function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-help}
