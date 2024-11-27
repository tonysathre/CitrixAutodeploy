function Get-PathType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if ($Path -match '^https?://') {
        return 'Uri'
    }

    $InvalidPathChars = [System.IO.Path]::GetInvalidPathChars()
    $Pattern = [regex]::Escape(($InvalidPathChars -join ''))

    if ($Path -match "[$Pattern]") {
        return 'Unknown'
    }

    if (Test-Path -Path $Path -PathType Leaf) {
        return 'LocalFile'
    }

    return 'Unknown'
}
