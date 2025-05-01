function Test-WimFileAccessible {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WimPath
    )
    
    # Check if file exists and is a valid path
    if (-not (Test-ValidPath -Path $WimPath -MustExist -IsFile)) {
        return $false
    }
    
    try {
        # Check if file can be opened for reading
        $fileStream = [System.IO.File]::Open($WimPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $fileStream.Close()
        $fileStream.Dispose()
        
        # Check if it has the WIM file header
        $bytes = New-Object byte[] 8
        $fileStream = [System.IO.File]::Open($WimPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        $fileStream.Read($bytes, 0, 8) | Out-Null
        $fileStream.Close()
        $fileStream.Dispose()
        
        # Check for WIM header - MSWIM\0\0
        $expectedHeader = [byte[]]@(77, 83, 87, 73, 77, 0, 0, 0)
        $isWimFile = $true
        
        for ($i = 0; $i -lt 8; $i++) {
            if ($bytes[$i] -ne $expectedHeader[$i]) {
                $isWimFile = $false
                break
            }
        }
        
        if (-not $isWimFile) {
            return $false
        }
        
        # Check DISM compatibility in a non-invasive way
        $dismInfo = Get-WindowsImage -ImagePath $WimPath -ErrorAction SilentlyContinue
        return ($null -ne $dismInfo)
    }
    catch {
        # Any exception means the file is not accessible or not a valid WIM
        return $false
    }
}