#!/bin/bash

set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # IS_PUBLIC_REPO: boolean; if true, the repository will be public, else private
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
    REPO_DESCRIPTION="A repository created using the python-cookiecutter-template"
    gh repo create "$GITHUB_USERNAME/$REPO_NAME" "--$PUBLIC_OR_PRIVATE" --description "$REPO_DESCRIPTION"
    # || {
    #     echo "Repository with name $REPO_NAME already exists."
    #     echo "Please enter a new repository name: "
    #     read -r REPO_NAME
    #     create-repository-if-not-exists
    # }

    # Create a trivial file and create an initial commit to main branch
    # This is required to open a PR to the main branch
    push-initial-readme-to-repo
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
    git push origin main
    cd ..
    rm -rf "$REPO_NAME" # remove the cloned repository after pushing the initial commit
}


# function configure-repository {}

# INFO: Opening a PR is not a git concept, but a GitHub concept or a Git hosting service provider concept.
# args:
    # REPO_NAME: repository name
    # GITHUB_USERNAME: github username; e.g. "avr2002"
    # BASE_BRANCH: base branch to open the PR against; e.g. "main"
    # HEAD_BRANCH: head branch to open the PR from; e.g. "feature/new-feature"
function open-pull-request-with-generated-project {
    rm -rf "$REPO_NAME" ./outdir

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
    git checkout -b "feat/populating-from-cookiecutter-template"
    git add --all

    # 2.1 Apply formatting, linting autofixes to the generated files (pre-commit hooks to the staged files)
    make install
    make lint-ci || true

    # 2.2 Re-stage the modified files after applying the pre-commit hooks
    git add --all

    # 2.3 Commit the changes and push to the remote feature branch
    git commit -m "feat: populated the repository from the \`python-cookiecutter-template\`"
    git push origin "feat/populating-from-cookiecutter-template"
    
    # 3. Open a PR to main branch using GitHub CLI
    gh pr create \
        --title "feat: populated the repository from the \`python-cookiecutter-template\`" \
        --body "Populated the repository from the \`python-cookiecutter-template\`" \
        --base main \
        --head "feat/populating-from-cookiecutter-template" \
        --repo "$GITHUB_USERNAME/$REPO_NAME"
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
