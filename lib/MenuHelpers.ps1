   # lib/MenuHelpers.ps1
# Funciones de UI compartidas para todos los modulos

    <#
    .SYNOPSIS
    Muestra titulo decorativo del menu
    #>
function Write-Title {
    param([string]$Title, [string]$Color = "Cyan")
    $line = "=" * 60
    Write-Host "`n$line" -ForegroundColor $Color
    Write-Host (" " * (([Math]::Max(0, 60 - $Title.Length) / 2))) -NoNewline
    Write-Host $Title -ForegroundColor $Color
    Write-Host "  NEXUS_CALDERON" -ForegroundColor DarkGray
    Write-Host "$line`n" -ForegroundColor $Color
}

    <#
    .SYNOPSIS
    Muestra subtitulo decorativo
    #>
function Write-Subtitle {
    param([string]$Title, [string]$Color = "Cyan")
    $line = "=" * 50
    Write-Host "`n$line" -ForegroundColor $Color
    Write-Host $Title -ForegroundColor $Color
    Write-Host "$line`n" -ForegroundColor $Color
}

    <#
    .SYNOPSIS
    Muestra lista de opciones del menu
    #>
function Write-Menu {
    param([string]$Prompt = "Seleccione opcion", [array]$Options)
    $line = "-" * 50
    Write-Host $line -ForegroundColor DarkGray
    foreach ($opt in $Options) {
        Write-Host $opt
    }
    Write-Host $line -ForegroundColor DarkGray
}

    <#
    .SYNOPSIS
    Lee seleccion numerica del usuario con validacion
    #>
function Read-MenuChoice {
    param([string]$Prompt = "Seleccione una opcion [0-9]", [int]$Min = 0, [int]$Max = 9)
    do {
        $choice = Read-Host "`n$Prompt"
        if ($choice -match "^\d+$" -and [int]$choice -ge $Min -and [int]$choice -le $Max) {
            return [int]$choice
        }
        Write-Host "Opcion invalida. Ingrese un numero entre $Min y $Max." -ForegroundColor Red
    } while ($true)
}

    <#
    .SYNOPSIS
    Lee contrasena de forma segura (sin eco en pantalla)
    #>
function Read-SecurePassword {
    param([string]$Prompt = "Contrasena")
    $ss = Read-Host -AsSecureString -Prompt $Prompt
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    return $plain
}

    <#
    .SYNOPSIS
    Lee confirmacion S/N del usuario
    #>
function Read-YesNo {
    param([string]$Prompt = "Confirma (S/N)", [string]$Default = "N")
    do {
        $r = (Read-Host "$Prompt ($Default)").Trim().ToUpper()
        if ($r -eq "") { $r = $Default.ToUpper() }
        if ($r -eq "S") { return $true }
        if ($r -eq "N") { return $false }
        Write-Host "Responda S o N" -ForegroundColor Red
    } while ($true)
}

    <#
    .SYNOPSIS
    Muestra mensaje y espera Enter
    #>
function Pause-Message {
    param([string]$Message = "Presione ENTER para continuar...")
    Write-Host "`n$Message" -ForegroundColor DarkGray
    $null = Read-Host
}

    <#
    .SYNOPSIS
    Muestra resultado con icono y color segun estado
    #>
function Write-Result {
    param([string]$Message, [string]$Status = "OK")
    $color = switch ($Status) {
        "OK" { "Green" }
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    $icon = switch ($Status) {
        "OK" { "`u{2713}" }
        "ERROR" { "`u{2717}" }
        "WARN" { "`u{26A0}" }
        default { "i" }
    }
    Write-Host "$icon $Message" -ForegroundColor $color
}

    <#
    .SYNOPSIS
    Escribe entrada en el archivo de log
    #>
function Invoke-Log {
    param([string]$Level = "INFO", [string]$Message)
    $logDir = Get-ConfigValue "LogDir"
    if ([string]::IsNullOrWhiteSpace($logDir)) {
        $logDir = Join-Path (Get-ScriptDirectory) "..\logs"
    } elseif (-not [IO.Path]::IsPathRooted($logDir)) {
        $logDir = Join-Path (Get-ScriptDirectory) $logDir
    }
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $logFile = Join-Path $logDir "app.log"
    $retention = Get-ConfigValue "RetentionDays"
    if ($retention -and (Test-Path $logFile)) {
        $days = [int]$retention
        if ($days -gt 0) {
            $lastWrite = (Get-Item $logFile).LastWriteTime
            if ((Get-Date) - $lastWrite -gt [TimeSpan]::FromDays($days)) {
                Move-Item -Path $logFile -Destination "$logFile.$((Get-Date $lastWrite -Format 'yyyyMMdd'))" -Force
            }
        }
    }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $entry
}

    <#
    .SYNOPSIS
    Obtiene valor de configuracion por clave
    #>
function Get-ConfigValue {
    param([string]$Key, [string]$Default = "")
    if ($global:Config) {
        foreach ($section in $global:Config.PSObject.Properties) {
            if ($section.Value -and $section.Value.$Key) {
                return $section.Value.$Key
            }
        }
    }
    $configPath = Join-Path (Get-ScriptDirectory) "..\config\settings.ini"
    if (-not (Test-Path $configPath)) { return $Default }
    try {
        $escapedKey = [regex]::Escape($Key)
        foreach ($line in Get-Content $configPath) {
            if ($line -match "^$escapedKey=(.+)$") {
                return $matches[1].Trim('"')
            }
        }
    } catch {
        Write-Host "[WARN] Get-ConfigValue($Key): $_" -ForegroundColor Yellow
    }
    return $Default
}

    <#
    .SYNOPSIS
    Obtiene la ruta del directorio del script actual
    #>
function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    $callStack = Get-PSCallStack
    if ($callStack.Count -ge 2) {
        return Split-Path $callStack[1].ScriptName -Parent
    }
    return (Get-Location).Path
}

