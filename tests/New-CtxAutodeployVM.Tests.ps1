[CmdletBinding()]
param ()

Describe 'New-CtxAutodeployVM' {
    BeforeAll {
        @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.MachineCreation.Commands",
            "${PSScriptRoot}\..\module\CitrixAutodeploy",
            "${PSScriptRoot}\Pester.Helper.psm1"
        ) | Import-Module -Force -ErrorAction Stop 3> $null

        if ($VerbosePreference -eq 'Continue') {
            Initialize-CtxAutodeployLogger -LogLevel 'Verbose' -AddEnrichWithExceptionDetails
        }

        Mock Get-ProvScheme       { return Get-MockProvScheme                    } -Module CitrixAutodeploy
        Mock Get-AcctIdentityPool { return Get-MockAcctIdentityPool -Lock $false } -Module CitrixAutodeploy
        Mock New-AcctADAccount    { return New-MockAcctADAccount                 } -Module CitrixAutodeploy
        Mock New-ProvVM           { return Get-MockProvTask                      } -Module CitrixAutodeploy
        Mock New-BrokerMachine    { return New-MockBrokerMachine                 } -Module CitrixAutodeploy
        Mock Get-ProvTask         { return Get-MockProvTask                      } -Module CitrixAutodeploy
        Mock Add-BrokerMachine    { return Add-MockBrokerMachine                 } -Module CitrixAutodeploy
    }

    BeforeEach {
        $AdminAddress  = New-MockAdminAddress
        $BrokerCatalog = New-MockBrokerCatalog
        $DesktopGroup  = New-MockDesktopGroup
        $Logging       = New-MockCtxHighLevelLogger
    }

    AfterAll {
        @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.MachineCreation.Commands",
            "${PSScriptRoot}\..\module\CitrixAutodeploy",
            "${PSScriptRoot}\Pester.Helper.psm1"
        ) | Remove-Module -Force

        if ($VerbosePreference -eq 'Continue') {
            $global:VerbosePreference = 'SilentlyContinue'
            Close-Logger
        }
    }

    It 'should create a new VM successfully' {
        $NewVMParams = @{
            AdminAddress  = $AdminAddress
            BrokerCatalog = $BrokerCatalog
            DesktopGroup  = $DesktopGroup
            Logging       = $Logging
        }

        $Result = New-CtxAutodeployVM @NewVMParams
        $Result | Out-File asdfasdf.txt
        $Result.MachineName | Should -Be 'PESTER-123456'
        $Result[1] | Should -BeOfType Citrix.Broker.Admin.SDK.Machine # TODO(tsathre): Figure out why $Result is an array
    }

    It 'should handle locked identity pool' {
        Mock Get-AcctIdentityPool -MockWith {
            return @{
                IdentityPoolName = 'TestPool'
                Lock             = $true
            }
        }

        Mock Wait-ForIdentityPoolUnlock

        $result = New-CtxAutodeployVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -Logging $Logging

        Assert-MockCalled -CommandName Wait-ForIdentityPoolUnlock -Times 1
    } -Skip

    It 'should handle provisioning task failure' {
        Mock Get-ProvTask -MockWith {
            return @{
                Active           = $false
                TerminatingError = 'TestError'
            }
        }

        Mock Get-ProvVM -MockWith {
            return @{
                VMName = 'TestVM'
                Lock   = $false
            }
        }

        Mock Remove-ProvVM
        Mock Remove-AcctADAccount

        { New-CtxAutodeployVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -Logging $Logging } | Should -Throw

        Assert-MockCalled -CommandName Write-ErrorLog -Times 1
        Assert-MockCalled -CommandName Remove-ProvVM -Times 1
        Assert-MockCalled -CommandName Remove-AcctADAccount -Times 1
    } -Skip

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

    It 'should log an error if an exception is thrown' {
        Mock Get-ProvScheme -MockWith { throw 'TestException' }

        { New-CtxAutodeployVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -Logging $Logging } | Should -Throw

        Assert-MockCalled -CommandName Write-ErrorLog -Times 1
    } -Skip
}
