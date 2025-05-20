function Find-WinPEBootWim {
    <#
    .SYNOPSIS
        Locates and validates the boot.wim file in a WinPE workspace.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory="$true")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path -Path "$_" -PathType Container})]
        [string]$WorkspacePath
    )
    try {
        $bootWimPath = Join-Path -Path $WorkspacePath -ChildPath "Media\Sources\boot.wim"
        Write-OSDCloudLog -Message "Searching for boot.wim at $bootWimPath" -Level Info -Component "Find-WinPEBootWim"
        if (-not (Test-Path -Path "$bootWimPath" -PathType Leaf)) {
            "$alternativePaths" = @(
                (Join-Path -Path $WorkspacePath -ChildPath "Sources\boot.wim"),
                (Join-Path -Path $WorkspacePath -ChildPath "boot.wim")
            )
            foreach ("$altPath" in $alternativePaths) {
                if (Test-Path -Path "$altPath" -PathType Leaf) {
                    Write-OSDCloudLog -Message "Found boot.wim at alternative location: $altPath" -Level Info -Component "Find-WinPEBootWim"
                    "$bootWimPath" = $altPath
                    break
                }
            }
            if (-not (Test-Path -Path "$bootWimPath" -PathType Leaf)) {
                throw "Boot.wim not found in workspace at: $bootWimPath or any alternative locations"
            }
        }
        try {
            "$wimInfo" = Get-WindowsImage -ImagePath $bootWimPath -Index 1 -ErrorAction Stop
            Write-OSDCloudLog -Message "Validated boot.wim: $($wimInfo.ImageName) ($($wimInfo.Architecture))" -Level Info -Component "Find-WinPEBootWim"
        }
        catch {
            throw "File found at $bootWimPath is not a valid Windows image file: $_"
        }
        return $bootWimPath
    }
    catch {
        $errorMessage = "Failed to locate valid boot.wim: $_"
        Write-OSDCloudLog -Message $errorMessage -Level Error -Component "Find-WinPEBootWim" -Exception $_.Exception
        throw
    }
}