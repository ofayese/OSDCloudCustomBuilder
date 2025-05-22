# Code signing script for OSDCloudCustomBuilder
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CertificatePath,

    [Parameter(Mandatory=$true)]
    [SecureString]$CertPassword
)

$ErrorActionPreference = 'Stop'

# Load certificate
try {
    $cert = Get-PfxCertificate -FilePath $CertificatePath -Password $CertPassword
    Write-Verbose "Loaded certificate: $($cert.Subject)"
}
catch {
    throw "Failed to load certificate: $_"
}

# Sign all PowerShell files
$filesToSign = Get-ChildItem -Path "src" -Recurse -Include "*.ps1","*.psm1","*.psd1"
foreach ($file in $filesToSign) {
    try {
        $sig = Set-AuthenticodeSignature -FilePath $file.FullName -Certificate $cert
        if ($sig.Status -eq "Valid") {
            Write-Verbose "Successfully signed $($file.Name)"
        }
        else {
            Write-Warning "Failed to sign $($file.Name): $($sig.StatusMessage)"
        }
    }
    catch {
        Write-Error "Error signing $($file.Name): $_"
    }
}

# Verify signatures
$verificationErrors = @()
foreach ($file in $filesToSign) {
    $sig = Get-AuthenticodeSignature -FilePath $file.FullName
    if ($sig.Status -ne "Valid") {
        $verificationErrors += "$($file.Name): $($sig.StatusMessage)"
    }
}

if ($verificationErrors) {
    throw "Signature verification failed:`n$($verificationErrors -join "`n")"
}

Write-Host "All files signed successfully" -ForegroundColor Green
