# New-TestWimFile.ps1
# Creates a test WIM file for use in OSDCloudCustomBuilder tests

function New-TestWimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter()]
        [int]$SizeInMB = 10,

        [Parameter()]
        [switch]$CreateWindowsDirectory
    )

    # Create a directory to hold the content for the WIM
    $tempDir = Join-Path -Path $env:TEMP -ChildPath "TestWimContent_$(Get-Random)"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

    try {
        # Create a dummy file to give the WIM some size
        $dummyFilePath = Join-Path -Path $tempDir -ChildPath "dummy.bin"
        $buffer = New-Object byte[] ($SizeInMB * 1MB)
        [System.IO.File]::WriteAllBytes($dummyFilePath, $buffer)

        # Create Windows directory if requested (for mount verification)
        if ($CreateWindowsDirectory) {
            $windowsDir = Join-Path -Path $tempDir -ChildPath "Windows"
            New-Item -Path $windowsDir -ItemType Directory -Force | Out-Null

            # Create some typical Windows directories
            $systemDir = Join-Path -Path $windowsDir -ChildPath "System32"
            New-Item -Path $systemDir -ItemType Directory -Force | Out-Null

            # Create a dummy system file
            $systemFilePath = Join-Path -Path $systemDir -ChildPath "ntdll.dll"
            $buffer = New-Object byte[] (1MB)
            [System.IO.File]::WriteAllBytes($systemFilePath, $buffer)
        }

        # Ensure output directory exists
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Check if DISM is available for creating a real WIM
        $dismAvailable = $null -ne (Get-Command -Name 'New-WindowsImage' -ErrorAction SilentlyContinue) -or
                         $null -ne (Get-Command -Name 'dism.exe' -ErrorAction SilentlyContinue)

        if ($dismAvailable) {
            # Try to create a real WIM file using DISM
            try {
                if (Get-Command -Name 'New-WindowsImage' -ErrorAction SilentlyContinue) {
                    New-WindowsImage -CapturePath $tempDir -ImagePath $OutputPath -Name "TestWIM" -Description "Test WIM file for OSDCloudCustomBuilder tests" -ErrorAction Stop
                }
                else {
                    $dismArgs = @(
                        "/Capture-Image",
                        "/ImageFile:$OutputPath",
                        "/CaptureDir:$tempDir",
                        "/Name:TestWIM"
                    )
                    Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -NoNewWindow -Wait
                }

                # Verify the WIM was created
                if (Test-Path -Path $OutputPath) {
                    return $OutputPath
                }
            }
            catch {
                Write-Warning "Failed to create WIM using DISM: $_"
                # Fall back to creating a dummy WIM file
            }
        }

        # If DISM is not available or failed, create a dummy WIM file
        Write-Warning "Creating a dummy WIM file (not a real WIM)"
        $buffer = New-Object byte[] ($SizeInMB * 1MB)
        [System.IO.File]::WriteAllBytes($OutputPath, $buffer)

        # Add WIM file signature at the beginning
        $signature = [System.Text.Encoding]::ASCII.GetBytes("MSWIM")
        $fileStream = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::Open)
        $fileStream.Write($signature, 0, $signature.Length)
        $fileStream.Close()

        return $OutputPath
    }
    finally {
        # Clean up the temporary directory
        if (Test-Path -Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Test-IsValidWimFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Check if the file exists
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        return $false
    }

    # Check file size (must be at least 1MB)
    $fileInfo = Get-Item -Path $Path
    if ($fileInfo.Length -lt 1MB) {
        return $false
    }

    # Check for WIM signature
    try {
        $fileStream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        $reader = New-Object System.IO.BinaryReader($fileStream)
        $signature = New-Object char[] 5
        $reader.Read($signature, 0, 5) | Out-Null
        $signatureString = -join $signature
        $fileStream.Close()

        return $signatureString -eq "MSWIM"
    }
    catch {
        return $false
    }
}

# Export functions
Export-ModuleMember -Function New-TestWimFile, Test-IsValidWimFile
