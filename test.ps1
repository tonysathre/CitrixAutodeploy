#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.6.1'}

[CmdletBinding()]
param (
[   Parameter()]
    [System.IO.FileInfo[]]$Path = "${PSScriptRoot}\tests",

    [Parameter()]
    [ValidateSet('Diagnostic', 'Detailed', 'Normal', 'Minimal', 'None')]
    [string]$Output = 'Detailed',

    [Parameter()]
    [ValidateSet('None', 'FirstLine', 'Filtered','Full')]
    $StackTraceVerbosity = 'Filtered',

    [Parameter()]
    [bool]$CodeCoverageEnabled = $false
)

$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Output.Verbosity                   = $Output
$PesterConfiguration.Run.Path                           = $Path
$PesterConfiguration.Output.StackTraceVerbosity         = $StackTraceVerbosity
$PesterConfiguration.CodeCoverage.Enabled               = $CodeCoverageEnabled
$PesterConfiguration.CodeCoverage.Path                  = $Path
$PesterConfiguration.CodeCoverage.CoveragePercentTarget = 75

Invoke-Pester -Configuration $PesterConfiguration
