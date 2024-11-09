Describe 'Get-CtxAutodeployConfig' {
    BeforeAll {
        #Import-Module ${PSScriptRoot}\Pester.Helper.psm1
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Initialize-CtxAutodeployEnv.ps1"
        Mock Write-InfoLog {}
        Mock Write-DebugLog {}
        Mock Write-ErrorLog {}
        Mock Write-WarningLog {}
        Mock Write-VerboseLog {}
    }

    Context 'When the configuration file exists' {
        It 'Should return a configuration object' {
            $FilePath = "${PSScriptRoot}/test_config.json"
            $Config = Get-CtxAutodeployConfig -FilePath $FilePath
            $Config | Should -Not -BeNullOrEmpty
            $Config.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'
        }
    }

    Context 'When the configuration file does not exist' {
        It 'Should throw an error' {
            $FilePath = "${PSScriptRoot}/non_existent_config.json"
            { Get-CtxAutodeployConfig -FilePath $FilePath } | Should -Throw
        }
    }

    Context 'When the configuration file is invalid JSON' {
        It 'Should throw an error' {
            $InvalidJson = @'
{
    "AutodeployMonitors": {
        "AutodeployMonitor": [
            {
                "AdminAddress": "test-admin-address",
                "BrokerCatalog": "test-broker-catalog",
                "DesktopGroupName": "test-desktop-group-name",
        }
    }
}
'@ | Set-Content -Path "${PSScriptRoot}/invalid_config.json"
            $FilePath = "${PSScriptRoot}/invalid_config.json"
            { Get-CtxAutodeployConfig -FilePath $FilePath } | Should -Throw
        }

        AfterAll {
            Remove-Item "${PSScriptRoot}/invalid_config.json"
        }
    }

    Context 'When no FilePath is provided and environment variable is set' {
        It 'Should use the environment variable for the file path' {
            $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"
            $Config = Get-CtxAutodeployConfig
            $Config | Should -Not -BeNullOrEmpty
            $Config.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'
        }
    }

    Context 'When no FilePath is provided and environment variable is not set' {
        It 'Should throw an error' {
            $env:CITRIX_AUTODEPLOY_CONFIG = $null
            { Get-CtxAutodeployConfig } | Should -Throw
        }
    }
}