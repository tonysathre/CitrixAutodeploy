[CmdletBinding()]
param ()

Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Invoke-CtxAutodeployTask.ps1"
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop 3> $null 4> $null
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

    It 'Should execute <_.Type> task script successfully' -ForEach $TestCases {
        $ExpectedOutput = "A test ${Type} script was executed"
        Set-Content -Path $FilePath -Value "'$ExpectedOutput'"

        $ActualOutput = Invoke-CtxAutodeployTask @_
        $ActualOutput | Should -Be $ExpectedOutput
    }

    It 'ArgumentList properties should be accessible in <_.Type> task script' -ForEach $TestCases {
        $ExpectedOutput = '{0}' -f $ArgumentList.Property1
        Set-Content -Path $FilePath -Value "'$ExpectedOutput'"

        $ActualOutput = Invoke-CtxAutodeployTask @_
        $ActualOutput | Should -Be $ArgumentList.Property1
    }

    Context 'When an error occurs in a <_.Type> task script' -ForEach $TestCases {
        It 'Should throw an exception' {
            $InvalidCommand = 'Non-ExistentCmdlet'
            Set-Content -Path $FilePath -Value $InvalidCommand

            { Invoke-CtxAutodeployTask @_ } | Should -Throw -ErrorId CommandNotFoundException -ExpectedMessage "The term '${InvalidCommand}' is not recognized as the name of a cmdlet*"
        }

        It 'Should log an error' {
            $InvalidCommand = 'Non-ExistentCmdlet'
            Set-Content -Path $FilePath -Value $InvalidCommand

            { Invoke-CtxAutodeployTask @_ } | Should -Throw -ErrorId CommandNotFoundException -ExpectedMessage "The term '${InvalidCommand}' is not recognized as the name of a cmdlet*"
        }
    }
}
