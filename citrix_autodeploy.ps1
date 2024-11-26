#Requires -Modules PoShLog

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FilePath = $env:CITRIX_AUTODEPLOY_CONFIG,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Information', 'Debug', 'Warning', 'Error', 'Verbose', 'Fatal', 'None')]
    [string]$LogLevel = $(if ($env:CITRIX_AUTODEPLOY_LOGLEVEL) { $env:CITRIX_AUTODEPLOY_LOGLEVEL } else { 'Information' }),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE,

    [Parameter()]
    $MaxRecordCount = $(if ($env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT) { $env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT } else { 10000 }),

    [Parameter()]
    [switch]$DryRun = [System.Convert]::ToBoolean($env:CITRIX_AUTODEPLOY_DRYRUN),

    [Parameter()]
    [string]$LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{Level:u3}] {Message:lj}{NewLine}{Exception}'
)

if ($DryRun) {
    $LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{Level:u3}] [DRYRUN] {Message:lj}{NewLine}{Exception}'
}

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop 3> $null 4> $null

if ($LogLevel -ne 'None') {
    $Logger = Initialize-CtxAutodeployLogger -LogLevel $LogLevel -LogFile $LogFile -LogOutputTemplate $LogOutputTemplate
}

Write-DebugLog -Message "Citrix Autodeploy started via {MyCommand} with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand.Source, ($PSBoundParameters | Out-String)

Initialize-CtxAutodeployEnv

$Config = Get-CtxAutodeployConfig -FilePath $FilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    Write-InfoLog -Message "Starting job:`n{AutodeployMonitor}" -PropertyValues ($AutodeployMonitor | ConvertTo-Json)

    foreach ($Ddc in $AutodeployMonitor.AdminAddress) {
        if (Test-DdcConnection -AdminAddress $Ddc -Protocol 'https') {
            $AdminAddress = $Ddc
            Write-DebugLog -Message "Using delivery controller {Ddc}" -PropertyValues $Ddc
            break
        }
    }

    if (-Not $AdminAddress) {
        Write-ErrorLog -Message "Failed to connect to any of the configured delivery controllers"
        continue
    }

    $PreTask  = $AutodeployMonitor.PreTask
    $PostTask = $AutodeployMonitor.PostTask

    try {
        $BrokerCatalog = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog -MaxRecordCount $MaxRecordCount
    }
    catch {
        Write-ErrorLog -Message "Failed to read catalog {BrokerCatalog} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.AdminAddress
        continue
    }

    if ($AutodeployMonitor.MaxMachinesInBrokerCatalog) {
        if (Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $BrokerCatalog -MaxMachines $AutodeployMonitor.MaxMachinesInBrokerCatalog -MaxRecordCount $MaxRecordCount) {
            Write-WarningLog -Message "Max machine count {MaxMachinesInBrokerCatalog} reached for catalog {BrokerCatalog}" -PropertyValues $AutodeployMonitor.MaxMachinesInBrokerCatalog, $BrokerCatalog.Name
            continue
        }
    }

    try {
        $DesktopGroup = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
    }
    catch {
        Write-ErrorLog -Message "Failed to read desktop group {DesktopGroupName} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    if ($AutodeployMonitor.MaxMachinesInDesktopGroup) {
        if (Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $DesktopGroup -MaxMachines $AutodeployMonitor.MaxMachinesInDesktopGroup -MaxRecordCount $MaxRecordCount) {
            Write-WarningLog -Message "Max machine count {MaxMachinesInDesktopGroup} reached for desktop group {DesktopGroup}" -PropertyValues $AutodeployMonitor.MaxMachinesInDesktopGroup, $DesktopGroup.Name
            continue
        }
    }

    try {
        $UnassignedMachines = Get-BrokerMachine -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroup.Name -IsAssigned $false -MaxRecordCount $MaxRecordCount
        Write-DebugLog -Message "{UnassignedMachines} unassigned machines in desktop group {DesktopGroupName}" -PropertyValues $UnassignedMachines.Count, $DesktopGroup.Name
    }
    catch {
        Write-ErrorLog -Message "Failed to get unassigned machines for desktop group {DesktopGroupName} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    $MachinesToAdd = [math]::Max($AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count, 0)

    Write-InfoLog -Message "{MachinesToAdd} machines needed for catalog {BrokerCatalog}" -PropertyValues $MachinesToAdd, $BrokerCatalog.Name
    if ($MachinesToAdd -eq 0) {
        continue
    }

    while ($MachinesToAdd -gt 0) {
        try {
            $JobSuccessful = $true

            if ($AutodeployMonitor.MaxMachinesInBrokerCatalog) {
                if (Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $BrokerCatalog -MaxMachines $AutodeployMonitor.MaxMachinesInBrokerCatalog -MaxRecordCount $MaxRecordCount) {
                    Write-WarningLog -Message "Max machine count {MaxMachinesInBrokerCatalog} reached for catalog {BrokerCatalog}" -PropertyValues $AutodeployMonitor.MaxMachinesInBrokerCatalog, $BrokerCatalog.Name
                    break
                }
            }

            if ($AutodeployMonitor.MaxMachinesInDesktopGroup) {
                if (Test-MachineCountExceedsLimit -AdminAddress $AdminAddress -InputObject $DesktopGroup -MaxMachines $AutodeployMonitor.MaxMachinesInDesktopGroup -MaxRecordCount $MaxRecordCount) {
                    Write-WarningLog -Message "Max machine count {MaxMachinesInDesktopGroup} reached for desktop group {DesktopGroup}" -PropertyValues $AutodeployMonitor.MaxMachinesInDesktopGroup, $DesktopGroup.Name
                    break
                }
            }

            # Start Citrix Logger
            $CtxHighLevelLoggerParams = @{
                AdminAddress = $AdminAddress
                Source       = 'Citrix Autodeploy'
                Text         = "Citrix Autodeploy: Adding 1 machine: Catalog: '$($BrokerCatalog.Name)', DesktopGroup: $($DesktopGroup.Name)"
            }

            if (-not $DryRun) {
                $Logging = Start-CtxHighLevelLogger @CtxHighLevelLoggerParams
            }

            # Invoke Pre-task if defined
            if ($PreTask) {
                $ArgumentList = @{
                    AutodeployMonitor = $AutodeployMonitor
                    AdminAddress      = $AdminAddress
                    DesktopGroup      = $DesktopGroup
                    BrokerCatalog     = $BrokerCatalog
                    Logging           = $Logging
                }

                $CtxAutodeployTask = @{
                    FilePath     = $PreTask
                    Type         = 'Pre'
                    Context      = "Catalog: $($BrokerCatalog.Name), DesktopGroup: $($DesktopGroup.Name)"
                    ArgumentList = $ArgumentList
                }

                Write-InfoLog -Message "Invoking pre-task {PreTask}" -PropertyValues $PreTask
                if (-not $DryRun) {
                    Invoke-CtxAutodeployTask @CtxAutodeployTask
                }

                # Create machine
                $NewVMParams = @{
                    AdminAddress  = $AdminAddress
                    BrokerCatalog = $BrokerCatalog
                    DesktopGroup  = $DesktopGroup
                    Logging       = $Logging
                }

                Write-InfoLog -Message "Creating new machine for catalog {BrokerCatalog}" -PropertyValues $BrokerCatalog.Name
                if (-not $DryRun) {
                    $NewBrokerMachine = New-CtxAutodeployVM @NewVMParams
                }

                # Invoke Post-task if defined
                if ($PostTask) {
                    $PostTaskArgs = @{
                        AutodeployMonitor = $AutodeployMonitor
                        AdminAddress      = $AdminAddress
                        DesktopGroup      = $DesktopGroup
                        BrokerCatalog     = $BrokerCatalog
                        NewBrokerMachine  = $NewBrokerMachine
                        Logging           = $Logging
                    }
                }

                Write-InfoLog -Message "Invoking post-task {PostTask}" -PropertyValues $PostTask
                if (-not $DryRun) {
                    Invoke-CtxAutodeployTask -FilePath $PostTask -Type Post -Context $NewBrokerMachine.MachineName -ArgumentList $PostTaskArgs
                }
            }
        }

        catch {
            $JobSuccessful = $false
        }

        finally {
            if ($JobSuccessful) {
                Write-InfoLog -Message 'Job completed successfully'
            } else {
                Write-ErrorLog -Message 'Job failed'
            }

            # Stop Citrix Logger
            if ($Logging) {
                Stop-CtxHighLevelLogger -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -IsSuccessful $JobSuccessful
                Remove-Variable -Name Logging
            }

            $MachinesToAdd--
        }
    }
}

if ($InternalLogger) {
    Write-VerboseLog -Message 'Closing internal PoShLog logger'
    $InternalLogger | Close-Logger
}

if ($Logger) {
    Write-VerboseLog -Message 'Closing PoShLog logger'
    $Logger | Close-Logger
}
