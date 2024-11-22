function Stop-CtxHighLevelLogger {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [guid]$HighLevelOperationId,

        [Parameter(Mandatory)]
        [bool]$IsSuccessful
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    try {
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $HighLevelOperationId -EndTime ([datetime]::Now) -IsSuccessful $IsSuccessful
    }
    catch {
        Write-FatalLog -Message 'An error occurred stopping the Citrix high-level logger:' -Exception $_.Exception -ErrorRecord $_
        throw
    }

    Write-DebugLog -Message 'High-level logging operation with Id: {Logging} stopped' -PropertyValues $HighLevelOperationId
}
