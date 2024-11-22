Describe 'Main Script Execution' {
    BeforeAll {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop 3> $null
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null
        Initialize-CtxAutodeployEnv
    }

    BeforeEach {
        Set-Logging
        Mock Get-BrokerDesktopGroup      { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerCatalog           { return Get-BrokerCatalogMock }
        Mock Get-BrokerMachine           { return Get-BrokerMachineMock }
        Mock Initialize-CtxAutodeployEnv

        $Params = @{
            LogLevel = 'None'
            FilePath = "${PSScriptRoot}\test_config.json"
        }
    }

    AfterAll {

    }

    It 'Should initialize the environment' {
        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw
        Should -Invoke Initialize-CtxAutodeployEnv -Exactly 1 -Scope It
    }

    It 'Should execute main script logic' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock }
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }

    It 'Should only add machines when needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock }
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 0 -Scope It
    }

    It 'Should loop when multiple machines are needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock }
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }

    It 'Should log and handle errors' {
        $ConfigFilePath = "${PSScriptRoot}\test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock }
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 1 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 0 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 0 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 0 -Scope It
    }

    It 'Should continue processing if error occurs in New-CtxAutodeployVM' {
        $ConfigFilePath = "${PSScriptRoot}\test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock }
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock }
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock }
        Mock New-CtxAutodeployVM    { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It
    }
}