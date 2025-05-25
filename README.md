
# OSDCloudCustomBuilder

A PowerShell module for customizing OSDCloud deployments.

## Development Setup

This project uses DevContainers to provide a consistent development environment. To get started:

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension
3. Clone this repository
4. Open the repository in VS Code
5. When prompted, click "Reopen in Container"

## Development Workflow

- **Build the module**: `./build.ps1 Build`
- **Run tests**: `./build.ps1 Test`
- **Analyze code**: `./build.ps1 Analyze`
- **Generate documentation**: `./build.ps1 Docs`

## Project Structure

- `Public/` - Public functions (exported)
- `Private/` - Private functions (internal)
- `Shared/` - Shared utilities
- `tests/` - Pester tests
- `docs/` - Documentation (generated)

## Testing

Tests are written using Pester 5. To run tests:

```powershell
./build.ps1 Test
```

## Code Style

This project follows the OTBS (One True Brace Style) PowerShell coding style. Code formatting is enforced using PSScriptAnalyzer.
