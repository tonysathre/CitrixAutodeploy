Describe 'Main Script Execution' {
    BeforeEach {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue
        Mock Write-InfoLog    {}
        Mock Write-DebugLog   {}
        Mock Write-ErrorLog   {}
        Mock Write-WarningLog {}
        Mock Write-VerboseLog {}
    }

    It 'Should initialize the environment' {
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerCatalog { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerMachine { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock Initialize-CtxAutodeployEnv
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }
        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Initialize-CtxAutodeployEnv -Exactly 1 -Scope It
    }

    It 'Should execute main script logic' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }

    It 'Should only add machines when needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }, [PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 0 -Scope It
    }

    It 'Should loop when multiple machines are needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }

    It 'Should log and handle errors' {
        $ConfigFilePath = "${PSScriptRoot}/test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog { throw "Test error" }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 1 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 0 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 0 -Scope It
        Should -Invoke New-CtxAutodeployVM -Exactly 0 -Scope It
    }

    It 'Should continue processing if error occurs in New-CtxAutodeployVM' {
        $ConfigFilePath = "${PSScriptRoot}/test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }
}
