function Import-CitrixAutodeployModule {
    Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
}

function New-MockAdminAddress {
    return 'test-admin-address'
}
function New-MockBrokerCatalog {
    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.Catalog]) -Properties @{
        Name        = 'MockBrokerCatalog'
        CatalogName = 'MockBrokerCatalog'
        Uid         = 123
    }
}

function New-MockDesktopGroup {
    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.DesktopGroup]) -Properties @{
        Name             = 'MockDesktopGroup'
        DesktopGroupName = 'MockDesktopGroup'
        Uid              = 123
    }
}

function New-MockBrokerMachine {
    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.Machine]) -Properties @{
        MachineName       = $ADAccount.Name
        HostedMachineName = $ADAccount.Name
        Uid               = [guid]::NewGuid()
    }
}

function New-MockCtxHighLevelLogger {
    return New-MockObject -Type ([Citrix.ConfigurationLogging.Sdk.HighLevelOperation]) -Properties @{
        Id = [guid]::NewGuid()
    }
}

function New-RandomComputerName {
    param (
        [Parameter()]
        [int]$Length = 8
    )

    $Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $ComputerName = -join ((1..$Length) | ForEach-Object { $Chars[(Get-Random -Maximum $Chars.Length)] })

    return "PESTER-${ComputerName}"
}

function New-MockADComputer {
    $SidBytes = New-Object byte[] 28
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($SidBytes)
    $SidBytes[0] = 1  # Set the revision number to 1
    $SidBytes[1] = 0  # Set the number of sub-authorities to 0
    $Sid = New-Object System.Security.Principal.SecurityIdentifier($SidBytes, 0)

    $Name = 'PESTER-123456'

    return @{
        Name           = $Name
        SID            = $Sid.Value
        SamAccountName = "${Name}$"
    }
}

function New-MockProvVM {
    param (
        [Parameter()]
        [string]$Lock = $false
    )

    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.MachineCreation.Sdk.ProvisionedVirtualMachine]) -Properties @{
        ADAccountName          = $ADAccount.SamAccountName
        ADAccountSid           = $ADAccount.SID
        ProvisioningSchemeName = (New-MockProvScheme).ProvisioningSchemeName
        VMName                 = $ADAccount.Name
        Uid                    = 123
        Lock                   = $Lock
    }
}

function Get-MockProvVM {
    param (
        [Parameter()]
        [string]$Lock = $false
    )

    return New-MockProvVM @PSBoundParameters

}

function New-MockProvTask {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Finished', 'Running')]
        [string]$Status,

        [Parameter()]
        [string]$TerminatingError = $null,

        [Parameter()]
        [bool]$Active = $false
    )

    return @{
        Active           = $Active
        TaskId           = [guid]::NewGuid()
        Status           = $Status
        TerminatingError = $TerminatingError
    }
}

function Get-MockProvTask {
    return [guid]::NewGuid()
}

function Unlock-MockProvVM {
    Mock Unlock-ProvVM {}
}

function Remove-MockProvVM {
    Mock Remove-ProvVM {}
}

function Remove-MockAcctADAccount {
    Mock Remove-AcctADAccount {}
}

function Get-MockAcctIdentityPool {
    param (
        [Parameter()]
        [string]$Lock = $false
    )

    return [PSCustomObject]@{
        IdentityPoolName = 'MockIdentityPool'
        Lock             = $Lock
    }
}

function New-MockAcctADAccount {
    param (
        [Parameter()]
        [string]$Lock = $false
    )

    $Domain = 'PESTER'
    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.ADIdentity.Sdk.AccountOperationDetailedSummary]) -Properties @{
        SuccessfulAccounts = @(
            @{
                ADAccountName    = "{0}\{1}" -f $Domain, $ADAccount.SamAccountName
                Domain           = $Domain
                IdentityPoolName = (Get-MockAcctIdentityPool).IdentityPoolName
                ADAccountSid     = $ADAccount.SID
                Lock             = $Lock
            }
        )
    }
}

function New-MockProvScheme {
    return New-MockObject -Type ([Citrix.MachineCreation.Sdk.ProvisioningScheme]) -Properties @{
        ProvisioningSchemeName = 'MockProvScheme'
    }
}

function Get-MockProvScheme {
    return New-MockProvScheme
}

function Add-MockBrokerMachine {
    return $null
}
