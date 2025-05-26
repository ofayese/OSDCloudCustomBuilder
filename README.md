# OSDCloudCustomBuilder

![Build](https://github.com/your-org/OSDCloudCustomBuilder/actions/workflows/ci.yml/badge.svg)
![PowerShell Gallery](https://img.shields.io/powershellgallery/v/OSDCloudCustomBuilder)

A robust PowerShell module for automating and customizing OSDCloud media, drivers, telemetry, and deployment workflows.

## 🚀 Getting Started

```powershell
Install-Module -Name OSDCloudCustomBuilder -Scope CurrentUser -Force
Import-Module OSDCloudCustomBuilder
```

## 📦 Features

- Driver & Script Injection
- Media Customization
- Configuration & Telemetry Management
- Fully Pester-tested & CI/CD ready

## 📖 Function Reference

See [docs/functions](docs/functions) for detailed function documentation.

## 🧪 Testing

```powershell
Invoke-Pester -Path ./tests
```

## 🛠️ Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md)

## 📄 License

MIT - See [LICENSE](LICENSE)
