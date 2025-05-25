Describe 'OSDCloudCustomBuilder Functions' {
    It 'Start-OSDCloudBuild should exist' {
        Get-Command -Name Start-OSDCloudBuild -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
