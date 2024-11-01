function Test-MachineCountExceedsLimit {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory)]
        [int]$MaxMachines,

        [Parameter()]
        $MaxRecordCount = 1000000
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    $Params = @{
        AdminAddress   = $AdminAddress
        MaxRecordCount = $MaxRecordCount
    }

    if ($InputObject -is [Citrix.Broker.Admin.SDK.Catalog]) {
        $Params.Add('CatalogName', $InputObject.Name)
    } elseif ($InputObject -is [Citrix.Broker.Admin.SDK.DesktopGroup]) {
        $Params.Add('DesktopGroupName', $InputObject.Name)
    } else {
        Write-ErrorLog -Message "Input object is not a valid type. Expected InputObject to be of type [Citrix.Broker.Admin.SDK.Catalog] or [Citrix.Broker.Admin.SDK.DesktopGroup]. Got {InputObject}" -PropertyValues $InputObject.GetType().FullName
        throw
    }

    try {
        $Machines = Get-BrokerMachine @Params
    }
    catch {
        Write-ErrorLog -Message "Failed getting machines from delivery controller {AdminAddress}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AdminAddress
        throw
    }

    if ($Machines.Count -ge $MaxMachines) {
        return $true
    } else {
        return $false
    }
}
