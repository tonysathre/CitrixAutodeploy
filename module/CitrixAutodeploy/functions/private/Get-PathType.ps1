function Get-PathType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    if ($Path -match '^https?://') {
        return 'Uri'
    }

    # PowerShell 5.1 uses .NET 4.0.30319.42000
    # [System.IO.Path]::GetInvalidPathChars() contains these printable characters: "<>\|☺☻♥♦♣\t\n\f\r►◄↕‼¶§▬↨↑↓→∟↔▲▼
    # There are also several non-printable characters in the array.
    $InvalidPathChars = [System.IO.Path]::InvalidPathChars
    $Pattern = [regex]::Escape(($InvalidPathChars -join ''))

    if ($Path -match "[$Pattern]") {
        throw [System.IO.IOException]::new('The provided file path contains invalid characters: {0}' -f $Path)
    }

    if ([System.IO.Path]::GetExtension($Path)) {
        return 'LocalFile'
    }

    if (Test-Path $Path -PathType Container) {
        return 'Directory'
    }

    return 'Unknown'
}
