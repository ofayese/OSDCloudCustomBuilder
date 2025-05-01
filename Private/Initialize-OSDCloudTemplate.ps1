function Initialize-OSDCloudTemplate {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = "$true")]
        [ValidateNotNullOrEmpty()]
        [string]$WorkspacePath
    )
    begin {
        Write-OSDLog -Message "Initializing OSDCloud template at $WorkspacePath" -Level "Info" -Component "Initialize-OSDCloudTemplate"
        # Check if OSD module is available
        if (-not (Get-Module -Name OSD -ListAvailable)) {
            $errorMessage = "OSD module is required but not installed. Please install it using 'Install-Module OSD -Force'"
            Write-OSDLog -Message $errorMessage -Level "Error" -Component "Initialize-OSDCloudTemplate"
            throw $errorMessage
        }
    }
    process {
        try {
            # Ensure workspace directory exists (using -Force to avoid error if it already exists)
            if ($PSCmdlet.ShouldProcess($WorkspacePath, "Create directory")) {
                if (-not (Test-Path -Path "$WorkspacePath")) {
                    New-Item -Path "$WorkspacePath" -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
            }
            if ($PSCmdlet.ShouldProcess($WorkspacePath, "Create OSDCloud workspace with custom template")) {
                Write-Verbose "Creating OSDCloud workspace..." -ForegroundColor Cyan
                "$config" = Get-OSDCloudConfig -ErrorAction SilentlyContinue
                # Try custom template if available; otherwise, use default
                if ("$config" -and $config.CustomOSDCloudTemplate) {
                    Write-OSDLog -Message "Attempting to create workspace using custom template" -Level "Info" -Component "Initialize-OSDCloudTemplate"
                    try {
                        New-OSDCloudWorkspace -WorkspacePath "$WorkspacePath" -TemplateJSON $config.CustomOSDCloudTemplate -ErrorAction Stop
                        Write-OSDLog -Message "Workspace created using custom template" -Level "Info" -Component "Initialize-OSDCloudTemplate"
                    }
                    catch {
                        Write-OSDLog -Message "Failed to create workspace using custom template, trying default..." -Level "Warning" -Component "Initialize-OSDCloudTemplate" -Exception $_.Exception
                        # Fallback to default template
                        New-OSDCloudWorkspace -WorkspacePath "$WorkspacePath" -ErrorAction Stop
                        Write-OSDLog -Message "Workspace created using default template" -Level "Info" -Component "Initialize-OSDCloudTemplate"
                    }
                }
                else {
                    Write-OSDLog -Message "No custom template specified, using default" -Level "Info" -Component "Initialize-OSDCloudTemplate"
                    New-OSDCloudWorkspace -WorkspacePath "$WorkspacePath" -ErrorAction Stop
                    Write-OSDLog -Message "Workspace created using default template" -Level "Info" -Component "Initialize-OSDCloudTemplate"
                }
            }
            $successMessage = "OSDCloud workspace created successfully"
            Write-OSDLog -Message $successMessage -Level "Info" -Component "Initialize-OSDCloudTemplate"
            return $WorkspacePath
        }
        catch {
            $errorMessage = "Failed to initialize OSDCloud template: $_"
            Write-OSDLog -Message $errorMessage -Level "Error" -Component "Initialize-OSDCloudTemplate" -Exception $_.Exception
            throw
        }
    }
}