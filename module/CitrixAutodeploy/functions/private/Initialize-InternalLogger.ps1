if (@(1, '1', $true, 'true') -contains $env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_ENABLED) {
    Write-VerboseLog -Message '$env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_ENABLED is set. Initializing internal logger'

    $OutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff} {Level:u3}] [InternalLogger] {Message:lj}{NewLine}{Exception}'
    $InternalLoggerConfig = New-Logger |
        Add-SinkConsole -OutputTemplate $OutputTemplate |
        Set-MinimumLevel -Value 'Verbose' -ToPreference

    if ($env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_FILE) {
        Write-VerboseLog -Message '$env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_FILE is set. Adding file sink to internal logger: {CITRIX_AUTODEPLOY_INTERNAL_LOGGER_FILE}' -PropertyValues $env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_FILE
        $InternalLoggerConfig = $InternalLoggerConfig | Add-SinkFile -Path $env:CITRIX_AUTODEPLOY_INTERNAL_LOGGER_FILE -OutputTemplate $OutputTemplate
    }

    $InternalLogger = Start-Logger -LoggerConfig $InternalLoggerConfig -PassThru

    Write-VerboseLog -Message 'Internal logger initialized' -Logger $InternalLogger
}
