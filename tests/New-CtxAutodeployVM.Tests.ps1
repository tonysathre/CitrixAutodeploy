[CmdletBinding()]
param ()

Describe 'New-CtxAutodeployVM' {
    BeforeAll {
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop 3> $null 4> $null
        Import-CitrixPowerShellModules 3> $null 4> $null

        Mock Get-ProvScheme       { return Get-ProvSchemeMock                    }
        Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $false }
        Mock New-AcctADAccount    { return New-AcctADAccountMock                 }
        Mock New-ProvVM           { return Get-ProvTaskMock                      }
        Mock New-BrokerMachine    { return New-BrokerMachineMock                 }
        Mock Get-ProvTask         { return Get-ProvTaskMock                      }
        Mock Add-BrokerMachine    { return Add-BrokerMachineMock                 }

        $Params = @{
            AdminAddress  = New-MockAdminAddress
            BrokerCatalog = New-BrokerCatalogMock
            DesktopGroup  = New-BrokerDesktopGroupMock
            Logging       = New-CtxHighLevelLoggerMock
        }
    }

    BeforeEach {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\New-CtxAutodeployVM.ps1"
    }

    AfterAll {
        if (-not $env:CI) {
            Remove-CitrixPowerShellModules
        }
    }

    It 'Should create a new Machine Creation Services machine successfully' {
        { New-CtxAutodeployVM @Params } | Should -Not -Throw
    }

    It 'Should return an object of type Citrix.Broker.Admin.SDK.Machine' {
        $Result = New-CtxAutodeployVM @Params
        $Result[1] | Should -BeOfType Citrix.Broker.Admin.SDK.Machine # TODO(tsathre): Figure out why $Result is an array
    }

    It 'Should call the required Citrix cmdlets' {
        { New-CtxAutodeployVM @Params } | Should -Not -Throw
        Should -Invoke Get-ProvScheme       -Times 1
        Should -Invoke Get-AcctIdentityPool -Times 1
        Should -Invoke New-AcctADAccount    -Times 1
        Should -Invoke New-ProvVM           -Times 1
        Should -Invoke New-BrokerMachine    -Times 1
        Should -Invoke Get-ProvTask         -Times 1
        Should -Invoke Add-BrokerMachine    -Times 1
    }

    Context 'When identity pool is locked' {
        It 'Should call Wait-ForIdentityPoolUnlock at least one time' {
            Mock Get-AcctIdentityPool       { return Get-AcctIdentityPoolMock -Lock $true }
            Mock Wait-ForIdentityPoolUnlock { return $null } -Module CitrixAutodeploy

            { New-CtxAutodeployVM @Params -Timeout 1 } | Should -Not -Throw

            Should -Invoke Wait-ForIdentityPoolUnlock -Times 1
        }
    } -Skip

    Context 'When an error occurs' {
        BeforeEach {
            Mock Write-ErrorLog {}
        }

        It 'Should log the error' {
            Mock Get-ProvScheme { throw 'MockException' }
            { New-CtxAutodeployVM @Params } | Should -Throw
            Should -Invoke Write-ErrorLog -Times 1
        }

        It 'Should throw an exception' {
            Mock Get-ProvScheme { throw 'MockException' }
            { New-CtxAutodeployVM @Params } | Should -Throw
        }

        It 'Should attempt to rollback changes' {
            Mock Write-ErrorLog {}
            Mock New-ProvVM           { return Get-ProvTaskMock  }
            Mock Get-ProvTask         { return New-ProvTaskMock -Status Finished -TerminatingError 'MockTerminatingError' -Active $false  }
            Mock Unlock-ProvVM        { return $null }
            Mock Remove-ProvVM        { return $null }
            Mock Remove-AcctADAccount { return $null }

            New-CtxAutodeployVM @Params

            Should -Invoke Write-ErrorLog       -Times 1
            Should -Invoke Remove-ProvVM        -Times 1
            Should -Invoke Remove-AcctADAccount -Times 1
        } -Skip
    }

    It 'Should handle machine lock during rollback' {
        Mock Get-ProvVM -MockWith { return Get-ProvVMMock }
        Mock Get-ProvTask { return New-ProvTaskMock -Active $false -TerminatingError 'MockError' }

        Mock Unlock-ProvVM

        { New-CtxAutodeployVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -Logging $Logging } | Should -Throw

        Assert-MockCalled -CommandName Unlock-ProvVM -Times 1
    } -Skip
}
