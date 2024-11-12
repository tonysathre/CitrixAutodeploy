[CmdletBinding()]
param ()

Describe 'New-CtxAutodeployVM' {
    BeforeAll {
        @(
            'Citrix.ADIdentity.Commands',
            'Citrix.Broker.Commands',
            'Citrix.ConfigurationLogging.Commands',
            'Citrix.MachineCreation.Commands',
            "${PSScriptRoot}\..\module\CitrixAutodeploy",
            "${PSScriptRoot}\Pester.Helper.psm1"
        ) | Import-Module -Force -ErrorAction Stop 3> $null

        if ($VerbosePreference -eq 'Continue') {
            Initialize-CtxAutodeployLogger -LogLevel Verbose -AddEnrichWithExceptionDetails
        }

        if ($DebugPreference -eq 'Continue') {
            Initialize-CtxAutodeployLogger -LogLevel Debug -AddEnrichWithExceptionDetails
        }

        Mock Get-ProvScheme       { return Get-MockProvScheme                    } -Module CitrixAutodeploy
        Mock Get-AcctIdentityPool { return Get-MockAcctIdentityPool -Lock $false } -Module CitrixAutodeploy
        Mock New-AcctADAccount    { return New-MockAcctADAccount                 } -Module CitrixAutodeploy
        Mock New-ProvVM           { return Get-MockProvTask                      } -Module CitrixAutodeploy
        Mock New-BrokerMachine    { return New-MockBrokerMachine                 } -Module CitrixAutodeploy
        Mock Get-ProvTask         { return Get-MockProvTask                      } -Module CitrixAutodeploy
        Mock Add-BrokerMachine    { return Add-MockBrokerMachine                 } -Module CitrixAutodeploy

        $Params = @{
            AdminAddress  = New-MockAdminAddress
            BrokerCatalog = New-MockBrokerCatalog
            DesktopGroup  = New-MockDesktopGroup
            Logging       = New-MockCtxHighLevelLogger
        }
    }

    BeforeEach {

    }

    AfterAll {
        #@(
        #    'Citrix.ADIdentity.Commands',
        #    'Citrix.Broker.Commands',
        #    'Citrix.ConfigurationLogging.Commands',
        #    'Citrix.MachineCreation.Commands',
        #    "${PSScriptRoot}\..\module\CitrixAutodeploy",
        #    "${PSScriptRoot}\Pester.Helper.psm1"
        #) | Remove-Module -Force

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
            Mock Get-AcctIdentityPool       { return Get-MockAcctIdentityPool -Lock $true }
            Mock Wait-ForIdentityPoolUnlock { return $null } -Module CitrixAutodeploy

            { New-CtxAutodeployVM @Params -Timeout 1 } | Should -Not -Throw

            Should -Invoke Wait-ForIdentityPoolUnlock -Times 1
        }
    } -Skip

    Context 'when an error occurs' {
        BeforeEach {
            Mock Write-ErrorLog {} -Module CitrixAutodeploy
        }

        It 'should throw an exception' {
            Mock Get-ProvScheme { throw 'MockException' } -Module CitrixAutodeploy
            { New-CtxAutodeployVM @Params } | Should -Throw
        }

        It 'should log the error' {
            Mock Get-ProvScheme { throw 'MockException' } -Module CitrixAutodeploy
            { New-CtxAutodeployVM @Params } | Should -Throw
            Should -Invoke Write-ErrorLog -Times 1 -Module CitrixAutodeploy
        }

        It 'should attempt to rollback changes' {
            Mock Write-ErrorLog {}
            Mock New-ProvVM           { return Get-MockProvTask  } -Module CitrixAutodeploy
            Mock Get-ProvTask         { return New-MockProvTask -Status Finished -TerminatingError 'MockTerminatingError' -Active $false  } -Module CitrixAutodeploy
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
