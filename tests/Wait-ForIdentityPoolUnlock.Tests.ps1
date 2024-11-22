# Describe "Wait-ForIdentityPoolUnlock" {
#     BeforeAll {
#         Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
#     }

#     It "Should wait until the identity pool is unlocked within the timeout" {
#         $IdentityPool = [PSCustomObject]@{ Lock = $true }

#         Mock Start-Sleep { $IdentityPool.Lock = $false }

#         { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 5 } | Should -Not -Throw
#     }

#     It "Should timeout if the identity pool remains locked" {
#         $IdentityPool = [PSCustomObject]@{ Lock = $true }

#         { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 5 } | Should -Throw
#     }
# }

Describe "Wait-ForIdentityPoolUnlock" {
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    It "Should wait until the identity pool is unlocked within the timeout" {
        $IdentityPool = [PSCustomObject]@{ Lock = $true }

        Mock Start-Sleep { $IdentityPool.Lock = $false }

        { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 2 -AdminAddress 'test-admin-address'} | Should -Not -Throw
    }

    It "Should timeout if the identity pool remains locked" {
        $IdentityPool = [PSCustomObject]@{ Lock = $true }

        Mock Start-Sleep {}

        { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 2 -AdminAddress 'test-admin-address' } | Should -Throw
    }

    It "Should not wait if the identity pool is not locked" {
        $IdentityPool = [PSCustomObject]@{ Lock = $false }

        Mock Start-Sleep {}

        { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 2 -AdminAddress 'test-admin-address' } | Should -Not -Throw

        Should -Invoke Start-Sleep -Exactly 0
    }
}
