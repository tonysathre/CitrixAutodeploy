[CmdletBinding()]
param ()

Describe 'Get-CtxAutodeployConfig' {
    BeforeAll {
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop 3> $null 4> $null
        Import-CitrixAutodeployModule -Scope Global
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Get-CtxAutodeployConfig.ps1"
    }

    BeforeEach {
        $script:FilePath = "${PSScriptRoot}\temp_config.json"
        @'
{
    "AutodeployMonitors": {
        "AutodeployMonitor": [
            {
                "AdminAddress": "test-admin-address",
                "BrokerCatalog": "TestCatalog1",
                "DesktopGroupName": "TestGroup1",
                "MinAvailableMachines": 2,
                "PreTask": "",
                "PostTask": ""
            }
        ]
    }
}
'@ | Set-Content -Path $FilePath
    }

    Context 'Valid Config File' {
        It 'Should return expected configuration object when a valid file is provided' {
            $Result = Get-CtxAutodeployConfig -Path $FilePath
            $Result | Should -BeOfType [PSCustomObject]
            $Result.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'
        }
    }

    Context 'Config File Set via $env:CITRIX_AUTODEPLOY_CONFIG' {
        It 'Should return expected configuration object when a valid file path is set via environment variable' {
            $env:CITRIX_AUTODEPLOY_CONFIG = $FilePath

            $Result = Get-CtxAutodeployConfig
            $Result | Should -BeOfType [PSCustomObject]
            $Result.AutodeployMonitors.AutodeployMonitor[0].AdminAddress | Should -Be 'test-admin-address'
        }
    }

    Context 'Invalid File Path' {
        It 'Should throw an [PathNotFound] exception when file does not exist' {
            { Get-CtxAutodeployConfig -Path "${PSScriptRoot}\non_existent_config.json" } | Should -Throw -ErrorId 'PathNotFound,Microsoft.PowerShell.Commands.GetContentCommand' -ExpectedMessage 'Cannot find path*'
        }
    }

    Context 'Unsupported File Format' {
        It 'Should throw an error when an unsupported file format is used' {
            Set-Content -Path $FilePath -Value 'Invalid Content'

            { Get-CtxAutodeployConfig -Path $FilePath } | Should -Throw -ErrorId 'System.ArgumentException,Microsoft.PowerShell.Commands.ConvertFromJsonCommand' -ExpectedMessage 'Invalid JSON primitive: Invalid.'

            Remove-Item -Path $FilePath -Force
        }
    }

    Context 'Download Config Over <_>' -ForEach 'HTTP', 'HTTPS' {
        It 'Should successfully download and parse a valid JSON config from an <_> URL' {
            $Uri = "{0}://example.com/config.json" -f $_

            Mock Invoke-WebRequest {
                return [PSCustomObject]@{
                    StatusCode            = 200
                    StatusCodeDescription = 'OK'
                    Content               = '{ "Key": "Value" }'
                }
            } -ModuleName CitrixAutodeploy

            $Result = Get-CtxAutodeployConfig -Path $Uri

            $Result | Should -BeOfType [PSCustomObject]
            $Result.Key | Should -Be 'Value'
        }
    }

    Context 'Invalid JSON Format' {
        It 'Should throw an [System.ArgumentException] exception for invalid JSON format' {
            Set-Content -Path $FilePath -Value '{Invalid:Json}'

            { Get-CtxAutodeployConfig -Path $FilePath } | Should -Throw -ErrorId 'System.ArgumentException,Microsoft.PowerShell.Commands.ConvertFromJsonCommand' -ExpectedMessage 'Invalid JSON primitive: Json.'

            Remove-Item -Path $FilePath -Force
        }
    }

    Context 'Empty Config File' {
        It 'Should throw an error when the file is exists, but is empty' {
            Set-Content -Path $FilePath -Value $null

            { Get-CtxAutodeployConfig -Path $FilePath } | Should -Throw -ExpectedMessage 'The configuration file is empty*'

            Remove-Item -Path $FilePath -Force
        }
    }
}
