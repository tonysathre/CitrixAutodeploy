
Describe 'New-CtxAutodeployVM' {
    BeforeAll {
        Import-Module "${PSScriptRoot}/Pester.Helper.psm1" 3> $null
        @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.MachineCreation.Commands",
            "${PSScriptRoot}\..\module\CitrixAutodeploy"
        ) | Import-Module -Force -ErrorAction Stop 3> $null
        Initialize-CtxAutodeployLogger -LogLevel Debug -AddEnrichmentWithExceptionDetails
    }

    BeforeEach {
        $AdminAddress  = 'test'
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
            "${PSScriptRoot}\..\module\CitrixAutodeploy"
        ) | Remove-Module -Force
    }

    Context 'When creating a new VM' {
        It 'should create a new VM successfully' {
            Mock Get-ProvScheme       { return (Get-MockProvScheme) }
            Mock Get-AcctIdentityPool { return (Get-MockAcctIdentityPool) }
            Mock New-AcctADAccount    { return (New-MockAcctADAccount) }
            Mock New-ProvVM           { return (New-MockProvVM) }
            Mock New-BrokerMachine    { return (New-MockBrokerMachine) }
            Mock Get-ProvTask         { return (Get-MockProvTask -Status 'Finished') }

            $NewVMParams = @{
                AdminAddress  = $AdminAddress
                BrokerCatalog = $BrokerCatalog
                DesktopGroup  = $DesktopGroup
                Logging       = $Logging
            }

            $Result = New-CtxAutodeployVM @NewVMParams

            #Should -Invoke New-BrokerMachine -Times 1
            #Assert-MockCalled -CommandName Get-ProvScheme -Times 1 -Scope It
            #Assert-MockCalled -CommandName Get-AcctIdentityPool -Times 1

            $Result.MachineName | Should -Not -BeNullOrEmpty
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
}