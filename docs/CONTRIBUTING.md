# Contributing to OSDCloudCustomBuilder

Thank you for your interest in contributing to OSDCloudCustomBuilder! We welcome all contributions, whether they're bug fixes, new features, documentation improvements, or examples.

## 🛠️ Development Environment Setup

### Prerequisites

- Git
- Visual Studio Code
- Docker (for DevContainer support)
- PowerShell 7+ (recommended)

### Getting Started

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/your-username/OSDCloudCustomBuilder.git
   cd OSDCloudCustomBuilder
   ```

2. **Open in VS Code with DevContainer:**
   - Open the project in Visual Studio Code
   - Install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
   - When prompted, click "Reopen in Container"
   - The DevContainer will automatically set up the development environment

3. **Verify the setup:**
   ```powershell
   ./build.ps1 Test
   ```

## 🧪 Development Workflow

### Before Making Changes

1. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Run the existing tests to ensure everything works:
   ```powershell
   ./build.ps1 Test
   ```

### Code Quality and Standards

- **PowerShell Style**: Follow the OTBS (One True Brace Style)
- **Auto-formatting**: Enabled on save in VS Code
- **Linting**: Use PSScriptAnalyzer

Run code analysis:

```powershell
./build.ps1 Analyze
```

### Testing Requirements

- All new functions must have corresponding Pester tests
- Tests should be placed in the `tests/` directory
- Test files should follow the naming pattern: `FunctionName.Tests.ps1`
- Aim for high test coverage

Run tests:

```powershell
./build.ps1 Test
```

### Documentation Standards

- All public functions must have complete help documentation
- Use proper PowerShell comment-based help format
- Add function documentation in `docs/functions/`
- Update README.md if adding new features

Generate documentation:

```powershell
./build.ps1 Docs
```

## 📋 Contribution Checklist

Before submitting a pull request, ensure:

- [ ] Code follows PowerShell best practices and OTBS style
- [ ] All tests pass (`./build.ps1 Test`)
- [ ] Code analysis passes (`./build.ps1 Analyze`)
- [ ] New functions have help comments with:
  - [ ] `.SYNOPSIS`
  - [ ] `.DESCRIPTION`
  - [ ] `.PARAMETER` (for each parameter)
  - [ ] `.EXAMPLE` (at least one)
  - [ ] `.NOTES` (with author and date)
- [ ] New functions have corresponding Pester tests
- [ ] Function documentation added in `docs/functions/`
- [ ] CHANGELOG.md updated (if applicable)
- [ ] README.md updated (if adding new features)

## 🐛 Bug Reports

When reporting bugs, please include:

- PowerShell version (`$PSVersionTable`)
- Operating system version
- Steps to reproduce the issue
- Expected vs. actual behavior
- Error messages (if any)

## 💡 Feature Requests

For feature requests, please:

- Check existing issues to avoid duplicates
- Provide a clear description of the proposed feature
- Explain the use case and benefits
- Include examples of how the feature would be used

## 📝 Pull Request Process

1. **Create a descriptive title** that summarizes the change
2. **Fill out the pull request template** completely
3. **Link related issues** using keywords (e.g., "Fixes #123")
4. **Request reviews** from maintainers
5. **Address feedback** promptly and professionally

### Pull Request Template

Please use the following template for pull requests:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Documentation
- [ ] Help documentation updated
- [ ] README updated (if applicable)
- [ ] CHANGELOG updated

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] No breaking changes
```

## 🔒 Security

If you discover a security vulnerability, please:

- **Do not** create a public GitHub issue
- Email the maintainers directly
- Include detailed information about the vulnerability
- Allow time for the issue to be addressed before public disclosure

See [SECURITY.md](../SECURITY.md) for more information.

## 📚 Additional Resources

- [PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- [Pester Documentation](https://pester.dev/)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)
- [Keep a Changelog](https://keepachangelog.com/)

## 🤝 Code of Conduct

Please be respectful and constructive in all interactions. We're committed to providing a welcoming and inclusive environment for all contributors.

## 📞 Getting Help

If you need help or have questions:

- Check existing documentation
- Search existing issues
- Create a new issue with the "question" label
- Join community discussions

Thank you for contributing to OSDCloudCustomBuilder!
