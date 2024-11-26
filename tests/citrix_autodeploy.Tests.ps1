[CmdletBinding()]
param ()

Describe 'Main Script Execution' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null 4> $null
        Import-CitrixAutodeployModule 3> $null 4> $null
    }

    BeforeEach {
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock } -ModuleName CitrixAutodeploy
        Mock Initialize-CtxAutodeployEnv {} -ModuleName CitrixAutodeploy

        $Params = @{
            LogLevel = 'None'
            FilePath = "${PSScriptRoot}\test_config.json"
        }
    }

    It 'Should initialize the environment' {
        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw
        Should -Invoke Initialize-CtxAutodeployEnv -Exactly 1 -Scope It -ModuleName CitrixAutodeploy
    }

    It 'Should execute main script logic' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It -ModuleName CitrixAutodeploy
    }

    It 'Should only add machines when needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock      } -ModuleName CitrixAutodeploy
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock      } -ModuleName CitrixAutodeploy
        Mock New-CtxAutodeployVM    { return New-BrokerMachineMock      } -ModuleName CitrixAutodeploy

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke New-CtxAutodeployVM    -Exactly 0 -Scope It -ModuleName CitrixAutodeploy
    }

    It 'Should loop when multiple machines are needed' {
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}\test_config.json"

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock      } -ModuleName CitrixAutodeploy
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock      } -ModuleName CitrixAutodeploy
        Mock New-CtxAutodeployVM    { return New-BrokerMachineMock      } -ModuleName CitrixAutodeploy

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Not -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It -ModuleName CitrixAutodeploy
    }

    It 'Should log and handle errors' {
        $ConfigFilePath = "${PSScriptRoot}\test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock      } -ModuleName CitrixAutodeploy
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock      } -ModuleName CitrixAutodeploy
        Mock New-CtxAutodeployVM    { return New-BrokerMachineMock      } -ModuleName CitrixAutodeploy

        { . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params } | Should -Throw

        Should -Invoke Get-BrokerCatalog      -Exactly 1 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerDesktopGroup -Exactly 0 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerMachine      -Exactly 0 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke New-CtxAutodeployVM    -Exactly 0 -Scope It -ModuleName CitrixAutodeploy
    }

    It 'Should continue processing if error occurs in New-CtxAutodeployVM' {
        $ConfigFilePath = "${PSScriptRoot}\test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return Get-BrokerCatalogMock      } -ModuleName CitrixAutodeploy
        Mock Get-BrokerDesktopGroup { return Get-BrokerDesktopGroupMock } -ModuleName CitrixAutodeploy
        Mock Get-BrokerMachine      { return Get-BrokerMachineMock      } -ModuleName CitrixAutodeploy
        Mock New-CtxAutodeployVM    { return New-BrokerMachineMock      } -ModuleName CitrixAutodeploy

        . "${PSScriptRoot}\..\citrix_autodeploy.ps1" @Params

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It -ModuleName CitrixAutodeploy
        Should -Invoke New-CtxAutodeployVM    -Exactly 4 -Scope It -ModuleName CitrixAutodeploy
    }
} -Skip