# dot-source private functions
foreach ($Folder in @('private')) {
    $Root = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if (Test-Path -Path $Root) {
        Write-Verbose "processing folder $Root"
        $Files = Get-ChildItem -Path $Root -Filter *.ps1 -Recurse
        $Files | ForEach-Object { Write-Verbose $_.basename; . $PSItem.FullName }
    }
}
