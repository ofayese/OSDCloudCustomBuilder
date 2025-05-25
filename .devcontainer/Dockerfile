FROM mcr.microsoft.com/powershell/test-deps:preview-alpine-3.16

RUN pwsh -NoProfile -Command \
    Install-Module Pester -Force -Scope AllUsers; \
    Install-Module PSScriptAnalyzer -Force -Scope AllUsers; \
    Install-Module PSReadLine -Force -Scope AllUsers; \
    Install-Module PSFramework -Force -Scope AllUsers; \
    Install-Module PSDepend -Force -Scope AllUsers; \
    Install-Module PSRule -Force -Scope AllUsers; \
    Install-Module PSRule.Rules.Azure -Force -Scope AllUsers; \
    Install-Module OSD -Force -Scope AllUsers; \
    Install-Module PowershellProTools -Force -Scope AllUsers
