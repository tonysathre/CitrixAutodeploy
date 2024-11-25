[CmdletBinding()]
param ()

Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Invoke-CtxAutodeployTask.ps1"
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop
    }

    AfterAll {
        "${PSScriptRoot}\test_PreTask.ps1", "${PSScriptRoot}\test_PostTask.ps1" | Remove-Item -Force
    }

    $TestCases = @(
        @{
            FilePath     = "${PSScriptRoot}\test_PreTask.ps1"
            Type         = 'Pre'
            Context      = 'PreTaskContext'
            ArgumentList = @(@{
                Property1 = 'One'
            })
        },
        @{
            FilePath     = "${PSScriptRoot}\test_PostTask.ps1"
            Type         = 'Post'
            Context      = 'PostTaskContext'
            ArgumentList = @(@{
                Property1 = 'One'
            })
        }
    )

    It 'Should execute <_.Type> task script' -ForEach $TestCases {
        param($FilePath, $Type, $Context, $ArgumentList)

        $ExpectedOutput = "A test ${Type} script was executed"
        Set-Content -Path $FilePath -Value "'$ExpectedOutput'"

        $ActualOutput = Invoke-CtxAutodeployTask @PSBoundParameters
        $ActualOutput | Should -Be $ExpectedOutput
    }

    It 'ArgumentList properties should be accessible in <_.Type> task script' -ForEach $TestCases {
        param($FilePath, $Type, $Context, $ArgumentList)

        $ExpectedOutput = '{0}' -f $ArgumentList.Property1
        Set-Content -Path $FilePath -Value "'$ExpectedOutput'"

        $ActualOutput = Invoke-CtxAutodeployTask @PSBoundParameters
        $ActualOutput | Should -Be $ArgumentList.Property1
    }
}
