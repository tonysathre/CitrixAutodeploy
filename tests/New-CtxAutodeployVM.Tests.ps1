[CmdletBinding()]
param ()

Describe 'New-CtxAutodeployVM' {
    BeforeAll {
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop
        Import-CitrixPowerShellModules
        Enable-Logging

        Mock Get-ProvScheme       { return Get-ProvSchemeMock                    } -Module CitrixAutodeploy
        Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $false } -Module CitrixAutodeploy
        Mock New-AcctADAccount    { return New-AcctADAccountMock                 } -Module CitrixAutodeploy
        Mock New-ProvVM           { return Get-ProvTaskMock                      } -Module CitrixAutodeploy
        Mock New-BrokerMachine    { return New-BrokerMachineMock                 } -Module CitrixAutodeploy
        Mock Get-ProvTask         { return Get-ProvTaskMock                      } -Module CitrixAutodeploy
        Mock Add-BrokerMachine    { return Add-BrokerMachineMock                 } -Module CitrixAutodeploy

        $Params = @{
            AdminAddress  = New-MockAdminAddress
            BrokerCatalog = New-BrokerCatalogMock
            DesktopGroup  = New-BrokerDesktopGroupMock
            Logging       = New-CtxHighLevelLoggerMock
        }
    }

    BeforeEach {

    }

    AfterAll {
        if (-not $env:CI) {
            Remove-CitrixPowerShellModules
            Remove-CitrixAutodeployModule
        }

        if ($VerbosePreference -eq 'Continue') {
            $global:VerbosePreference = 'SilentlyContinue'
            Close-Logger
        }

        if ($DebugPreference -eq 'Continue') {
            $global:DebugPreference = 'SilentlyContinue'
            Close-Logger
        }
    }

    It 'should create a new Machine Creation Services machine successfully' {
        { New-CtxAutodeployVM @Params } | Should -Not -Throw
    }

    It 'should return an object of type Citrix.Broker.Admin.SDK.Machine' {
        $Result = New-CtxAutodeployVM @Params
        $Result[1] | Should -BeOfType Citrix.Broker.Admin.SDK.Machine # TODO(tsathre): Figure out why $Result is an array
    }

    It 'should call the required Citrix cmdlets' {
        { New-CtxAutodeployVM @Params } | Should -Not -Throw
        Should -Invoke Get-ProvScheme       -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke Get-AcctIdentityPool -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke New-AcctADAccount    -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke New-ProvVM           -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke New-BrokerMachine    -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke Get-ProvTask         -Times 1 -ModuleName CitrixAutodeploy
        Should -Invoke Add-BrokerMachine    -Times 1 -ModuleName CitrixAutodeploy
    }

    Context 'when identity pool is locked' {
        It 'should call Wait-ForIdentityPoolUnlock at least one time' {
            Mock Get-AcctIdentityPool       { return Get-AcctIdentityPoolMock -Lock $true }
            Mock Wait-ForIdentityPoolUnlock { return $null } -Module CitrixAutodeploy

            { New-CtxAutodeployVM @Params -Timeout 1 } | Should -Not -Throw

            Should -Invoke Wait-ForIdentityPoolUnlock -Times 1
        }
    } -Skip

    Context 'when an error occurs' {
        BeforeEach {
            Mock Write-ErrorLog {} -Module CitrixAutodeploy
        }

        It 'should log the error' {
            Mock Get-ProvScheme { throw 'MockException' } -Module CitrixAutodeploy
            { New-CtxAutodeployVM @Params } | Should -Throw
            Should -Invoke Write-ErrorLog -Times 1 -Module CitrixAutodeploy
        }

        It 'should throw an exception' {
            Mock Get-ProvScheme { throw 'MockException' } -Module CitrixAutodeploy
            { New-CtxAutodeployVM @Params } | Should -Throw
        }

        It 'should attempt to rollback changes' {
            Mock Write-ErrorLog {}
            Mock New-ProvVM           { return Get-ProvTaskMock  } -Module CitrixAutodeploy
            Mock Get-ProvTask         { return New-ProvTaskMock -Status Finished -TerminatingError 'MockTerminatingError' -Active $false  } -Module CitrixAutodeploy
            Mock Unlock-ProvVM        { return $null } -Module CitrixAutodeploy
            Mock Remove-ProvVM        { return $null } -Module CitrixAutodeploy
            Mock Remove-AcctADAccount { return $null } -Module CitrixAutodeploy

            New-CtxAutodeployVM @Params

            Should -Invoke Write-ErrorLog       -Times 1
            Should -Invoke Remove-ProvVM        -Times 1
            Should -Invoke Remove-AcctADAccount -Times 1
        } -Skip
    }

    It 'should handle machine lock during rollback' {
        Mock Get-ProvVM -MockWith {
            return @{
                VMName = 'TestVM'
                Lock   = $true
            }
        }

        Mock Get-ProvTask -MockWith {
            return @{
                Active           = $false
                TerminatingError = 'TestError'
            }
        }

        Mock Unlock-ProvVM

        { New-CtxAutodeployVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -Logging $Logging } | Should -Throw

        Assert-MockCalled -CommandName Unlock-ProvVM -Times 1
    } -Skip
}
