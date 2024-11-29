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
        It 'Should wait until the pool is unlocked and then return' {
            $Loops = 2
            Mock Get-AcctIdentityPool {
                if ($global:InvocationCount -eq $Loops) {
                    return Get-AcctIdentityPoolMock -Lock $false
                }
                $global:InvocationCount++
                return Get-AcctIdentityPoolMock -Lock $true
            }

            $Params = @{
                AdminAddress = New-MockAdminAddress
                IdentityPool = Get-AcctIdentityPoolMock -Lock $true
                Timeout      = $Loops
            }

            $ExecutionTime = Measure-Command {
                Wait-ForIdentityPoolUnlock @Params
            }

            $ExecutionTime.TotalSeconds | Should -BeGreaterThan $Loops
            $ExecutionTime.TotalSeconds | Should -BeLessThan ($Loops + 1)
            Should -Invoke Get-AcctIdentityPool -Exactly $Loops -Scope It
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
