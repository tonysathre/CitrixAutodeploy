# Import the module containing the function to be tested
Import-Module -Name '../module/CitrixAutodeploy/functions/public/Initialize-CtxAutodeployEnv.ps1'

Describe 'Initialize-CtxAutodeployEnv' {
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

        It 'Should log a verbose message when called' {
            $VerbosePreference = 'Continue'
            $VerboseMessages = & {
                Initialize-CtxAutodeployEnv -Verbose
            } 4>&1

            $VerboseMessages | Should -Contain 'Function Initialize-CtxAutodeployEnv called'
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