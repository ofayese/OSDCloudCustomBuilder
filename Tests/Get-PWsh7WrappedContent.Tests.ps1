# Pester Test: Get-PWsh7WrappedContent
Describe "Get-PWsh7WrappedContent" {
    BeforeAll {
        Import-Module "$PSScriptRoot\..\OSDCloudCustomBuilder.psd1" -Force
    }

    It "should return a wrapped PowerShell 7 command" {
        $content = 'Write-Host "Test from PS7"'
        $result = Get-PWsh7WrappedContent -Content $content
        $result | Should -BeLike '*pwsh*'
        $result | Should -Match 'Write-Host "Test from PS7"'
    }
}