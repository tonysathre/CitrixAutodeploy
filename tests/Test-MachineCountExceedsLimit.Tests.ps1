Describe 'Test-MachineCountLimit' {
    BeforeDiscovery {
        $MockDesktopGroup = New-MockObject -Type 'Citrix.Broker.Admin.SDK.DesktopGroup' -Properties @{
            Name = 'MockDesktopGroup'
        }

        $MockCatalog = New-MockObject -Type 'Citrix.Broker.Admin.SDK.Catalog' -Properties @{
            Name = 'MockCatalog'
        }
    }

    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Test-MachineCountLimit.ps1"
    }

    BeforeEach {
        Mock Write-InfoLog    {}
        Mock Write-DebugLog   {}
        Mock Write-ErrorLog   {}
        Mock Write-VerboseLog {}
        Mock Write-WarningLog {}

        Mock Get-BrokerMachine {
        return @(1..5 | ForEach-Object {
                            New-MockObject -Type 'Citrix.Broker.Admin.SDK.Machine' -Properties @{
                            Name = "Machine$_"
                        }
                    }
                )
            }
        }

    $Types = @($MockCatalog, $MockDesktopGroup)

    Context 'When InputObject is type <_.GetType().FullName>' -ForEach $Types {

        It 'Should return $true if machine count exceeds MaxMachines' {
            $Result = Test-MachineCountLimit -AdminAddress 'TestAdminAddress' -InputObject $_ -MaxMachines 3
            $Result | Should -Be $true
        }

        It 'Should return $false if machine count is less than MaxMachines' {
            $Result = Test-MachineCountLimit -AdminAddress 'TestAdminAddress' -InputObject $_ -MaxMachines 10
            $Result | Should -Be $false
        }
    }

    Context 'Error Handling' {
        It 'Should throw an error if Get-BrokerMachine fails' {
            Mock Get-BrokerMachine {
                throw 'Mocked exception'
            }

            { Test-MachineCountLimit -AdminAddress 'TestAdminAddress' -InputObject $MockCatalog -MaxMachines 3 } | Should -Throw
        }
    }
}
