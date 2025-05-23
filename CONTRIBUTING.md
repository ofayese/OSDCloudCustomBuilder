# Contributing to OSDCloudCustomBuilder

Thank you for your interest in contributing to OSDCloudCustomBuilder! This document provides guidelines and instructions for contributing.

## Development Environment

This project uses VS Code with the Dev Containers extension for a consistent development environment. The container includes all necessary PowerShell modules and tools.

### Getting Started

1. Install the prerequisites:
   - Docker
   - VS Code
   - Remote - Containers extension

2. Clone the repository and open in VS Code:
   ```
   git clone https://github.com/your-org/OSDCloudCustomBuilder.git
   cd OSDCloudCustomBuilder
   code .
   ```

3. When prompted, click "Reopen in Container" or use the Command Palette (F1) and select "Remote-Containers: Reopen in Container"

## Coding Standards

- Follow the [PowerShell Best Practices and Style Guide](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- Use proper [comment-based help](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help) for all public functions
- Write descriptive commit messages following [Conventional Commits](https://www.conventionalcommits.org/)

## Testing

- Write Pester tests for all functions in the `tests` folder
- Run tests before submitting a PR:
  ```powershell
  ./tools/Run-Tests.ps1
  ```

## Pull Request Process

1. Create a feature branch from `main`
2. Implement your changes
3. Add/update tests
4. Update documentation
5. Run the test suite
6. Submit a pull request to `main`

## Module Structure

```
src/
├── OSDCloudCustomBuilder/
│   ├── Private/          # Internal module functions
│   ├── Public/           # Exported module functions
│   ├── Shared/           # Functions shared between Public and Private
│   ├── en-US/            # Localized help content
│   ├── OSDCloudCustomBuilder.psd1  # Module manifest
│   └── OSDCloudCustomBuilder.psm1  # Module script
```

Thank you for contributing!
