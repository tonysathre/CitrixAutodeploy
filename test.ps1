#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.5.0'}

[CmdletBinding()]
param (
[   Parameter()]
    [System.IO.FileInfo[]]$Path = "${PSScriptRoot}\tests",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Diagnostic', 'Detailed', 'Normal', 'Minimal', 'None')]
    [string]$Output = 'Detailed',

    [Parameter()]
    [ValidateSet('None', 'FirstLine', 'Filtered','Full')]
    $StackTraceVerbosity = 'Filtered',

    [Parameter()]
    [bool]$CodeCoverageEnabled = $false
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue

$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Output.Verbosity                      = $Output
$PesterConfiguration.Run.Path                              = $Path
$PesterConfiguration.Output.Verbosity                      = $Output
$PesterConfiguration.Output.StackTraceVerbosity            = $StackTraceVerbosity
$PesterConfiguration.CodeCoverage.Enabled                  = $CodeCoverageEnabled
$PesterConfiguration.CodeCoverage.Path                     = $Path
$PesterConfiguration.CodeCoverage.CoveragePercentTarget    = 75

Invoke-Pester -Configuration $PesterConfiguration
