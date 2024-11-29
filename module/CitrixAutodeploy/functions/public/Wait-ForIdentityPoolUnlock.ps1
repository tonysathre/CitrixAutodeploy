function Wait-ForIdentityPoolUnlock {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [Citrix.ADIdentity.Sdk.IdentityPool]$IdentityPool,

        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [int]$Timeout = 60
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    if (-not $IdentityPool.Lock) {
        Write-VerboseLog -Message 'Identity pool {IdentityPoolName} is not locked, returning.' -PropertyValues $IdentityPool.IdentityPoolName
        return
    }

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()

    while ($IdentityPool.Lock -and $Stopwatch.Elapsed.Seconds -lt $Timeout) {
        Write-VerboseLog -Message 'Identity pool {IdentityPoolName} is locked. Waiting {Timeout} seconds for it to unlock' -PropertyValues $IdentityPool.IdentityPoolName, $Timeout
        try {
            $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $IdentityPool.IdentityPoolName
            Start-Sleep -Seconds 1
        }
        catch {
            Write-ErrorLog 'An error occurred getting identity pool {IdentityPoolName} from delivery controller {AdminAddress}' -PropertyValues $IdentityPool.IdentityPoolName, $AdminAddress -Exception $_.Exception -ErrorRecord $_
            $Stopwatch.Stop()
            throw
        }
    }

    if ($IdentityPool.Lock) {
        Write-WarningLog 'Identity pool {IdentityPoolName} did not unlock within the specified Timeout period ({Timeout} seconds). Increase the Timeout or manually unlock the identity pool with Unlock-AcctIdentityPool.' -PropertyValues $IdentityPool.IdentityPoolName, $Timeout
        $Stopwatch.Stop()
        return
    }

    Write-VerboseLog -Message 'Identity pool {IdentityPoolName} unlocked after {ElapsedSeconds} seconds' -PropertyValues $IdentityPool.IdentityPoolName, $Stopwatch.Elapsed.Seconds
    $Stopwatch.Stop()
}
