Describe 'Initialize-CtxAutodeployEnv' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Initialize-CtxAutodeployEnv.ps1"
        Mock Write-InfoLog {}
        Mock Write-DebugLog {}
        Mock Write-ErrorLog {}
        Mock Write-WarningLog {}
        Mock Write-VerboseLog {}
    }

    Context 'When called' {
        It 'Should import the required modules without errors' {
            Mock Import-Module { return $true } -ModuleName 'CitrixAutodeploy'
            $Modules = @(
                'Citrix.ADIdentity.Commands',
                'Citrix.Broker.Commands',
                'Citrix.ConfigurationLogging.Commands',
                'Citrix.MachineCreation.Commands'
            )

            foreach ($Module in $Modules) {
                Remove-Module -Name $Module -ErrorAction SilentlyContinue
            }

            { Initialize-CtxAutodeployEnv } | Should -Not -Throw
        }

        }

        It 'Should throw an error if a module fails to import' {
            Mock Import-Module { return $true } -ModuleName 'CitrixAutodeploy'
            $InvalidModule = 'NonExistent.Module'
            $Modules = @(
                'Citrix.ADIdentity.Commands',
                'Citrix.Broker.Commands',
                'Citrix.ConfigurationLogging.Commands',
                'Citrix.MachineCreation.Commands',
                $InvalidModule
            )

            foreach ($Module in $Modules) {
                Remove-Module -Name $Module -ErrorAction SilentlyContinue
            }

            { Initialize-CtxAutodeployEnv } | Should -Throw
        }
    }
}