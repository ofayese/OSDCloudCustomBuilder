@{
    # Include all default rules
    IncludeDefaultRules = $true

    # Specific rules to include
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSAvoidUsingPositionalParameters',
        'PSUseProcessBlockForPipelineCommand',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidGlobalVars',
        'PSAvoidUsingInvokeExpression',
        'PSUseSingularNouns',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingUsernameAndPasswordParams',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSUseCmdletCorrectly',
        'PSUseOutputTypeCorrectly',
        'PSAvoidDefaultValueSwitchParameter',
        'PSMissingModuleManifestField',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseCompatibleCmdlets',
        'PSUseCompatibleSyntax'
    )

    # Rules to exclude (if any)
    ExcludeRules = @(
        # Exclude Write-Host rule for logging functions where it's intentional
        # 'PSAvoidUsingWriteHost'
    )

    # Severity levels to include
    Severity = @('Error', 'Warning', 'Information')

    # Custom rule configurations
    Rules = @{
        PSUseCompatibleCmdlets = @{
            # Target PowerShell versions
            Compatibility = @('desktop-5.1.14393.206-windows', 'core-6.1.0-windows', 'core-7.0.0-windows')
        }

        PSUseCompatibleSyntax = @{
            # Enable checking for PowerShell version compatibility
            Enable = $true
            TargetVersions = @('5.1', '7.0')
        }

        PSAvoidUsingCmdletAliases = @{
            # Allow certain common aliases in specific contexts
            Whitelist = @()
        }

        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }

        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }

        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }
    }
}
