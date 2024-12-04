Remove-Module Microsoft.PowerShell.PSResourceGet -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop

$Author            = 'Tony Sathre'
$CompanyName       = 'Tony Sathre'
$Description       = 'This module is used to automate the creation of Citrix virtual desktops in a Citrix Virtual Apps & Desktops environment.'
$ModuleVersion     = '2.0.0.0'
$Copyright         = "(c) {0} ${Author}. All rights reserved." -f (Get-Date -Format 'yyyy')
$ProjectUri        = 'https://github.com/tonysathre/CitrixAutodeploy'

$BasePath          = "${PSScriptRoot}\module\CitrixAutodeploy"
$Path              = "${BasePath}\CitrixAutodeploy.psd1"
$RootModule        = "${PSScriptRoot}\module\CitrixAutodeploy\CitrixAutodeploy.psm1"
$NestedModules     = Get-ChildItem -Recurse ${BasePath}\functions\*.ps1 | ForEach-Object { ".\functions\$(Split-Path -Leaf $_.Directory)\$($_.Name)" }
$FunctionsToExport = (Get-ChildItem ${BasePath}\functions\public\*.ps1).Name -replace '\.ps1$'
$RequiredModules   = @('PoShLog')
#$ScriptsToProcess = @('.\functions\private\Initialize-InternalLogger.ps1')
$VariablesToExport = @('InternalLogger')


$ModuleManifest = @{
    Author            = $Author
    CompanyName       = $CompanyName
    Description       = $Description
    Copyright         = $Copyright
    ProjectUri        = $ProjectUri
    ModuleVersion     = $ModuleVersion
    RootModule        = $RootModule
    Path              = $Path
    FunctionsToExport = $FunctionsToExport
    NestedModules     = $NestedModules
    RequiredModules   = $RequiredModules
    #ScriptsToProcess  = $ScriptsToProcess
    VariablesToExport = $VariablesToExport
}

Update-PSModuleManifest @ModuleManifest

# Trim trailing whitespace added by Update-PSModuleManifest
(Get-Content $Path).TrimEnd() | Set-Content $Path
