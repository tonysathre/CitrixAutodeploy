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

    # TODO(tsathre): Come up with a better test name
    It 'ArgumentList should contain stuff' -ForEach $TestCases {
        param($FilePath, $Type, $ArgumentList)

    }
}
