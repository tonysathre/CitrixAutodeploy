#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.5.0'}

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = "${PSScriptRoot}\tests",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Diagnostic', 'Detailed', 'Normal', 'Minimal', 'None')]
    [string]$Output = 'Normal'
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue

$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Output.Verbosity = $Output
$PesterConfiguration.Run.Path = $Path
$PesterConfiguration.CodeCoverage.Enabled = $true

Invoke-Pester -Configuration $PesterConfiguration
