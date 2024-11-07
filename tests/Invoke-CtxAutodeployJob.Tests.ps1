Describe 'Invoke-CtxAutodeployJob' {
    BeforeAll {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    BeforeEach {
        Mock Write-InfoLog    {}
        Mock Write-DebugLog   {}
        Mock Write-ErrorLog   {}
        Mock Write-WarningLog {}
        Mock Write-VerboseLog {}
    }

    It 'Should initialize the environment' {
        Mock Initialize-CtxAutodeployEnv
        Mock Get-CtxAutodeployConfig { return @{ AutodeployMonitors = @{ AutodeployMonitor = @() } } }
        Mock Test-DdcConnection { return $true }
        Mock Get-BrokerCatalog { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { Invoke-CtxAutodeployJob -FilePath "${PSScriptRoot}/test_config.json" } | Should -Not -Throw

        Should -Invoke Initialize-CtxAutodeployEnv -Exactly 1 -Scope It
    }

    It 'Should read the configuration' {
        Mock Get-CtxAutodeployConfig { return @{ AutodeployMonitors = @{ AutodeployMonitor = @() } } }

        { Invoke-CtxAutodeployJob -FilePath "${PSScriptRoot}/test_config.json" } | Should -Not -Throw

        Should -Invoke Get-CtxAutodeployConfig -Exactly 1 -Scope It
    }

    It 'Should process each AutodeployMonitor' {
        $Config = @{
            AutodeployMonitors = @{
                AutodeployMonitor = @(
                    @{
                        AdminAddress = 'test-admin-address'
                        BrokerCatalog = 'TestCatalog1'
                        DesktopGroupName = 'TestGroup1'
                        MinAvailableMachines = 2
                    },
                    @{
                        AdminAddress = 'test-admin-address'
                        BrokerCatalog = 'TestCatalog2'
                        DesktopGroupName = 'TestGroup2'
                        MinAvailableMachines = 2
                    }
                )
            }
        }

        Mock Get-CtxAutodeployConfig { return $Config }
        Mock Test-DdcConnection { return $true }
        Mock Get-BrokerCatalog { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { Invoke-CtxAutodeployJob -FilePath "${PSScriptRoot}/test_config.json" } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM -Exactly 4 -Scope It
    }

    It 'Should log and handle errors' {
        Mock Get-CtxAutodeployConfig { return @{ AutodeployMonitors = @{ AutodeployMonitor = @() } } }
        Mock Test-DdcConnection { throw "Test error" }

        { Invoke-CtxAutodeployJob -FilePath "${PSScriptRoot}/test_config.json" } | Should -Throw

        Should -Invoke Test-DdcConnection -Exactly 1 -Scope It
        Should -Invoke Write-ErrorLog -Exactly 1 -Scope It
    }
}
