Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Invoke-CtxAutodeployTask.ps1"
    }

    $TestCases = @(
        @{
            FilePath     = 'PreTask'
            Type         = 'Pre'
            ArgumentList = @()
        },
        @{
            FilePath     = 'PostTask'
            Type         = 'Post'
            ArgumentList = @()
        }
    )

    It 'Should execute <_.FilePath>' -TestCases $TestCases {
        param($FilePath, $Type, $ArgumentList)

        $ExpectedOutput = "A test ${Type} script was executed"
        $FilePath       = "${PSScriptRoot}\test_${FilePath}.ps1"
        Set-Content -Path $FilePath -Value "'${ExpectedOutput}'"

        $Params = @{
            FilePath     = $FilePath
            Context      = 'PreTaskTest'
            Type         = $Type
            ArgumentList = $ArgumentList
        }

        $ActualOutput = Invoke-CtxAutodeployTask @Params
        $ActualOutput | Should -Be $ExpectedOutput

        Remove-Item -Path $FilePath -Force
    }
}
