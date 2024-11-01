#Requires -Modules PoShLog

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FilePath = $env:CITRIX_AUTODEPLOY_CONFIG,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
    [string]$LogLevel = $env:CITRIX_AUTODEPLOY_LOGLEVEL,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE,

    [Parameter()]
    $MaxRecordCount = 10000,

    [Parameter()]
    [switch]$DryRun
)

.\citrix_autodeploy.ps1 @PSBoundParameters