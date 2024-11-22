[CmdletBinding()]
param ()

Describe 'Start-CtxHighLevelLogger' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Start-CtxHighLevelLogger.ps1"
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null
        Import-CitrixPowerShellModules
    }

    Context 'Mandatory Parameters' {
        It 'Should start high-level logging with mandatory parameters' {
            $Params = @{
                AdminAddress = New-MockAdminAddress
                Text         = '[PESTER] Starting high-level logging'
            }

            Mock Start-LogHighLevelOperation { return Start-LogHighLevelOperationMock @Params }

            $Logging = Start-CtxHighLevelLogger @Params

            $Logging        | Should -BeOfType 'Citrix.ConfigurationLogging.Sdk.HighLevelOperation'
            $Logging.Source | Should -Be 'Citrix Autodeploy'
            $Logging.Text   | Should -Be $Params.Text
        }
    }

    Context 'Optional Parameters' {
        It 'Should start high-level logging with custom source' {
            $Params = @{
                AdminAddress = New-MockAdminAddress
                Source       = 'Custom Source'
                Text         = '[PESTER] Starting high-level logging with custom source'
            }

            Mock Start-LogHighLevelOperation { return Start-LogHighLevelOperationMock @Params }

            $Logging = Start-CtxHighLevelLogger @Params

            $Logging        | Should -BeOfType 'Citrix.ConfigurationLogging.Sdk.HighLevelOperation'
            $Logging.Source | Should -Be $Params.Source
            $Logging.Text   | Should -Be $Params.Text
        }
    }

    Context 'Error handling' {
        It 'Should throw an exception if an error occurs' {
            $Params = @{
                AdminAddress = 'BadAdminAddress'
                Text         = 'Bad AdminAddress'
            }

            { Start-CtxHighLevelLogger @Params } | Should -Throw -ExceptionType 'System.InvalidOperationException' -ExpectedMessage "An invalid URL was given for the service.*"
        }
        # FIX(tsathre): Not working
        It 'Should log a fatal error' {
            Mock Write-FatalLog {}
            Should -Invoke Write-FatalLog -Exactly 1 -Scope It
        } -Skip
    }
}
