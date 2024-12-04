[CmdletBinding()]
param ()

Describe 'Test-MachineCountExceedsLimit' {
    BeforeDiscovery {
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null 4> $null
        Import-CitrixPowerShellModules 3> $null 4> $null
    }

    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Test-MachineCountExceedsLimit.ps1"
    }

    BeforeEach {
        $AdminAddress = New-MockAdminAddress
        Mock Get-BrokerMachine {
            return @(1..5 | ForEach-Object { New-BrokerMachineMock })
        }
    }

    $MockDesktopGroup = New-BrokerDesktopGroupMock
    $MockCatalog      = New-BrokerCatalogMock
    $Types            = @($MockCatalog, $MockDesktopGroup)

    Context 'When InputObject is type [<_.GetType().FullName>]' -ForEach $Types {
        It 'Should return $true if machine count exceeds MaxMachines' {
            $Result = Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $_ -MaxMachines 3
            $Result | Should -Be $true
        }

        It 'Should return $false if machine count is less than MaxMachines' {
            $Result = Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $_ -MaxMachines 10
            $Result | Should -Be $false
        }

        Context 'Error handling' {
            It 'Should throw a [ParameterBindingException] exception if InputObject is not a valid type' {
                $Params = @{
                    AdminAddress = $AdminAddress
                    InputObject  = 'InvalidType'
                    MaxMachines  = 3
                }

                { Test-MachineCountExceedsLimit @Params } | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException]) -ExpectedMessage "Cannot validate argument on parameter 'InputObject'*"
            }

            It 'Should throw an exception if Get-BrokerMachine fails' {
                $MockException = 'Mocked exception'
                Mock Get-BrokerMachine { throw $MockException }

                $Params = @{
                    AdminAddress = $AdminAddress
                    InputObject  = $_
                    MaxMachines  = 3
                }

                { Test-MachineCountExceedsLimit @Params } | Should -Throw -ExpectedMessage $MockException
            }

            It 'Should log the error' {
                $Params = @{
                    AdminAddress = $AdminAddress
                    InputObject  = $_
                    MaxMachines  = 3
                }

                $MockException = 'Mocked exception'
                Mock Write-ErrorLog {}
                Mock Get-BrokerMachine { throw $MockException }

                { Test-MachineCountExceedsLimit @Params } | Should -Throw -ExpectedMessage $MockException
                Should -Invoke Write-ErrorLog -Exactly 1 -Scope It
            }
        }
    }
}
