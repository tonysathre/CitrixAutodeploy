[CmdletBinding()]
param ()

Describe 'Get-PathType' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\private\Get-PathType.ps1"
    }

    Context 'Valid HTTP/S URLs' {
        It "Should return 'Uri' for an HTTP URL" {
            $Result = Get-PathType -Path 'http://example.com'
            $Result | Should -Be 'Uri'
        }

        It "Should return 'Uri' for an HTTPS URL" {
            $Result = Get-PathType -Path 'https://example.com'
            $Result | Should -Be 'Uri'
        }

        It "Should return 'Uri' for an HTTPS URL with query parameters" {
            $Result = Get-PathType -Path 'https://example.com?param=value'
            $Result | Should -Be 'Uri'
        }

        It "Should return 'Uri' for an HTTPS URL with port number" {
            $Result = Get-PathType -Path 'https://example.com:8080'
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

        It "Should return 'Unknown' for a directory path" {
            $Result = Get-PathType -Path "$PSScriptRoot"
            $Result | Should -Be 'Unknown'
        }
    }
}
