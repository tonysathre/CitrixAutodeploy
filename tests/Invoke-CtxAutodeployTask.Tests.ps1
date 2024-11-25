[CmdletBinding()]
param ()

Describe 'Invoke-CtxAutodeployTask' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Invoke-CtxAutodeployTask.ps1"
        Import-Module "${PSScriptRoot}\Pester.Helper.psm1" -Force -ErrorAction Stop
        Enable-Logging
    }

    AfterAll {
        if (-not $env:CI) {
            Remove-CitrixAutodeployModule
        }

        if ($VerbosePreference -eq 'Continue') {
            $global:VerbosePreference = 'SilentlyContinue'
            Close-Logger
        }

        if ($DebugPreference -eq 'Continue') {
            $global:DebugPreference = 'SilentlyContinue'
            Close-Logger
        }
    }

    $TestCases = @(
        @{
            FilePath     = "${PSScriptRoot}\test_PreTask.ps1"
            Type         = 'Pre'
            Context      = 'PreTaskContext'
            ArgumentList = @(@{
                    Property1 = 'One'
                    Property2 = 'Two'
            })
        },
        @{
            FilePath     = "${PSScriptRoot}\test_PostTask.ps1"
            Type         = 'Post'
            Context      = 'PostTaskContext'
            ArgumentList = @(@{
                Property1 = 'One'
                Property2 = 'Two'
            })
        }
    )

    It 'Should execute <_.Task>' -ForEach $TestCases {
        param($FilePath, $Type, $Context, $ArgumentList)

        $ExpectedOutput = "A test ${Type} script was executed"

        $ActualOutput = Invoke-CtxAutodeployTask @PSBoundParameters
        $ActualOutput | Should -Be $ExpectedOutput

        Remove-Item -Path $FilePath -Force
    }

    # TODO(tsathre): Come up with a better test name
    It 'ArgumentList should contain stuff' -ForEach $TestCases {
        param($FilePath, $Type, $ArgumentList)

    }

    # TODO(tsathre): Come up with a better test name
    It 'ArgumentList should contain stuff' -ForEach $TestCases {
        param($FilePath, $Type, $ArgumentList)

    }
}
