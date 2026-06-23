   # lib/Read-Config.ps1
# Lee config/settings.ini y retorna JSON para ser consumido por batch

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

$ini = @{}
$currentSection = ""

Get-Content $ConfigPath | ForEach-Object {
    $line = $_.Trim()

    # Skip comments and empty
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(";")) {
        return
    }

    # Section: [Paths]
    if ($line -match "^\[(.+)\]$") {
        $currentSection = $matches[1]
        $ini[$currentSection] = @{}
        return
    }

    # Key=Value
    if ($line -match "^(.+?)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()

        # Strip quotes if present
        if ($value -match '^"(.*)"$') {
            $value = $matches[1]
        }

        if ($currentSection) {
            $ini[$currentSection][$key] = [Environment]::ExpandEnvironmentVariables($value)
        }
    }
}

# Output as JSON
$ini | ConvertTo-Json -Depth 10
