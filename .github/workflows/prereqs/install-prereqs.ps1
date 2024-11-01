function Invoke-MsiExec {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Install')]
        [string]$Action,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FilePath
    )

    $TimeStamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $LogName = "{0}_{1}_{2}.log" -f $FilePath.Name, $Action, $TimeStamp
    $Log = Join-Path $env:TEMP $LogName

    Write-Verbose $Log
    if ($Action -eq 'Install') {
        $Arguments.Add('/i')
        $Arguments.Add("`"$FilePath`"")
    }

    $Arguments.Add('/qn')
    $Arguments.Add('/norestart')
    $Arguments.Add("/log `"$Log`"")

    $StartProcessArgs = @{
        FilePath         = 'msiexec'
        ArgumentList     = $Arguments
        Wait             = $true
        WorkingDirectory = $FilePath.DirectoryName
        Passthru         = $true
    }

    '{0}ing {1}...' -f $Action, $FilePath
    $Process = Start-Process @StartProcessArgs

    Write-Verbose ("Command line: `n{0} {1}" -f $Process.StartInfo.FileName, $Process.StartInfo.Arguments)

    return "{0}`n" -f [ComponentModel.Win32Exception]$Process.ExitCode
}

Get-ChildItem "${PSScriptRoot}\modules\*.msi" | ForEach-Object {
    Invoke-MsiExec -Action Install -FilePath $_.FullName
}
