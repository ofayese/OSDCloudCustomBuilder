function Test-ValidPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        
        [Parameter()]
        [switch]$MustExist,
        
        [Parameter()]
        [switch]$CreateIfNotExist,
        
        [Parameter()]
        [switch]$IsFile,
        
        [Parameter()]
        [switch]$IsDirectory
    )
    
    # Check for invalid characters in the path
    $invalidChars = [System.IO.Path]::GetInvalidPathChars()
    $invalidCharsFound = $false
    
    foreach ($char in $invalidChars) {
        if ($Path.Contains($char)) {
            $invalidCharsFound = $true
            break
        }
    }
    
    # Also check for other problematic characters/patterns
    if ($Path -match '[<>"|?*]') {
        $invalidCharsFound = $true
    }
    
    # Return false if invalid characters were found
    if ($invalidCharsFound) {
        return $false
    }
    
    # If MustExist is specified, check existence
    if ($MustExist) {
        $exists = Test-Path -Path $Path
        
        # If it doesn't exist but CreateIfNotExist is specified, try to create it
        if (-not $exists -and $CreateIfNotExist) {
            # Determine if we're creating a file or directory
            try {
                if ($IsFile) {
                    # Ensure parent directory exists
                    $parent = Split-Path -Path $Path -Parent
                    if (-not (Test-Path -Path $parent)) {
                        New-Item -Path $parent -ItemType Directory -Force | Out-Null
                    }
                    
                    # Create empty file
                    New-Item -Path $Path -ItemType File -Force | Out-Null
                }
                else {
                    # Default to creating a directory
                    New-Item -Path $Path -ItemType Directory -Force | Out-Null
                }
                
                $exists = Test-Path -Path $Path
            }
            catch {
                return $false
            }
        }
        
        # If the path still doesn't exist, return false
        if (-not $exists) {
            return $false
        }
        
        # If path exists, check if it's the correct type (file or directory)
        if ($IsFile -or $IsDirectory) {
            $item = Get-Item -Path $Path
            
            if ($IsFile -and -not $item.PSIsContainer) {
                return $true
            }
            
            if ($IsDirectory -and $item.PSIsContainer) {
                return $true
            }
            
            # Not the requested type
            return $false
        }
    }
    
    # If we got this far, the path is syntactically valid and exists if required
    return $true
}