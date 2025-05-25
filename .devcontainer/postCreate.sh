#!/bin/bash

# Post-create script for OSDCloudCustomBuilder DevContainer
# This script runs after the container is created and VS Code is connected

set -e

echo "🔧 Setting up OSDCloudCustomBuilder development environment..."

# Set proper permissions for the workspace
sudo chown -R vscode:vscode /workspaces/OSDCloudCustomBuilder

# Navigate to workspace
cd /workspaces/OSDCloudCustomBuilder

# Restore .NET dependencies
if [ -f "OSDCloudCustomBuilder.csproj" ]; then
    echo "📦 Restoring .NET packages..."
    dotnet restore
fi

if [ -f "OSDCloudCustomBuilder.sln" ]; then
    echo "📦 Restoring solution packages..."
    dotnet restore OSDCloudCustomBuilder.sln
fi

# Install additional PowerShell modules if requirements.psd1 exists
if [ -f "requirements.psd1" ]; then
    echo "📋 Installing PowerShell modules from requirements.psd1..."
    pwsh -NoProfile -Command "
        try {
            Import-PowerShellDataFile -Path './requirements.psd1' | ForEach-Object {
                if (\$_.RequiredModules) {
                    \$_.RequiredModules | ForEach-Object {
                        Write-Host \"Installing module: \$_\"
                        Install-Module -Name \$_ -Force -Scope AllUsers -AllowClobber
                    }
                }
            }
        } catch {
            Write-Warning \"Error processing requirements.psd1: \$_\"
        }
    "
fi

# Set up PowerShell profile for enhanced development experience
echo "⚙️ Setting up PowerShell profile..."
pwsh -NoProfile -Command "
    \$profilePath = \$PROFILE.AllUsersAllHosts
    \$profileDir = Split-Path \$profilePath -Parent
    if (!(Test-Path \$profileDir)) {
        New-Item -ItemType Directory -Path \$profileDir -Force
    }

    \$profileContent = @'
# OSDCloudCustomBuilder Development Profile
Write-Host \"🚀 OSDCloudCustomBuilder DevContainer\" -ForegroundColor Green
Write-Host \"📁 Workspace: \$(Get-Location)\" -ForegroundColor Cyan

# Set up aliases for common tasks
Set-Alias -Name build -Value './build.ps1'
Set-Alias -Name test -Value 'Invoke-Pester'
Set-Alias -Name analyze -Value 'Invoke-ScriptAnalyzer'

# Function to show project status
function Show-ProjectStatus {
    Write-Host \"\\n📊 Project Status:\" -ForegroundColor Yellow
    if (Test-Path './OSDCloudCustomBuilder.csproj') {
        Write-Host \"  .NET Project: ✅\" -ForegroundColor Green
        dotnet --version | ForEach-Object { Write-Host \"  .NET Version: \$_\" -ForegroundColor Cyan }
    }
    if (Test-Path './OSDCloudCustomBuilder.psd1') {
        Write-Host \"  PowerShell Module: ✅\" -ForegroundColor Green
        \$manifest = Import-PowerShellDataFile './OSDCloudCustomBuilder.psd1'
        Write-Host \"  Module Version: \$(\$manifest.ModuleVersion)\" -ForegroundColor Cyan
    }
    if (Test-Path './tests') {
        \$testCount = (Get-ChildItem ./tests -Filter '*.Tests.ps1').Count
        Write-Host \"  Test Files: \$testCount\" -ForegroundColor Cyan
    }
}

# Function to run all tests with coverage
function Invoke-FullTest {
    Write-Host \"🧪 Running comprehensive tests...\" -ForegroundColor Yellow

    # PowerShell tests
    if (Test-Path './tests') {
        Write-Host \"\\n📋 Running Pester tests...\"
        Invoke-Pester -Path ./tests -CodeCoverage ./Public/*.ps1,./Private/*.ps1 -OutputFormat NUnitXml -OutputFile TestResults.xml
    }

    # .NET tests
    if (Test-Path './OSDCloudCustomBuilder.csproj') {
        Write-Host \"\\n🔍 Running .NET tests...\"
        dotnet test --logger trx --collect:\"XPlat Code Coverage\"
    }

    # Script analysis
    Write-Host \"\\n🔍 Running PSScriptAnalyzer...\"
    Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzer.settings.psd1
}

# Function to build the entire project
function Invoke-FullBuild {
    Write-Host \"🔨 Building OSDCloudCustomBuilder...\" -ForegroundColor Yellow

    # .NET build
    if (Test-Path './OSDCloudCustomBuilder.csproj') {
        Write-Host \"\\n📦 Building .NET project...\"
        dotnet build --configuration Release
    }

    # PowerShell module build
    if (Test-Path './build.ps1') {
        Write-Host \"\\n📋 Running PowerShell build...\"
        ./build.ps1
    }
}

Write-Host \"\\n💡 Available commands:\"
Write-Host \"  Show-ProjectStatus  - Display project information\"
Write-Host \"  Invoke-FullTest     - Run all tests with coverage\"
Write-Host \"  Invoke-FullBuild    - Build the entire project\"
Write-Host \"  build               - Alias for ./build.ps1\"
Write-Host \"  test                - Alias for Invoke-Pester\"
Write-Host \"  analyze             - Alias for Invoke-ScriptAnalyzer\"
Write-Host \"\"
'@

    Set-Content -Path \$profilePath -Value \$profileContent -Force
    Write-Host \"PowerShell profile created at: \$profilePath\"
"

# Create VS Code tasks and launch configurations
echo "⚙️ Setting up VS Code configuration..."
mkdir -p .vscode

# Create tasks.json for enhanced build tasks
cat > .vscode/tasks.json << 'EOF'
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build: Full Project",
            "type": "shell",
            "command": "pwsh",
            "args": ["-NoProfile", "-Command", "Invoke-FullBuild"],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": ["$msCompile", "$pester"]
        },
        {
            "label": "Test: Full Test Suite",
            "type": "shell",
            "command": "pwsh",
            "args": ["-NoProfile", "-Command", "Invoke-FullTest"],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": ["$pester"]
        },
        {
            "label": "Test: Pester Only",
            "type": "shell",
            "command": "pwsh",
            "args": ["-NoProfile", "-Command", "Invoke-Pester", "-Path", "./tests", "-Output", "Detailed"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": ["$pester"]
        },
        {
            "label": "Analyze: PSScriptAnalyzer",
            "type": "shell",
            "command": "pwsh",
            "args": ["-NoProfile", "-Command", "Invoke-ScriptAnalyzer", "-Path", ".", "-Recurse", "-Settings", "PSScriptAnalyzer.settings.psd1"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Build: .NET Only",
            "type": "shell",
            "command": "dotnet",
            "args": ["build", "--configuration", "Release"],
            "group": "build",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            },
            "problemMatcher": "$msCompile"
        },
        {
            "label": "Test: .NET Only",
            "type": "shell",
            "command": "dotnet",
            "args": ["test", "--logger", "trx", "--collect:XPlat Code Coverage"],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "shared"
            }
        },
        {
            "label": "Clean: All Artifacts",
            "type": "shell",
            "command": "pwsh",
            "args": ["-NoProfile", "-Command", "Remove-Item -Path ./bin, ./obj, ./TestResults*, ./coverage* -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'Cleaned all build artifacts'"],
            "group": "build"
        }
    ]
}
EOF

# Create launch.json for debugging
cat > .vscode/launch.json << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "PowerShell: Launch Current File",
            "type": "PowerShell",
            "request": "launch",
            "program": "${file}",
            "args": [],
            "cwd": "${workspaceFolder}",
            "console": "integratedTerminal"
        },
        {
            "name": "PowerShell: Launch Pester Tests",
            "type": "PowerShell",
            "request": "launch",
            "program": "Invoke-Pester",
            "args": ["-Path", "./tests", "-Output", "Detailed"],
            "cwd": "${workspaceFolder}",
            "console": "integratedTerminal"
        },
        {
            "name": ".NET: Attach to Process",
            "type": "coreclr",
            "request": "attach",
            "processId": "${command:pickProcess}"
        }
    ]
}
EOF

# Create settings.json with enhanced development settings
cat > .vscode/settings.json << 'EOF'
{
    "powershell.codeFormatting.preset": "OTBS",
    "powershell.scriptAnalysis.enable": true,
    "powershell.pester.useLegacyCodeLens": false,
    "powershell.pester.outputVerbosity": "Detailed",
    "files.associations": {
        "*.psd1": "powershell",
        "*.psm1": "powershell",
        "*.ps1": "powershell"
    },
    "files.eol": "\n",
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll": "explicit"
    },
    "dotnet.completion.showCompletionItemsFromUnimportedNamespaces": true,
    "dotnet.server.useOmnisharp": false,
    "omnisharp.enableEditorConfigSupport": true,
    "omnisharp.enableRoslynAnalyzers": true,
    "terminal.integrated.defaultProfile.linux": "pwsh"
}
EOF

# Initialize git hooks if git is present
if [ -d ".git" ]; then
    echo "🔧 Setting up git hooks..."
    mkdir -p .git/hooks

    # Pre-commit hook for code quality
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🔍 Running pre-commit checks..."

# Run PSScriptAnalyzer
echo "Running PSScriptAnalyzer..."
pwsh -NoProfile -Command "
    \$issues = Invoke-ScriptAnalyzer -Path . -Recurse -Settings PSScriptAnalyzer.settings.psd1
    if (\$issues) {
        Write-Host 'PSScriptAnalyzer found issues:' -ForegroundColor Red
        \$issues | Format-Table
        exit 1
    } else {
        Write-Host 'PSScriptAnalyzer: No issues found' -ForegroundColor Green
    }
"

# Run basic tests
echo "Running basic tests..."
pwsh -NoProfile -Command "
    if (Test-Path './tests') {
        \$result = Invoke-Pester -Path ./tests -PassThru
        if (\$result.FailedCount -gt 0) {
            Write-Host 'Some tests failed!' -ForegroundColor Red
            exit 1
        } else {
            Write-Host 'All tests passed!' -ForegroundColor Green
        }
    }
"

echo "✅ Pre-commit checks passed!"
EOF
    chmod +x .git/hooks/pre-commit
fi

# Create test coverage configuration
echo "📊 Setting up test coverage configuration..."
cat > coverlet.runsettings << 'EOF'
<?xml version="1.0" encoding="utf-8" ?>
<RunSettings>
  <DataCollectionRunSettings>
    <DataCollectors>
      <DataCollector friendlyName="XPlat code coverage">
        <Configuration>
          <Format>opencover,cobertura,lcov,teamcity,json</Format>
          <Exclude>[*.Tests?]*,[*]*.Test*,[xunit.*]*</Exclude>
          <ExcludeByAttribute>Obsolete,GeneratedCodeAttribute,CompilerGeneratedAttribute</ExcludeByAttribute>
          <IncludeDirectory>Public,Private,Shared</IncludeDirectory>
        </Configuration>
      </DataCollector>
    </DataCollectors>
  </DataCollectionRunSettings>
</RunSettings>
EOF

# Set up directory structure for test results
mkdir -p TestResults
mkdir -p coverage

echo "✅ OSDCloudCustomBuilder development environment setup complete!"
echo ""
echo "🔧 Next steps:"
echo "  1. Reload VS Code window to apply all settings"
echo "  2. Open a PowerShell terminal (Ctrl+Shift+\`)"
echo "  3. Run 'Show-ProjectStatus' to verify setup"
echo "  4. Use 'Invoke-FullBuild' to build the project"
echo "  5. Use 'Invoke-FullTest' to run all tests"
echo ""
echo "📋 Available VS Code tasks:"
echo "  - Build: Full Project (Ctrl+Shift+P > Tasks: Run Task)"
echo "  - Test: Full Test Suite"
echo "  - Analyze: PSScriptAnalyzer"
echo ""
echo "Happy coding! 🚀"
