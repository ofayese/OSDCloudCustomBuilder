Import-Module ModuleBuilder -Force
$Source = Join-Path -Path $PSScriptRoot -ChildPath "src/osdcloudcustombuilder"
$Output = Join-Path -Path $PSScriptRoot -ChildPath "out"
New-Item -ItemType Directory -Force -Path $Output | Out-Null
Build-Module -SourcePath $Source -OutputPath $Output
