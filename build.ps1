Remove-Module Microsoft.PowerShell.PSResourceGet -ErrorAction SilentlyContinue
Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop

$Author            = 'Tony Sathre'
$CompanyName       = 'Tony Sathre'
$Description       = 'This module is used to automate the deployment of Citrix virtual desktops in a Citrix Virtual Apps & Desktops environment.'
$ModuleVersion     = '2.0.0.0'
$Copyright         = "(c) {0} ${Author}. All rights reserved." -f (Get-Date -Format 'yyyy')
$ProjectUri        = 'https://github.com/tonysathre/CitrixAutodeploy'

$BasePath          = "${PSScriptRoot}\module\CitrixAutodeploy"
$NestedModules     = Get-ChildItem -Recurse ${BasePath}\functions\*.ps1 | ForEach-Object { ".\functions\$(Split-Path -Leaf $_.Directory)\$($_.Name)" }
$FunctionsToExport = (Get-ChildItem ${BasePath}\functions\public\*.ps1).Name -replace '\.ps1$'
$RequiredModules   = @('PoShLog')
$ScriptsToProcess  = @('.\functions\private\Initialize-InternalLogger.ps1')
$VariablesToExport = @('InternalLogger')


$ModuleManifest = @{
    Author            = $Author
    CompanyName       = $CompanyName
    Description       = $Description
    Copyright         = $Copyright
    ProjectUri        = $ProjectUri
    ModuleVersion     = $ModuleVersion
    Path              = "${BasePath}\CitrixAutodeploy.psd1"
    FunctionsToExport = $FunctionsToExport
    NestedModules     = $NestedModules
    RequiredModules   = $RequiredModules
    ScriptsToProcess  = $ScriptsToProcess
    VariablesToExport = $VariablesToExport
}

Update-PSModuleManifest @ModuleManifest
