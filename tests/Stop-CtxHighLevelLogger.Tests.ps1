Describe 'Stop-CtxHighLevelLogger' {
    BeforeAll {
        . "$PSScriptRoot\..\module\CitrixAutodeploy\functions\public\Stop-CtxHighLevelLogger.ps1"
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null
        Import-CitrixPowerShellModules
        Enable-Logging
    }

    It 'Should call Stop-LogHighLevelOperation with correct parameters' {
        $Params = @{
            AdminAddress         = New-MockAdminAddress
            HighLevelOperationId = (New-CtxHighLevelLoggerMock).Id
            IsSuccessful         = $true
        }

        Mock Stop-LogHighLevelOperation { return Stop-LogHighLevelOperationMock @Params }

        $Output = Stop-CtxHighLevelLogger @Params
        $Output | Should -BeNullOrEmpty
        Should -Invoke Stop-LogHighLevelOperation -Exactly 1 -Scope It
    }

    Context 'Error handling' {
        It 'Should throw an exception if an error occurs' {
            $Params = @{
                AdminAddress         = 'BadAdminAddress'
                HighLevelOperationId = (New-CtxHighLevelLoggerMock).Id
                IsSuccessful         = $false
            }

            { Stop-CtxHighLevelLogger @Params } | Should -Throw -ExceptionType 'System.InvalidOperationException' -ExpectedMessage 'An invalid URL was given for the service.*'
        }
        # FIX(tsathre): Not working
        It 'Should log a fatal error' {
            Mock Write-FatalLog { }
            Should -Invoke Write-FatalLog -Exactly 1 -Scope It
        } -Skip
    }
}
