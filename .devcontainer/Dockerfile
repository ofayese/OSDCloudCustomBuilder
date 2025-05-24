FROM mcr.microsoft.com/powershell:latest

RUN pwsh -NoProfile -Command \
    Install-Module Pester -Force -Scope AllUsers; \
    Install-Module PSScriptAnalyzer -Force -Scope AllUsers
