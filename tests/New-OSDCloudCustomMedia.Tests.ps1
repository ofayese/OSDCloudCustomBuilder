Describe "New-OSDCloudCustomMedia Tests" {
    BeforeEach {
        $TestPath = "$TestDrive\Media"
        New-Item -Path $TestPath -ItemType Directory | Out-Null
    }

    It "Should create media in valid path" {
        { New-OSDCloudCustomMedia -Path $TestPath } | Should -Not -Throw
    }

    It "Should fail on invalid path" {
        { New-OSDCloudCustomMedia -Path '' } | Should -Throw
    }
}
