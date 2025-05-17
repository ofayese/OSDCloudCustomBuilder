# Install Windows ADK and WinPE addon
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Write-Status {
    param (
        [string]$Message
    )
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" -ForegroundColor Cyan
}

try {
    Write-Status "Starting Windows ADK installation"

    # Create temp directory
    $tempDir = "C:\temp"
    if (-not (Test-Path -Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        Write-Status "Created temp directory: $tempDir"
    }

    # Download ADK installer
    $adkUrl = "https://go.microsoft.com/fwlink/?linkid=2196127"
    $adkInstaller = "$tempDir\adksetup.exe"
    Write-Status "Downloading ADK installer from $adkUrl"
    Invoke-WebRequest -Uri $adkUrl -OutFile $adkInstaller -UseBasicParsing
    Write-Status "Downloaded ADK installer to $adkInstaller"

    # Install ADK with required components
    Write-Status "Installing Windows ADK (this may take a while)..."
    $adkArgs = "/quiet /features OptionId.DeploymentTools OptionId.UserStateMigrationTool OptionId.ImagingAndConfigurationDesigner"
    Write-Status "Running: $adkInstaller $adkArgs"
    $adkProcess = Start-Process -FilePath $adkInstaller -ArgumentList $adkArgs -Wait -PassThru -NoNewWindow
    
    if ($adkProcess.ExitCode -ne 0) {
        throw "ADK installation failed with exit code: $($adkProcess.ExitCode)"
    }
    
    Write-Status "Windows ADK installed successfully"

    # Download WinPE addon
    $winpeUrl = "https://go.microsoft.com/fwlink/?linkid=2196224"
    $winpeInstaller = "$tempDir\adkwinpesetup.exe"
    Write-Status "Downloading WinPE addon from $winpeUrl"
    Invoke-WebRequest -Uri $winpeUrl -OutFile $winpeInstaller -UseBasicParsing
    Write-Status "Downloaded WinPE addon to $winpeInstaller"

    # Install WinPE addon
    Write-Status "Installing WinPE addon (this may take a while)..."
    $winpeArgs = "/quiet /features +"
    Write-Status "Running: $winpeInstaller $winpeArgs"
    $winpeProcess = Start-Process -FilePath $winpeInstaller -ArgumentList $winpeArgs -Wait -PassThru -NoNewWindow
    
    if ($winpeProcess.ExitCode -ne 0) {
        throw "WinPE addon installation failed with exit code: $($winpeProcess.ExitCode)"
    }
    
    Write-Status "WinPE addon installed successfully"

    # Cleanup
    if (Test-Path -Path $adkInstaller) {
        Remove-Item -Path $adkInstaller -Force
        Write-Status "Cleaned up ADK installer"
    }
    
    if (Test-Path -Path $winpeInstaller) {
        Remove-Item -Path $winpeInstaller -Force
        Write-Status "Cleaned up WinPE installer"
    }

    Write-Status "Windows ADK and WinPE addon installation completed successfully"
}
catch {
    Write-Host "Error installing Windows ADK and WinPE addon: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    throw
}
