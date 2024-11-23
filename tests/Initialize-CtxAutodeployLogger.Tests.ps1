[CmdletBinding()]
param ()

Describe 'Initialize-CtxAutodeployLogger' {
    BeforeDiscovery {
        $global:VerbosePreference = 'SilentlyContinue'
        $global:DebugPreference   = 'SilentlyContinue'
    }

    BeforeAll {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\public\Initialize-CtxAutodeployLogger.ps1"
        Import-Module ${PSScriptRoot}\Pester.Helper.psm1 -Force -ErrorAction Stop 3> $null
        Import-CitrixAutodeployModule
    }

    BeforeEach {
        $PreferenceVars = @(
            (Get-Variable 'VerbosePreference')
            (Get-Variable 'DebugPreference')
        )
    }

    AfterEach {
        $script:Logger | Close-Logger
    }

    It 'Should return an object of type Serilog.Core.Logger' {
        $script:Logger, $LoggerConfig = Initialize-CtxAutodeployLogger
        $Logger | Should -BeOfType 'Serilog.Core.Logger'
    }

    It 'Should set the LogLevel to Debug' {
        $script:Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -LogLevel 'Debug'
        Write-Host ([Serilog.Configuration.LoggerSettingsConfiguration].GetProperties($LoggerConfig))

        $LogLevel = $LoggerConfig.MinimumLevel.ControlledSwitch.MinimumLevel.ToString()
        $LogLevel | Should -Be 'Debug'
    } -Skip

    It 'Should add a file sink to the logger' {
        $TempFile = New-TempFile
        $Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -LogFile $TempFile
        $Logger | Should -BeOfType 'Serilog.Core.Logger'

        # Verify file sink
        #$LoggerConfig = [Serilog.Core.Logger]::GetType().GetProperty('Configuration', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).GetValue($Logger, $null)
        $FileSink = $LoggerConfig.WriteTo.Sinks | Where-Object { $_.GetType().Name -eq 'FileSink' }
        $FileSink | Should -Not -BeNullOrEmpty
        $FileSink.Path | Should -Be $TempFile.FullName

        Remove-Item -Path $TempFile
    } -Skip

    It 'Should set the custom output template' {
        $CustomTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] {Message:lj}{NewLine}{Exception}'
        $Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -LogOutputTemplate $CustomTemplate
        $Logger | Should -BeOfType 'Serilog.Core.Logger'

        # Verify output template
        #$LoggerConfig = [Serilog.Core.Logger]::GetType().GetProperty('Configuration', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).GetValue($Logger, $null)
        $ConsoleSink = $LoggerConfig.WriteTo.Sinks | Where-Object { $_.GetType().Name -eq 'ConsoleSink' }
        $ConsoleSink | Should -Not -BeNullOrEmpty
        $ConsoleSink.OutputTemplate | Should -Be $CustomTemplate
    } -Skip

    It 'Should add enrich with exception details' {
        $Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -AddEnrichWithExceptionDetails
        $Logger | Should -BeOfType 'Serilog.Core.Logger'

        # Verify enrich with exception details
        #$LoggerConfig = [Serilog.Core.Logger]::GetType().GetProperty('Configuration', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).GetValue($Logger, $null)
        $Enrichers = $LoggerConfig.Enrichers | Where-Object { $_.GetType().Name -eq 'ExceptionEnricher' }
        $Enrichers | Should -Not -BeNullOrEmpty
    } -Skip

    It 'Should set $DebugPreference to Continue' {
        $DebugPreference = 'SilentlyContinue'
        $Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -LogLevel 'Debug'
        $Logger | Should -BeOfType 'Serilog.Core.Logger'
        $DebugPreference | Should -Be 'Continue'
    } -Skip

    It 'Should set $VerbosePreference to Continue' {
        $VerbosePreference = 'SilentlyContinue'
        $Logger, $LoggerConfig = Initialize-CtxAutodeployLogger -LogLevel 'Verbose'
        $Logger | Should -BeOfType 'Serilog.Core.Logger'
        $VerbosePreference | Should -Be 'Continue'
    } -Skip
}
