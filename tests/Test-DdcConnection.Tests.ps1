Describe 'Test-DdcConnection' {
    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Test-DdcConnection.ps1"
    }

    $Protocols = @('http', 'https')

    Context 'When connection is successful' {
        It "Should return $true using protocol <_>" -ForEach $Protocols {
            Mock Invoke-RestMethod { return $true }
            $Result = Test-DdcConnection -AdminAddress 'test-admin-address' -Protocol $_
            $Result | Should -Be $true
        }
    }

    Context 'When connection fails' {
        It 'Should return $false using protocol <_>' -ForEach $Protocols {
            Mock Invoke-RestMethod { return $false }

            $Result = Test-DdcConnection -AdminAddress 'test-admin-address' -Protocol 'https'
            $Result | Should -Be $false
        }
    }
}
