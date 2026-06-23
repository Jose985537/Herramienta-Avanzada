   # launcher.ps1
# Orquestador principal - Herramienta Avanzada
# PUNTO UNICO DE ORQUESTACION

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$libDir = Join-Path $ScriptRoot "lib"

# ====== UAC ELEVATION ======
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "No tiene permisos de administrador. Solicitando elevacion..." -ForegroundColor Yellow
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $psi.Verb = "runas"
        $psi.WorkingDirectory = $ScriptRoot
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Error al solicitar elevacion: $_" -ForegroundColor Red
    }
    exit 1
}

# ====== IMPORTAR MODULOS ======
$modules = @(
    "MenuHelpers.ps1",
    "Maintenance.ps1",
    "Network.ps1",
    "SecurityPlus.ps1",
    "Info.ps1",
    "Power.ps1",
    "ConfigSys.ps1",
    "Users.ps1",
    "Services.ps1",
    "Backup.ps1",
    "Processes.ps1",
    "Hosts.ps1",
    "WiFi.ps1",
    "RDP.ps1",
    "PowerPlan.ps1",
    "TaskScheduler.ps1",
    "WindowsFeatures.ps1",
    "DriveMapping.ps1"
)

foreach ($module in $modules) {
    $path = Join-Path $libDir $module
    if (Test-Path $path) {
        . $path
    } else {
        Write-Host "[WARN] Modulo no encontrado: $path" -ForegroundColor Yellow
    }
}

# ====== CONFIG LOAD ======
$configFile = Join-Path (Join-Path $ScriptRoot "config") "settings.ini"
$global:Config = $null
if (Test-Path $configFile) {
    try {
        $configRaw = & (Join-Path $libDir "Read-Config.ps1") $configFile
        $global:Config = ($configRaw -join "`n") | ConvertFrom-Json
        Invoke-Log -Message "Configuracion cargada desde $configFile"
    } catch {
        Write-Host "[ERROR] No se pudo cargar config: $_" -ForegroundColor Red
        $global:Config = $null
    }
} else {
    Write-Host "[WARN] Archivo de configuracion no encontrado: $configFile" -ForegroundColor Yellow
    $global:Config = $null
}

# ====== VERSION ======
$global:AppVersion = "v5.0"

# ====== MAIN MENU ======
    <#
    .SYNOPSIS
    Muestra el menu principal de la aplicacion
    #>
function Show-MainMenu {
    param([switch]$NoClear)
    if (-not $NoClear) { Clear-Host }
    $host.UI.RawUI.WindowTitle = "Herramienta Avanzada $global:AppVersion"
    
    $color = "DarkCyan"
    
    $line = "=" * 67
    Write-Host $line -ForegroundColor $color
    Write-Host "      HERRAMIENTA TECNICA AVANZADA $global:AppVersion" -ForegroundColor Cyan
    Write-Host "      Creado por: NEXUS_CALDERON" -ForegroundColor Gray
    Write-Host $line -ForegroundColor $color
    
    Write-Menu -Options @(
        "   1. Mantenimiento del Sistema (incl. USB)",
        "   2. Red, Conexiones y Carpetas Compartidas",
        "   3. Seguridad, Firewall y Permisos",
        "   4. Informacion del Sistema",
        "   5. Apagar/Reiniciar/Bloqueo",
        "   6. Configuracion del equipo",
        "   7. Administracion de cuentas de usuario",
        "   8. Servicios y Aplicaciones de inicio",
        "   9. Copia de seguridad de controladores",
        "  10. Gestor de Procesos",
        "  11. Editor de Archivo Hosts",
        "  12. Gestion de Perfiles WiFi",
        "  13. Escritorio Remoto (RDP)",
        "  14. Planes de Energia",
        "  15. Tareas Programadas",
        "  16. Caracteristicas de Windows",
        "  17. Mapeo de Unidades de Red",
        "   0. Salir"
    )
    
    $opt = Read-MenuChoice -Prompt "Seleccione una opcion [0-17]" -Max 17
    return $opt
}

# ====== MAIN LOOP ======
do {
    $choice = Show-MainMenu
    if ($choice -eq 0) { break }
    switch ($choice) {
        1  { Show-MaintenanceMenu }
        2  { Show-NetworkMenu }
        3  { Show-SecurityMenu }
        4  { Show-InfoMenu }
        5  { Show-PowerMenu }
        6  { Show-ConfigSysMenu }
        7  { Show-UsersMenu }
        8  { Show-ServicesMenu }
        9  { Show-BackupMenu }
        10 { Show-ProcessMenu }
        11 { Show-HostsMenu }
        12 { Show-WiFiMenu }
        13 { Show-RDPMenu }
        14 { Show-PowerPlanMenu }
        15 { Show-TaskSchedulerMenu }
        16 { Show-WindowsFeaturesMenu }
        17 { Show-DriveMappingMenu }
    }
    Pause-Message "Presione ENTER para volver al menu principal..."
} while ($true)

Invoke-Log -Message "Aplicacion cerrada por el usuario"
Clear-Host
Write-Host "`nGracias por utilizar Herramienta Avanzada $global:AppVersion" -ForegroundColor Cyan
Write-Host "Creado por: NEXUS_CALDERON`n" -ForegroundColor Gray
exit 0

