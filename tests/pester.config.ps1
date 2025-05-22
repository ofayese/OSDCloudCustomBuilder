# Pester configuration for OSDCloudCustomBuilder tests
@{
    Run = @{
        Path = "./tests"
        Exit = $true
        PassThru = $true
    }
    Debug = @{
        ShowNavigationMarkers = $true
    }
    Filter = @{
        Tag = ''
        ExcludeTag = @('Integration')
    }
    CodeCoverage = @{
        Enabled = $true
        OutputPath = "coverage.xml"
        OutputFormat = "JaCoCo"
        Path = @(
            "./src/OSDCloudCustomBuilder/Public/*.ps1"
            "./src/OSDCloudCustomBuilder/Private/*.ps1"
        )
        ExcludeTests = $true
    }
    TestResult = @{
        Enabled = $true
        OutputPath = "test-results.xml"
        OutputFormat = "NUnitXml"
    }
    Output = @{
        Verbosity = "Detailed"
    }
}
