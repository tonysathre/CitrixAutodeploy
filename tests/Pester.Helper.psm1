function Import-CitrixPowerShellModules {
    [CmdletBinding()]
    param ()

    @(
        'Citrix.ADIdentity.Commands',
        'Citrix.Broker.Commands',
        'Citrix.ConfigurationLogging.Commands',
        'Citrix.MachineCreation.Commands'
    ) | Import-Module -Force -ErrorAction Stop
}

function Remove-CitrixPowerShellModules {
    [CmdletBinding()]
    param ()

    @(
        'Citrix.ADIdentity.Commands',
        'Citrix.Broker.Commands',
        'Citrix.ConfigurationLogging.Commands',
        'Citrix.MachineCreation.Commands'
    ) | Remove-Module -Force
}

function Import-CitrixAutodeployModule {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet('Global', 'Local')]
        [string]$Scope = 'Global'
    )

    Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Scope $Scope -Force -ErrorAction Stop
}

function Remove-CitrixAutodeployModule {
    [CmdletBinding()]
    param ()

    Get-Module CitrixAutodeploy | Remove-Module -Force
}

function New-MockAdminAddress {
    [CmdletBinding()]
    param ()

    return 'mock-admin-address'
}

function New-BrokerCatalogMock {
    [CmdletBinding()]
    param ()

    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.Catalog]) -Properties @{
        Name        = 'MockBrokerCatalog'
        CatalogName = 'MockBrokerCatalog'
        Uid         = 123
    }
}

function New-BrokerDesktopGroupMock {
    [CmdletBinding()]
    param ()

    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.DesktopGroup]) -Properties @{
        Name             = 'MockDesktopGroup'
        DesktopGroupName = 'MockDesktopGroup'
        Uid              = 123
    }
}

function New-BrokerMachineMock {
    [CmdletBinding()]
    param ()

    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.Broker.Admin.SDK.Machine]) -Properties @{
        MachineName       = $ADAccount.Name
        HostedMachineName = $ADAccount.Name
        Uid               = [guid]::NewGuid()
    }
}

function New-CtxHighLevelLoggerMock {
    [CmdletBinding()]
    param ()

    return New-MockObject -Type ([Citrix.ConfigurationLogging.Sdk.HighLevelOperation]) -Properties @{
        Id = [guid]::NewGuid()
    }
}

function New-RandomComputerName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [int]$Length = 8
    )

    $Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $ComputerName = -join ((1..$Length) | ForEach-Object { $Chars[(Get-Random -Maximum $Chars.Length)] })

    return "PESTER-${ComputerName}"
}

function New-MockADComputer {
    [CmdletBinding()]
    param ()

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

function New-ProvVMMock {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Lock = $false
    )

    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.MachineCreation.Sdk.ProvisionedVirtualMachine]) -Properties @{
        ADAccountName          = $ADAccount.SamAccountName
        ADAccountSid           = $ADAccount.SID
        ProvisioningSchemeName = (New-ProvSchemeMock).ProvisioningSchemeName
        VMName                 = $ADAccount.Name
        Uid                    = 123
        Lock                   = $Lock
    }
}

function Get-ProvVMMock {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Lock = $false
    )

    return New-ProvVMMock @PSBoundParameters
}

function New-ProvTaskMock {
    [CmdletBinding()]
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

function Get-ProvTaskMock {
    [CmdletBinding()]
    param ()

    return [guid]::NewGuid()
}

function Unlock-ProvVMMock {
    [CmdletBinding()]
    param ()

    Mock Unlock-ProvVM {}
}

function  Remove-ProvVMMock {
    [CmdletBinding()]
    param ()

    Mock Remove-ProvVM {}
}

function Remove-AcctADAccountMock {
    [CmdletBinding()]
    param ()

    Mock Remove-AcctADAccount {}
}

function Get-AcctIdentityPoolMock {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Lock = $false
    )

    return New-MockObject -Type ([Citrix.ADIdentity.Sdk.IdentityPool]) -Properties @{
        IdentityPoolName = 'MockIdentityPool'
        Lock             = $Lock
    }
}

function New-AcctADAccountMock {
    [CmdletBinding()]
    param (
        [Parameter()]
        [bool]$Lock = $false
    )

    $Domain = 'PESTER'
    $ADAccount = New-MockADComputer

    return New-MockObject -Type ([Citrix.ADIdentity.Sdk.AccountOperationDetailedSummary]) -Properties @{
        SuccessfulAccounts = @(
            @{
                ADAccountName    = "{0}\{1}" -f $Domain, $ADAccount.SamAccountName
                Domain           = $Domain
                IdentityPoolName = (Get-AcctIdentityPoolMock).IdentityPoolName
                ADAccountSid     = $ADAccount.SID
                Lock             = $Lock
            }
        )
    }
}

function New-ProvSchemeMock {
    [CmdletBinding()]
    param ()

    return New-MockObject -Type ([Citrix.MachineCreation.Sdk.ProvisioningScheme]) -Properties @{
        ProvisioningSchemeName = 'MockProvScheme'
    }
}

function Get-ProvSchemeMock {
    [CmdletBinding()]
    param ()

    return New-ProvSchemeMock
}

function Add-BrokerMachineMock {
    [CmdletBinding()]
    param ()

    return $null
}

function Start-LogHighLevelOperationMock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress = (New-MockAdminAddress),

        [Parameter()]
        [string]$Source = 'Citrix Autodeploy',

        [Parameter(Mandatory)]
        [string]$Text
    )

    return New-MockObject -Type ([Citrix.ConfigurationLogging.Sdk.HighLevelOperation]) -Properties @{
        Id            = [guid]::NewGuid()
        Source        = $Source
        OperationType = 'AdminActivity'
        Text          = $Text
    }
}

function Stop-LogHighLevelOperationMock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress = (New-MockAdminAddress),

        [Parameter()]
        [guid]$HighLevelOperationId,

        [Parameter()]
        [bool]$IsSuccessful
    )

    return $null
}

function New-TempFile {
    [CmdletBinding()]
    param ()

    return [System.IO.Path]::GetTempFileName()
}
