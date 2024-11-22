function Start-CtxHighLevelLogger {
    [CmdletBinding()]
    [OutputType([Citrix.ConfigurationLogging.Sdk.HighLevelOperation])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [string]$Source = 'Citrix Autodeploy',

        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    try {
        $Logging = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source $Source -StartTime ([datetime]::Now) -Text $Text -OperationType AdminActivity
    }
    catch {
        Write-FatalLog -Message 'An error occurred starting the Citrix high-level logger:' -Exception $_.Exception -ErrorRecord $_
        throw
    }
    Write-DebugLog -Message "High-level logging operation started with Id: {Logging}" -PropertyValues $Logging.Id

    return $Logging
}
