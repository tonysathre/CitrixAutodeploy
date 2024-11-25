Describe 'Test-MachineCountExceedsLimit' {
    BeforeDiscovery {
        @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.MachineCreation.Commands"
        ) | Import-Module -Force -ErrorAction Stop 3> $null

        $MockDesktopGroup = New-BrokerDesktopGroupMock

        $MockCatalog = New-BrokerCatalogMock
    }

    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Test-MachineCountExceedsLimit.ps1"
    }

    BeforeEach {
        Mock Get-BrokerMachine {
        return @(1..5 | ForEach-Object {
                            New-MockObject -Type ([Citrix.Broker.Admin.SDK.Machine]) -Properties @{
                            Name = "Machine$_"
                        }
                    }
                )
            }
        }

    $Types = @($MockCatalog, $MockDesktopGroup)

    Context 'When InputObject is type <_.GetType().FullName>' -ForEach $Types {

        It 'Should return $true if machine count exceeds MaxMachines' {
            $Result = Test-MachineCountExceedsLimit -AdminAddress 'TestAdminAddress' -InputObject $_ -MaxMachines 3
            $Result | Should -Be $true
        }

        It 'Should return $false if machine count is less than MaxMachines' {
            $Result = Test-MachineCountExceedsLimit -AdminAddress 'TestAdminAddress' -InputObject $_ -MaxMachines 10
            $Result | Should -Be $false
        }
    }

    Context 'Error Handling' {
        It 'Should throw an error if Get-BrokerMachine fails' {
            Mock Get-BrokerMachine {
                throw 'Mocked exception'
            }

            { Test-MachineCountExceedsLimit -AdminAddress 'TestAdminAddress' -InputObject $MockCatalog -MaxMachines 3 } | Should -Throw
        }

        It 'Should throw an error if InputObject is not a valid type' {
            { Test-MachineCountExceedsLimit -AdminAddress 'TestAdminAddress' -InputObject 'InvalidType' -MaxMachines 3 } | Should -Throw
        }
    }
}
