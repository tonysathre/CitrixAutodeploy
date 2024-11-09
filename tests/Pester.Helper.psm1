function Mock-LoggingFunctions {
    Mock Write-InfoLog    {}
    Mock Write-DebugLog   {}
    Mock Write-ErrorLog   {}
    Mock Write-WarningLog {}
    Mock Write-VerboseLog {}
}

function Import-CitrixAutodeployModule {
    Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
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
    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.Machine]) -Properties @{
        MachineName       = 'DOMAIN\MockMachine'
        HostedMachineName = 'MockMachine'
        Uid               = [guid]::NewGuid()
    }
}

function New-MockCtxHighLevelLogger {
    return New-MockObject -Type ([Citrix.ConfigurationLogging.Sdk.HighLevelOperation]) -Properties @{
        Id = [guid]::NewGuid()
    }
}

function Get-RandomComputerName {
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

    $Name = Get-RandomComputerName

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

function Get-MockProvTask {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Finished', 'Running')]
        [string]$Status
    )

    return @{
        TaskId = [guid]::NewGuid()
        Status  = $Status
    }
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

    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.ADIdentity.Sdk.IdentityInPool]) -Properties @{
        AccountName      = $ADAccount.SamAccountName
        IdentityPoolName = 'MockIdentityPool'
        ADAccountSid     = $ADAccount.SID
        Lock             = $Lock
    }
}

function New-MockProvScheme {
    return New-MockObject -Type ([Citrix.MachineCreation.Sdk.ProvisioningScheme]) @{
        ProvisioningSchemeName = 'MockProvScheme'
    }
}

function Add-MockBrokerMachine {
    Mock Add-BrokerMachine {}
}
