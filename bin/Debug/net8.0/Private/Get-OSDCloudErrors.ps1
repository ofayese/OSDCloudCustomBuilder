function Get-OSDCloudErrors {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[OSDCloudCustomBuilderError]])]
    param (
        [Parameter()]
        [switch]$Clear
    )
    
    $result = $script:ErrorCollection
    
    if ($Clear) {
        $script:ErrorCollection = [System.Collections.Generic.List[OSDCloudCustomBuilderError]]::new()
    }
    
    return $result
}