Describe 'Wait-ForIdentityPoolUnlock' {
    Context 'When the identity pool remains locked beyond the timeout period' {
        Mock Get-AcctIdentityPool { return Get-AcctIdentityPoolMock -Lock $true }

        Mock -CommandName Unlock-AcctIdentityPool -MockWith {}

        It 'Should wait until the pool is unlocked and then return' {
            $IdentityPoolLockedTimeout = 2
            $StartTime = Get-Date
            Wait-ForIdentityPoolUnlock -IdentityPoolLockedTimeout $IdentityPoolLockedTimeout
            $EndTime = Get-Date
            $ExecutionTime = $EndTime - $StartTime

            $ExecutionTime.TotalSeconds | Should -BeGreaterThan $IdentityPoolLockedTimeout
        }
    }
}
