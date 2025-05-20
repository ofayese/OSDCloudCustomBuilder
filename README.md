# OSDCloudCustomBuilder

Custom PowerShell module for building and customizing OSDCloud WinPE media.

## 🔧 Features

- Build module with `ModuleBuilder`
- Run tests with `Pester`
- Publish to PowerShell Gallery
- Fully containerized Dev Environment (VS Code + Docker)
- Structured `src/`, `tests/`, `tools/`

---

## 🛠 Development Environment

This project supports **Visual Studio Code Remote - Containers**.

### 🚀 Getting Started

1. **Install Requirements**:
    - [Docker](https://www.docker.com/)
    - [VS Code](https://code.visualstudio.com/)
    - VS Code Extensions:
        - Remote - Containers
        - PowerShell

2. **Clone & Open** in VS Code:
    ```bash
    git clone https://github.com/your-org/OSDCloudCustomBuilder.git
    cd OSDCloudCustomBuilder
    code .
    ```

3. **Reopen in Container**:
    - VS Code should prompt automatically.
    - Or use: `Cmd+Shift+P → Dev Containers: Reopen in Container`

---

## 📦 Common Dev Tasks

### 🧪 Run Tests

```powershell
tools\Run-Tests.ps1
```

Or via VS Code Task:  
`Ctrl+Shift+P → Run Task → Run Tests`

---

### 🏗 Build Module

```powershell
tools\build.ps1
```

Output goes to `out/` directory.

---

### 🚀 Publish to Gallery

```powershell
$env:PSGALLERY_API_KEY = 'your-key-here'
tools\Publish-Module.ps1
```

---

## 🧬 Folder Structure

```
src/                  # PowerShell module code
tests/                # Pester test cases
tools/                # Build/test/publish scripts
out/                  # Output build artifacts
.devcontainer/        # VS Code dev container config
.vscode/              # Tasks and debugging config
```

---

## 📄 License

MIT
