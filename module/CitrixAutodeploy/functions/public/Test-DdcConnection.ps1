function Test-DdcConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [ValidateSet('http', 'https')]
        [string]$Protocol = 'https',

        [Parameter()]
        [string]$Endpoint = 'cvad/manage/HealthCheck'
    )

    # The cvad/manage/HealthCheck API is only available in CVAD 2308+ according to this document:
    # https://developer-docs.citrix.com/en-us/citrix-virtual-apps-desktops/citrix-cvad-rest-apis/citrix-virtual-apps-and-desktops-apis-release-notes#citrix-virtual-apps-and-desktops-7-2308

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    $Uri = "${Protocol}://${AdminAddress}/${Endpoint}"
    Write-DebugLog -Message 'Testing connection to delivery controller {Protocol}://{AdminAddress}/{Endpoint}' -PropertyValues $Protocol, $AdminAddress, $Endpoint

    try {
        return Invoke-RestMethod -Uri $Uri -Method Get -UseBasicParsing
    }
    catch {
        Write-WarningLog -Message 'Connection to delivery controller {Protocol}://{AdminAddress}/{Endpoint} failed' -PropertyValues $Protocol, $AdminAddress, $Endpoint
        return $false
    }
}
