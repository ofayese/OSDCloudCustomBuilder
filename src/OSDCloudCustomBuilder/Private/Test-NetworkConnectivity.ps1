function Test-NetworkConnectivity {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter()]
        [int]$Timeout = 5000
    )
    
    try {
        # Extract hostname from URI
        $uriObj = [System.Uri]$Uri
        $hostname = $uriObj.Host
        
        # First, try a simple ping test
        $ping = New-Object System.Net.NetworkInformation.Ping
        $pingResult = $ping.Send($hostname, $Timeout)
        
        if ($pingResult.Status -eq 'Success') {
            return $true
        }
        
        # If ping fails, try an HTTP request as some servers block ICMP
        $request = [System.Net.HttpWebRequest]::Create($Uri)
        $request.Method = "HEAD"
        $request.Timeout = $Timeout
        $request.AllowAutoRedirect = $true
        
        try {
            $response = $request.GetResponse()
            $response.Close()
            return $true
        }
        catch {
            # HTTP request failed
            return $false
        }
    }
    catch {
        # Something went wrong with the validation process
        return $false
    }
}