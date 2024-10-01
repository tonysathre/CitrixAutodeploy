Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    $TestConfig = Get-CtxAutodeployConfig -FilePath ${PSScriptRoot}\test_config.json
    $TestCases = @(
        @{
            Task = 'PreTask'
            Type = 'Pre'
            ArgumentList = @(
                [PSCustomObject]@{
                    AutodeployMonitor = $TestConfig.AutodeployMonitors.AutodeployMonitor[0]
                    DesktopGroup      =  $TestConfig.AutodeployMonitors.AutodeployMonitor[0].DesktopGroupName
                    BrokerCatalog     = $TestConfig.AutodeployMonitors.AutodeployMonitor[0].BrokerCatalog
                }
            )
        },
        @{
            Task = 'PostTask'
            Type = 'Post'
            ArgumentList = [PSCustomObject]@{
                AutodeployMonitor = $TestConfig.AutodeployMonitors.AutodeployMonitor[0]
                DesktopGroup      = $TestConfig.AutodeployMonitors.AutodeployMonitor[0].DesktopGroupName
                BrokerCatalog     = $TestConfig.AutodeployMonitors.AutodeployMonitor[0].BrokerCatalog
            }
        }
    )

    It 'Should execute <_.Task>' -TestCases $TestCases {
        param($Task, $Type, $ArgumentList)

        $ExpectedOutput = "A test ${Task} script was executed"
        $Task           = "${PSScriptRoot}\test_${Name}.ps1"

        $Params = @{
            Task    = $Task
            Context = 'TestContext'
            Type    = $Type
            ArgumentList = $ArgumentList
        }

        Set-Content -Path $Task -Value "'${ExpectedOutput}'"

        $ActualOutput = Invoke-CtxAutodeployTask @Params
        $ActualOutput | Should -Be $ExpectedOutput
    }
}
