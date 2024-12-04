[CmdletBinding()]
param ()

Describe 'Get-PathType' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\private\Get-PathType.ps1"
    }

    Context 'Valid <_> URLs' -ForEach 'HTTP', 'HTTPS' {
        It "Should return 'Uri' for an <_> URL" {
            $Result = Get-PathType -Path ('{0}://example.com' -f $_)
            $Result | Should -Be 'Uri'
        }

        It "Should return 'Uri' for an <_> URL with query parameters" {
            $Result = Get-PathType -Path ('{0}://example.com?param=value' -f $_)
            $Result | Should -Be 'Uri'
        }

        It "Should return 'Uri' for an <_> URL with port number" {
            $Result = Get-PathType -Path ('{0}://example.com:8080' -f $_)
            $Result | Should -Be 'Uri'
        }
    }

    Context 'Valid Local File Paths' {
        BeforeAll {
            New-Item -Path "$PSScriptRoot\TestFile1.txt" -ItemType File -Force | Out-Null
            New-Item -Path "$PSScriptRoot\TestFile2.json" -ItemType File -Force | Out-Null
        }

        AfterAll {
            Remove-Item -Path "$PSScriptRoot\TestFile1.txt", "$PSScriptRoot\TestFile2.json" -Force
        }

        It "Should return 'LocalFile' for a valid local file path" {
            $Result = Get-PathType -Path "$PSScriptRoot\TestFile1.txt"
            $Result | Should -Be 'LocalFile'
        }

        It "Should return 'LocalFile' for another valid local file path" {
            $Result = Get-PathType -Path "$PSScriptRoot\TestFile2.json"
            $Result | Should -Be 'LocalFile'
        }

        It "Should return 'LocalFile' for a non-existent file path" {
            $Result = Get-PathType -Path "$PSScriptRoot\NonExistentFile.txt"
            $Result | Should -Be 'LocalFile'
        }
    }

    Context 'Valid Directory Paths' {
        It "Should return 'Directory' for a valid directory path" {
            $Result = Get-PathType -Path "$PSScriptRoot"
            $Result | Should -Be 'Directory'
        }

        It "Should return 'Directory' for another valid directory path" {
            $Result = Get-PathType -Path "$env:TEMP"
            $Result | Should -Be 'Directory'
        }
    }

    Context 'Invalid Paths' {
        It "Should return 'Unknown' for a random string" {
            $Result = Get-PathType -Path 'randomstring'
            $Result | Should -Be 'Unknown'
        }

        It "Should return 'Unknown' for a malformed URL" {
            $Result = Get-PathType -Path 'htp:/malformed-url'
            $Result | Should -Be 'Unknown'
        }

        It 'Should throw an [ParameterArgumentValidationError] exception for an empty string' {
            { Get-PathType -Path '' } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Get-PathType' -ExceptionType ([System.Exception]) -ExpectedMessage "*The argument is null or empty*"
        }

        It 'Should throw an exception for a file path with invalid characters' {
            { Get-PathType -Path 'C:\Invalid|Path.txt' } | Should -Throw -ExpectedMessage "The provided file path contains invalid characters*"
        }
    }

    Context 'Edge Cases' {
        It "Should return 'Uri' for a URL with a long query string" {
            $LongUrl = 'https://example.com?' + ('param=value&' * 100)
            $Result = Get-PathType -Path $LongUrl
            $Result | Should -Be 'Uri'
        }
    }
}
