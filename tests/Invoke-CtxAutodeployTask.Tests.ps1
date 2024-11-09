Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Invoke-CtxAutodeployTask.ps1"
        Mock Write-InfoLog {}
        Mock Write-DebugLog {}
        Mock Write-ErrorLog {}
        Mock Write-WarningLog {}
        Mock Write-VerboseLog {}
    }

    $TestCases = @(
        @{
            FilePath     = 'PreTask'
            Type = 'Pre'
            ArgumentList = @()
        },
        @{
            FilePath     = 'PostTask'
            Type = 'Post'
            ArgumentList = @()
        }
    )

    It 'Should execute <_.Task>' -TestCases $TestCases {
        param($FilePath, $Type, $ArgumentList)

        $ExpectedOutput = "A test ${Type} script was executed"
        $FilePath           = "${PSScriptRoot}\test_${Type}.ps1"

        $Params = @{
            Task    = $Task
            Context = 'PreTaskTest'
            Type    = $Type
            ArgumentList = $ArgumentList
        }

        Set-Content -Path $Task -Value "'${ExpectedOutput}'"

        $ActualOutput = Invoke-CtxAutodeployTask @Params
        $ActualOutput | Should -Be $ExpectedOutput
    }
}
