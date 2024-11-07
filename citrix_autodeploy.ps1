#Requires -Modules PoShLog

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
    $MaxRecordCount = $(if ($env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT) { $env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT } else { 10000 }),

    [Parameter()]
    [switch]$DryRun = [System.Convert]::ToBoolean($env:CITRIX_AUTODEPLOY_DRYRUN),

    [Parameter()]
    [string]$LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{Level:u3}] {Message:lj}{NewLine}{Exception}'
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue 4> $null

Invoke-CtxAutodeployJob -FilePath $FilePath -LogLevel $LogLevel -LogFile $LogFile -MaxRecordCount $MaxRecordCount -DryRun:$DryRun -LogOutputTemplate $LogOutputTemplate
