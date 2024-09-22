# Contributing to Roomie Tasks

Thank you for your interest in contributing to Roomie Tasks! We welcome contributions from everyone. By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Git Working Policy

We follow a specific Git workflow to maintain a clean and organized repository. Please adhere to these guidelines when contributing:

### Branching Strategy

1. The `main` branch is our primary branch and should always be stable.
2. Create feature branches from `main` for your work.
3. Use the following naming convention for branches:
   - Features: `feature/short-description`
   - Bugfixes: `bugfix/short-description`
   - Hotfixes: `hotfix/short-description`
   - Releases: `release/version-number`

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for your commit messages:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types include:

- feat: A new feature
- fix: A bug fix
- docs: Documentation only changes
- style: Changes that do not affect the meaning of the code
- refactor: A code change that neither fixes a bug nor adds a feature
- perf: A code change that improves performance
- test: Adding missing tests or correcting existing tests
- chore: Changes to the build process or auxiliary tools and libraries

Example:

```text
feat(auth): implement user registration

- Add registration form
- Implement email verification
- Store user data in Firestore

Closes #123
```

### Pull Request Process

1. Ensure your code adheres to the project's style guide and passes all tests.
2. Update the README.md with details of changes to the interface, if applicable.
3. Increase the version numbers in any examples files and the README.md to the new version that this Pull Request would represent.
4. You may merge the Pull Request once you have the sign-off of two other developers, or if you do not have permission to do that, you may request the second reviewer to merge it for you.

## How to Contribute

### Reporting Bugs

- Use a clear and descriptive title for the issue to identify the problem.
- Describe the exact steps which reproduce the problem in as many details as possible.
- Provide specific examples to demonstrate the steps.

### Suggesting Enhancements

- Use a clear and descriptive title for the issue to identify the suggestion.
- Provide a step-by-step description of the suggested enhancement in as many details as possible.
- Provide specific examples to demonstrate the steps.

### Code Contribution

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Style Guide

- Follow the [Effective Dart: Style Guide](https://dart.dev/guides/language/effective-dart/style).
- Use `dart format` to format your code before committing.
- Ensure your code passes `flutter analyze` without any warnings or errors.

## Additional Notes

### Issue and Pull Request Labels

This section lists the labels we use to help us track and manage issues and pull requests:

- `bug`: Issues that are bugs.
- `enhancement`: Issues that are feature requests.
- `documentation`: Issues or pull requests related to documentation.
- `good first issue`: Good for newcomers.

Thank you for contributing to Roomie Tasks!
