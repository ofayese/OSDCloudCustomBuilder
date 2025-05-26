# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Enhanced documentation with detailed Getting Started guide
- Improved Contributing guidelines with comprehensive checklist
- Badge system for build status, PowerShell Gallery, and license
- Function reference table in README
- Development workflow documentation

### Changed
- README.md restructured with better organization and examples
- CONTRIBUTING.md expanded with detailed development guidelines

### Fixed
- Documentation formatting issues
- Removed placeholder text in documentation

## [1.0.0] - 2025-05-24

### Added
- Full function help documentation for all public functions
- CI workflow with Pester testing and PSScriptAnalyzer
- DevContainer configuration with platform detection
- `Invoke-Build.ps1` build system and versioning
- Core OSDCloud customization functions:
  - `Add-OSDCloudCustomDriver` - Driver management
  - `Add-OSDCloudCustomScript` - Script injection
  - `New-CustomOSDCloudISO` - ISO creation
  - `New-OSDCloudCustomMedia` - Media customization
  - `Set-OSDCloudCustomSettings` - Configuration management
  - `Test-OSDCloudCustomRequirements` - System validation
  - `Update-CustomWimWithPwsh7` - PowerShell 7 integration
- Comprehensive Pester test suite
- PSScriptAnalyzer configuration and code quality checks
- Module manifest and build configuration

### Security
- Input validation for all public functions
- Secure handling of file operations

## [0.1.0] - Initial Development

### Added
- Initial project structure
- Basic function scaffolding
- Development environment setup
