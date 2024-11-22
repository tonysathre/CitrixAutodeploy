#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.6.1'}

using namespace System.Management.Automation

[CmdletBinding()]
param (
    [Parameter()]
    [ArgumentCompleter({
        param ( $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters )
        (Get-ChildItem -Path (Join-Path $PSScriptRoot -ChildPath 'tests')).Name.Where({ $_ -like "$wordToComplete*" }) | ForEach-Object {
            [CompletionResult]::new($_, $_, 'ParameterValue', 'test file')
        }
    })]
    [System.IO.FileInfo[]]$Tests = "${PSScriptRoot}\tests",

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
$PesterConfiguration.Run.Path                           = $Tests
$PesterConfiguration.Output.StackTraceVerbosity         = $StackTraceVerbosity
$PesterConfiguration.CodeCoverage.Enabled               = $CodeCoverageEnabled
$PesterConfiguration.CodeCoverage.Path                  = $Tests
$PesterConfiguration.CodeCoverage.CoveragePercentTarget = 75

Invoke-Pester -Configuration $PesterConfiguration
