# Contributing to Azure Data Lake Management

Thanks for your interest in improving **Azure Data Lake Management**! 🎉

This project follows a **fork → branch → pull request (PR)** workflow. The guidelines below will help you propose changes that are easy to review and merge.

> **TL;DR**
> 1) Fork the repo · 2) Create a feature branch · 3) Commit with clear messages · 4) Open a PR referencing related issues.

---

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Before You Start](#before-you-start)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Checklist](#pull-request-checklist)
- [Issue Reporting](#issue-reporting)
- [Security](#security)
- [License](#license)
- [Questions](#questions)

---

## Code of Conduct
Please help us keep this project open and welcoming. By participating, you agree to uphold our [Code of Conduct](https://github.com/SteveCInVA/AzureDataLakeManagement/blob/main/CODE_OF_CONDUCT.md). 

## Ways to Contribute
- 🐛 **Report bugs** and reproduction steps
- 💡 **Request features** with clear use-cases
- 🛠️ **Improve code** (refactors, bugfixes, docs)
- 📚 **Enhance documentation** (README, examples, comments)
- ✅ **Add tests** or improve coverage

## Before You Start
- Read existing issues and pull requests to avoid duplicates.
- Check the project structure to see where your change should live (e.g., `AzureDataLakeManagement/`, `Tests/`).
- For substantial changes, consider opening an issue first to discuss the approach.

## Getting Started
1. **Fork** the repository: <https://github.com/SteveCInVA/AzureDataLakeManagement>
2. **Clone your fork**:
   ```bash
   git clone https://github.com/<your-username>/AzureDataLakeManagement.git
   cd AzureDataLakeManagement
   ```
3. **Add the upstream remote** (original repo):
   ```bash
   git remote add upstream https://github.com/SteveCInVA/AzureDataLakeManagement.git
   git fetch upstream
   ```
4. **Create a working branch** from `main` (or the target branch):
   ```bash
   git checkout -b feat/short-description
   # examples: feat/add-adls-role-binding, fix/az-cli-auth-bug, docs/improve-readme
   ```

To keep your fork up to date:
```bash
git checkout main
git fetch upstream
git merge upstream/main
git push origin main
```

## Development Workflow
- Make small, focused commits.
- Include comments where intent isn’t obvious.
- Prefer configuration and scripts that are **idempotent** and **reproducible**.
- If you add or change behavior, please add/update tests and documentation.

**Languages & tooling**
> This repository may include PowerShell/Bash scripts, Bicep/ARM templates, and/or Python. Use linters and formatters appropriate to your changes (e.g., PSScriptAnalyzer for PowerShell, `bash -n`/`shellcheck` for shell). If a `.editorconfig` or tool config exists in the repo, please adhere to it.

**Local validation examples**
```bash
# PowerShell (from pwsh)
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path ./AzureDataLakeManagement -Recurse
```

## Commit Message Guidelines
Use clear, descriptive messages. Conventional Commits are encouraged:
```
<type>(optional-scope): short summary

optional body explaining what/why, not how

BREAKING CHANGE: details (if applicable)
```
Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

Examples:
- `feat(adls): add container-level RBAC assignment helper`
- `fix(scripts): handle az login device code on WSL`
- `docs(readme): clarify prerequisites for azd`

## Pull Request Checklist
Before opening a PR, please ensure:
- [ ] The branch is up to date with `upstream/main`.
- [ ] Code builds/validates locally and passes linting/tests.
- [ ] New/changed behavior is documented.
- [ ] Any UI/behavior changes include screenshots or examples (if applicable).
- [ ] The PR description links related issues (e.g., `Fixes #123`).
- [ ] The PR is **scoped** (small, reviewable) and the title is clear.

**Open a PR** from your fork’s branch to the `main` branch of `SteveCInVA/AzureDataLakeManagement`.

## Issue Reporting
When filing an issue, include:
- **Environment** (OS, shell, versions: Azure CLI/PowerShell/Python, etc.)
- **Steps to reproduce** (exact commands or code)
- **Expected vs. actual behavior**
- **Logs/error output** (redact secrets)
- **Screenshots** if relevant

Feature requests should describe the **problem**, proposed **solution**, and alternative approaches considered.

## Security
Please **do not** open public issues for security vulnerabilities. If the repo contains `SECURITY.md`, follow those instructions. Otherwise, use GitHub’s [private security advisories](https://docs.github.com/code-security/security-advisories/repository-security-advisories/creating-a-repository-security-advisory) to report privately to the maintainers.

## License
By contributing, you agree your contributions will be licensed under the project’s license (see `LICENSE`). If this repository uses a Contributor License Agreement (CLA), the maintainers may request you to sign it for significant changes.

## Questions
If you need help or want feedback before starting, please open a **discussion** (if enabled) or an **issue** labeled `question`/`discussion` describing your idea. We’re glad you’re here—thanks for contributing! 🙌
