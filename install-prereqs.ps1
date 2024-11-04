[CmdletBinding()]
param (
    [switch]$Force
)

function Invoke-MsiExec {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Install')]
        [string]$Action,

        [Parameter(Mandatory)]
        [System.IO.FileInfo]$FilePath,

        [Parameter()]
        [System.Collections.Generic.List[string]]$Arguments = @()
    )

    if ($Action -eq 'Install') {
        $Arguments.Add('/i')
        $Arguments.Add("`"$FilePath`"")
    }

    $Arguments.Add('/qn')
    $Arguments.Add('/norestart')

    $StartProcessArgs = @{
        FilePath         = 'msiexec'
        ArgumentList     = $Arguments
        Wait             = $true
        WorkingDirectory = $FilePath.DirectoryName
        Passthru         = $true
    }

    '{0}ing {1} ...' -f $Action, $FilePath
    $Process = Start-Process @StartProcessArgs

    Write-Verbose ("Command line: `n{0} {1}" -f $Process.StartInfo.FileName, $Process.StartInfo.Arguments)

    return "{0}`n" -f [ComponentModel.Win32Exception]$Process.ExitCode
}

Get-ChildItem "${PSScriptRoot}\prereqs\modules\*.msi" | ForEach-Object {
    Invoke-MsiExec -Action Install -FilePath $_.FullName
}

& ${PSScriptRoot}\requirements.ps1 | ForEach-Object {
    Install-Module @_ -AllowClobber -Confirm:$false -Force:$Force -SkipPublisherCheck
}
