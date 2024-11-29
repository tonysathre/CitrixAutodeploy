[CmdletBinding()]
param ()

Describe 'Initialize-CtxAutodeployEnv' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Initialize-CtxAutodeployEnv.ps1"
    }

    BeforeEach {
        $Modules = @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.MachineCreation.Commands"
        )

        $Modules | Remove-Module -Force -ErrorAction SilentlyContinue
    }

    It 'Should import the required modules without errors' {
        Mock Import-Module { return $true }

        { Initialize-CtxAutodeployEnv } | Should -Not -Throw
    }

    It 'PowerShell module <_> should be available in the session' -ForEach $Modules {
        { Initialize-CtxAutodeployEnv } | Should -Not -Throw
        Get-Module -ListAvailable $_
    }

    It 'Should throw an error if a module fails to import' {
        Mock Import-Module { throw 'Module import failed' }

        { Initialize-CtxAutodeployEnv } | Should -Throw -ExpectedMessage 'Module import failed' -ExceptionType 'System.Management.Automation.RuntimeException'
    }
}
