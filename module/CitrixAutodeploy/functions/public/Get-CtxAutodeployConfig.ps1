function Get-CtxAutodeployConfig {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path = $env:CITRIX_AUTODEPLOY_CONFIG
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    $PathType = Get-PathType -Path $Path
    Write-DebugLog -Message 'PathType: {PathType}' -PropertyValues $PathType

    switch ($PathType) {
        'Uri' {
            try {
                Write-VerboseLog -Message 'Downloading configuration from URL: {Path}' -PropertyValues $Path
                $Response = Invoke-WebRequest -Uri $Path -UseBasicParsing
                $ConfigContent = $Response.Content
            }
            catch {
                Write-ErrorLog -Message 'Failed to download the configuration file from URL: {Path}' -Exception $_.Exception -ErrorRecord $_ -PropertyValues $Path
                throw
            }
        }
        'LocalFile' {
            try {
                Write-VerboseLog -Message 'Reading configuration from local file: {Path}' -PropertyValues $Path
                $ConfigContent = Get-Content -Path $Path -Raw -ErrorAction Stop

                if ($ConfigContent.Length -eq 0) {
                    Write-ErrorLog -Message 'The configuration file is empty: {Path}' -PropertyValues $Path
                    throw [System.IO.IOException]::new('The configuration file is empty: {0}' -f $Path)
                }
            }
            catch {
                Write-FatalLog -Message 'Failed to read the configuration file from local path: {Path}' -Exception $_.Exception -ErrorRecord $_ -PropertyValues $Path
                throw
            }
        }
        'Directory' {
            Write-FatalLog -Message 'The provided path is a directory: {Path}' -Exception ([System.Management.Automation.ItemNotFoundException]::new('Directory path')) -PropertyValues $Path
            throw
        }
        default {
            Write-FatalLog -Message 'The provided path is neither a valid URL nor a local file path: {Path}' -Exception ([System.Management.Automation.ItemNotFoundException]::new('Invalid path or URL')) -PropertyValues $Path
            throw
        }
    }

    try {
        $Config = ConvertFrom-Json -InputObject $ConfigContent

        return $Config
    }
    catch {
        Write-ErrorLog -Message 'Failed to parse the configuration content as JSON: {ConfigContent}' -Exception $_.Exception -ErrorRecord $_ -PropertyValues $ConfigContent
        throw
    }
}
