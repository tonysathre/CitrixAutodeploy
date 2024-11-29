[CmdletBinding()]
param ()

Describe 'Wait-ForIdentityPoolUnlock' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null 4> $null
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Wait-ForIdentityPoolUnlock.ps1"
    }

    AfterAll {
        Remove-Variable -Name CallCount -Scope Global
    }

    Context 'When the identity pool is initially unlocked' {
        It 'Should not wait and return immediately' {
            Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $false }

            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $false
                Timeout      = 60
            }

            { Wait-ForIdentityPoolUnlock @Params } | Should -Not -Throw
            Should -Not -Invoke Get-AcctIdentityPool -Scope It
        }
    }

    Context 'When the identity pool unlocks within the timeout period' {
        It 'Should wait until the identity pool is unlocked and then return successfully' {
            # Mock Get-AcctIdentityPool to simulate the pool being locked initially and then unlocked
            # after the second call
            Mock Get-AcctIdentityPool {
                param (
                    [string]$AdminAddress,
                    [string]$IdentityPoolName
                )
                if ($global:CallCount -lt 2) {
                    $global:CallCount++
                    return Get-AcctIdentityPoolMock -Lock $true
                } else {
                    return Get-AcctIdentityPoolMock -Lock $false
                }
            }
            # TODO(tsathre): Add a .5 second buffer to the timeout period to account for execution overhead.
            # A bit janky but it works for now
            $Buffer           = .5
            $global:CallCount = 0
            $Timeout          = 2

            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $true
                Timeout      = $Timeout
            }

            $StartTime = Get-Date
            { Wait-ForIdentityPoolUnlock @Params } | Should -Not -Throw
            $EndTime = Get-Date
            $ExecutionTime = $EndTime - $StartTime

            $ExecutionTime.TotalSeconds | Should -BeGreaterThan 1
            $ExecutionTime.TotalSeconds | Should -BeLessOrEqual ($Timeout + $Buffer)
        }
    }

    Context 'When the identity pool remains locked beyond the timeout period' {
        It 'Should exit after the specified timeout period' {
            Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $true }

            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $true
                Timeout      = 2
            }

            $ExecutionTime = Measure-Command {
                Wait-ForIdentityPoolUnlock @Params
            }

            $ExecutionTime.TotalSeconds | Should -BeGreaterOrEqual 2
            $ExecutionTime.TotalSeconds | Should -BeLessThan 3
            Should -Invoke Get-AcctIdentityPool -Times 2 -Scope It
        }

        It 'Should log a warning' {
            Mock Write-WarningLog {}
            Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $true }

            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $true
                Timeout      = 1
            }

            { Wait-ForIdentityPoolUnlock @Params } | Should -Not -Throw
            Should -Invoke Write-WarningLog -Exactly 1 -Scope It
        }
    }

    Context 'When an error occurs contacting delivery controller' {
        It 'Should throw an exception' {
            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $true
                Timeout      = 1
            }

            $Exception = [System.Exception]
            Mock Get-AcctIdentityPool { throw $Exception }
            { Wait-ForIdentityPoolUnlock @Params } | Should -Throw -ExceptionType ($Exception)
        }
    }
}
