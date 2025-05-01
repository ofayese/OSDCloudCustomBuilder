# File: Tests/Private/Copy-CustomizationScripts.Tests.ps1
# Requires -Modules Pester

BeforeAll {
    # Import the function to test
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    $moduleRoot = Resolve-Path "$here/../../"
    . "$moduleRoot/Private/Copy-CustomizationScripts.ps1"
    
    # Import required dependencies
    . "$moduleRoot/Private/Copy-FilesInParallel.ps1"
    . "$moduleRoot/Private/Invoke-WithRetry.ps1"
    
    # Mock Write-OSDCloudLog to avoid errors
    function Write-OSDCloudLog {
        param($Message, $Level, $Component, $Exception)
        # Do nothing for tests
    }
}

Describe 'Copy-CustomizationScripts' {
    Context 'Parameter validation' {
        It 'Should have mandatory WorkspacePath parameter' {
            (Get-Command Copy-CustomizationScripts).Parameters['WorkspacePath'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory | Should -Be $true
        }
        
        It 'Should have optional ScriptPath parameter' {
            (Get-Command Copy-CustomizationScripts).Parameters['ScriptPath'].Attributes |
                Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } |
                Select-Object -ExpandProperty Mandatory | Should -Be $false
        }
    }
    
    Context 'Basic functionality' {
        BeforeAll {
            # Create test directories and files
            $testRoot = Join-Path -Path $TestDrive -ChildPath "CopyCustomizationScriptsTest"
            $testWorkspace = Join-Path -Path $testRoot -ChildPath "Workspace"
            $testScripts = Join-Path -Path $testRoot -ChildPath "Scripts"
            
            # Create directories
            New-Item -Path $testWorkspace -ItemType Directory -Force
            New-Item -Path $testScripts -ItemType Directory -Force
            
            # Create test script files
            "# Test script 1" | Out-File -FilePath (Join-Path -Path $testScripts -ChildPath "script1.ps1") -Force
            "# Test script 2" | Out-File -FilePath (Join-Path -Path $testScripts -ChildPath "script2.ps1") -Force
            
            # Create subdirectory with scripts
            New-Item -Path (Join-Path -Path $testScripts -ChildPath "Subfolder") -ItemType Directory -Force
            "# Subfolder script" | Out-File -FilePath (Join-Path -Path $testScripts -ChildPath "Subfolder\script3.ps1") -Force
            
            # Mock Copy-FilesInParallel
            Mock Copy-FilesInParallel {
                param($SourcePath, $DestinationPath, $FileFilter, $Recurse, $MaxThreads)
                
                # Simple implementation for testing
                if ($Recurse) {
                    Get-ChildItem -Path $SourcePath -Filter $FileFilter -Recurse | ForEach-Object {
                        $destFile = $_.FullName.Replace($SourcePath, $DestinationPath)
                        $destDir = Split-Path -Path $destFile -Parent
                        
                        if (-not (Test-Path -Path $destDir)) {
                            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
                        }
                        
                        Copy-Item -Path $_.FullName -Destination $destFile -Force
                    }
                }
                else {
                    Get-ChildItem -Path $SourcePath -Filter $FileFilter | ForEach-Object {
                        $destFile = Join-Path -Path $DestinationPath -ChildPath $_.Name
                        Copy-Item -Path $_.FullName -Destination $destFile -Force
                    }
                }
                
                return $true
            }
        }
        
        It 'Should copy scripts to workspace' {
            # Arrange
            $targetScriptsPath = Join-Path -Path $testWorkspace -ChildPath "OSDCloud\Scripts"
            
            # Act
            $result = Copy-CustomizationScripts -WorkspacePath $testWorkspace -ScriptPath $testScripts
            
            # Assert
            $result | Should -Be $true
            Should -Invoke Copy-FilesInParallel -Times 1 -Exactly
        }
        
        It 'Should create target directory if it does not exist' {
            # Arrange
            $newWorkspace = Join-Path -Path $testRoot -ChildPath "NewWorkspace"
            New-Item -Path $newWorkspace -ItemType Directory -Force
            $targetScriptsPath = Join-Path -Path $newWorkspace -ChildPath "OSDCloud\Scripts"
            
            # Act
            $result = Copy-CustomizationScripts -WorkspacePath $newWorkspace -ScriptPath $testScripts
            
            # Assert
            $result | Should -Be $true
            Test-Path -Path $targetScriptsPath -PathType Container | Should -Be $true
        }
        
        It 'Should handle empty script path gracefully' {
            # Arrange
            $emptyScriptsPath = Join-Path -Path $testRoot -ChildPath "EmptyScripts"
            New-Item -Path $emptyScriptsPath -ItemType Directory -Force
            
            # Act
            $result = Copy-CustomizationScripts -WorkspacePath $testWorkspace -ScriptPath $emptyScriptsPath
            
            # Assert
            $result | Should -Be $true
        }
        
        It 'Should handle non-existent script path gracefully' {
            # Act & Assert
            { Copy-CustomizationScripts -WorkspacePath $testWorkspace -ScriptPath "C:\NonExistentPath" } | Should -Not -Throw
        }
    }
}