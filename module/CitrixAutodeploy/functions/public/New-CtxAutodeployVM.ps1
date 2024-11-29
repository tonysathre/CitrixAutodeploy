function New-CtxAutodeployVM {
    [CmdletBinding()]
    [OutputType([Citrix.Broker.Admin.SDK.Machine])]
    param(
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$BrokerCatalog,

        [Parameter(Mandatory)]
        [PSCustomObject]$DesktopGroup,

        [Parameter(Mandatory)]
        [PSCustomObject]$Logging,

        [Parameter()]
        [int]$Timeout = 60
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)
    Write-VerboseLog -Message "Broker catalog properties: {BrokerCatalog}" -PropertyValues ($BrokerCatalog | Out-String)
    Write-VerboseLog -Message "Desktop group properties: {DesktopGroup}" -PropertyValues ($DesktopGroup | Out-String)

    try {
        $ProvisioningScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name
        Write-VerboseLog -Message "Provisioning scheme properties: {ProvisioningSchemeName}" -PropertyValues ($ProvisioningScheme | Out-String)

        $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $BrokerCatalog.Name
        Write-VerboseLog -Message "Identity pool properties: {IdentityPool}" -PropertyValues ($IdentityPool | Out-String)

        # TODO(tsathre): Do we need to wait? Can we just unlock it, or continue anyway?
        if ($IdentityPool.Lock -eq $true) {
            Write-InfoLog -Message "Identity pool {IdentityPoolName} is locked. Waiting {Timeout} seconds for it to unlock" -PropertyValues $IdentityPool.IdentityPoolName, $Timeout
            Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout $Timeout -AdminAddress $AdminAddress
        }

        # TODO(tsathre): Do we need this?
        #Set-AcctIdentityPool -AdminAddress $AdminAddress -AllowUnicode -Domain $IdentityPool.Domain -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id

        Write-InfoLog -Message "Creating AD account in identity pool {IdentityPool}" -PropertyValues $IdentityPool.IdentityPoolName
        $NewAdAccount = New-AcctADAccount -AdminAddress $AdminAddress -Count 1 -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id
        Write-InfoLog -Message "AD account created successfully: {SuccessfulAccounts}" -PropertyValues ($NewAdAccount.SuccessfulAccounts | Out-String)
        $MachineName = $NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$')

        Write-InfoLog -Message "Creating machine {MachineName} using provisioning scheme {ProvisioningSchemeName}" -PropertyValues $MachineName, $ProvisioningScheme.ProvisioningSchemeName
        $ProvisioningTaskId = New-ProvVM -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts -ProvisioningSchemeName $ProvisioningScheme.ProvisioningSchemeName -RunAsynchronously -LoggingId $Logging.Id
        $ProvisioningTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvisioningTaskId

        while ($ProvisioningTask.Active) {
            Start-Sleep -Seconds 1
            $ProvisioningTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvisioningTaskId
        }

        Write-InfoLog -Message "Adding machine {MachineName} to catalog {BrokerCatalog}" -PropertyValues $MachineName, $BrokerCatalog.Name
        $NewBrokerMachine = New-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountSid -CatalogUid $BrokerCatalog.Uid -LoggingId $Logging.Id
        Write-InfoLog -Message "{MachineName} added to catalog {BrokerCatalog} successfully" -PropertyValues $MachineName, $BrokerCatalog.Name
        Write-VerboseLog -Message "New machine properties: {NewBrokerMachine}" -PropertyValues ($NewBrokerMachine | Out-String)

        Write-InfoLog -Message "Adding machine {MachineName} in catalog {BrokerCatalog} to desktop group {DesktopGroup}" -PropertyValues $NewBrokerMachine.MachineName, $BrokerCatalog.Name, $DesktopGroup.Name
        Add-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewBrokerMachine.MachineName -DesktopGroup $DesktopGroup.Name -LoggingId $Logging.Id

        Write-InfoLog -Message "Machine {MachineName} created successfully" -PropertyValues $MachineName

        return $NewBrokerMachine
    }
    catch {
        Write-ErrorLog -Message "Failed to create machine in catalog {BrokerCatalog}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $BrokerCatalog.Name

        <# TODO(tsathre): Will implement later

            if ($ProvisioningTask.TerminatingError -ne '') {
            Write-ErrorLog -Message "Machine provisioning task failed: {TerminatingError}" -PropertyValues $ProvisioningTask.TerminatingError
            Write-InfoLog -Message "Attempting to roll back changes"
            $ProvVM = Get-ProvVM -AdminAddress $AdminAddress -Filter { VMName -eq $MachineName }

            if ($ProvVM -and $ProvVM.Lock) {
                Write-InfoLog -Message "Machine is locked, unlocking {MachineName} unlocked" -PropertyValues $MachineName
                $ProvVM | Unlock-ProvVM -AdminAddress $AdminAddress -LoggingId $Logging.Id
            }

            Write-InfoLog -Message "Removing machine from provisioning database: {MachineName}" -PropertyValues $MachineName
            $ProvVM | Remove-ProvVM -AdminAddress $AdminAddress -ForgetVM

            Write-InfoLog -Message "Removing AD account {NewAdAccount.SuccessfulAccounts.ADAccountName} from identity pool {IdentityPool}" -PropertyValues $NewAdAccount.SuccessfulAccounts.ADAccountName, $IdentityPool.IdentityPoolName
            if ($NewAdAccount.SuccessfulAccounts) {
                $NewAdAccount.SuccessfulAccounts | Remove-AcctADAccount -AdminAddress $AdminAddress -IdentityPoolName $IdentityPool.IdentityPoolName
            }
        }
        #>
        throw
    }
}
