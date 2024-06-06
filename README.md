## @TODO:

- [ ] Seperate publish to Test PyPI and Prod PyPI in CI/CD
- [ ] Complete the README.md
- [x] Implement Upsert PyPI Secret in Github Actions
- [x] Populate from Template feature in Github Actions
- [x] Don't hardcode github username, user-name, and email in the workflow


## Tools used in the Project

<img src='assets/all-tools-images-1x.png' title='All Tools Used in the Project'>


## Github Actions Workflow to Create a New Repo and Populate it with Boilerplate Code

```mermaid
graph TD;
    A[Create Repo if Not Exists] ---> B[Configure Repo, i.e. PyPI Secrects, Branch Protection, etc.]
    A ---> C[Open a PR with Boilerplate Code]
```
