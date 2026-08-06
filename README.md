# Herramienta Avanzada v5.0 -- Bitacora Tecnica de Desarrollo (15 Dias)

Suite de administracion de Windows en PowerShell 5.1 con 18 modulos funcionales. 138 tests automatizados.

---

## Dia 1: Analisis de requisitos y definicion de alcance

- **Que se hizo**: Se analizaron los requerimientos para una suite portable de administracion de Windows. Se definieron 18 areas funcionales: mantenimiento, red, seguridad, informacion, energia, configuracion del sistema, usuarios, servicios, backup, procesos, hosts, WiFi, RDP, planes de energia, tareas programadas, caracteristicas de Windows, mapeo de unidades. Se decidio que cada modulo tendria su propio submenu con opciones especificas.

- **Archivos creados/modificados**: (ninguno - fase de planificacion)

- **Codigo critico**: (ninguno)

- **Registro/INI/Env afectados**: ninguno

---

## Dia 2: Decisiones arquitectonicas

- **Que se hizo**: Se definio la arquitectura en capas: batch wrapper -> orquestador PowerShell -> configuracion INI -> 18 modulos dot-sourced. Decisiones clave: PowerShell 5.1 (no 7) por disponibilidad nativa en Windows; dot-sourcing en vez de modulos formales para evitar problemas de firma y deployment; INI en vez de JSON para configuracion editable por usuarios no tecnicos; UAC elevation explicita via `ProcessStartInfo.Verb = "runas"` en vez de `#Requires -RunAsAdministrator` para tener control del flujo.

- **Archivos creados/modificados**: (ninguno)

- **Codigo critico**: Se definio el patron de cada modulo: `function Show-NombreMenu` como unico punto de entrada, llamado via `switch` desde `launcher.ps1`. Cada funcion interna con prefijo `Invoke-` o `Get-` segun accion.

- **Registro/INI/Env afectados**: ninguno

---

## Dia 3: Creacion de launcher.ps1 y UAC elevation

- **Que se hizo**: Se creo `launcher.ps1` como orquestador principal. Implementa deteccion de admin via `WindowsPrincipal.IsInRole([WindowsBuiltInRole]::Administrator)` (lineas 9-10) y elevacion explicita con `ProcessStartInfo.Verb = "runas"` (lineas 15-20). Define el array `$modules` con los 18 archivos (lineas 28-47), los carga con dot-sourcing (linea 52), invoca `Read-Config.ps1` para cargar `settings.ini` en `$global:Config` (lineas 59-73), y ejecuta el bucle principal del menu (lineas 122-151).

- **Archivos creados/modificados**: `launcher.ps1`

- **Codigo critico**:
```powershell
# launcher.ps1 lineas 9-25: UAC elevation
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    $psi.WorkingDirectory = $ScriptRoot
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit 1
}
```

- **Registro/INI/Env afectados**: ninguno

---

## Dia 4: Configuracion centralizada -- settings.ini y Read-Config.ps1

- **Que se hizo**: Se creo `config/settings.ini` con tres secciones: `[Paths]` (BackupSourceDrivers, BackupSourceDriverStore, BackupSourceInf, BackupDest, LogDir, TempDir), `[Logging]` (Level, RetentionDays), `[Behavior]` (EnableDebugLog, ColorSuccess, ColorError, ColorWarn). Se creo `lib/Read-Config.ps1` como parser INI -> JSON que expande variables de entorno via `[Environment]::ExpandEnvironmentVariables()` (linea 44). El parser lee linea por linea, identifica secciones `[Section]` (lineas 27-31) y pares `Key=Value` (lineas 34-46), ignorando comentarios con `;`.

- **Archivos creados/modificados**: `config/settings.ini`, `lib/Read-Config.ps1`

- **Codigo critico**:
```powershell
# lib/Read-Config.ps1 linea 44: expansion de variables de entorno
if ($currentSection) {
    $ini[$currentSection][$key] = [Environment]::ExpandEnvironmentVariables($value)
}
```

- **Registro/INI/Env afectados**: `%SYSTEMROOT%` y `%TEMP%` expandidos en las claves `BackupSourceDrivers`, `BackupSourceDriverStore`, `BackupSourceInf`, `BackupDest`, `LogDir`, `TempDir`.

---

## Dia 5: Funciones compartidas -- MenuHelpers.ps1 y batch wrapper

- **Que se hizo**: Se creo `lib/MenuHelpers.ps1` con 10 funciones compartidas: `Write-Title`, `Write-Subtitle`, `Write-Menu`, `Read-MenuChoice`, `Read-SecurePassword`, `Read-YesNo`, `Pause-Message`, `Write-Result`, `Invoke-Log`, `Get-ConfigValue`, `Get-ScriptDirectory`. Cada una con bloque `<# .SYNOPSIS #>`. Se creo `Herramienta Avanzada.bat` con verificacion de admin via `fltmc.exe` (linea 6, reemplazando el deprecado `cacls.exe`), creacion de VBS para elevacion UAC en batch (lineas 11-14), y lanzamiento de `launcher.ps1` con `-ExecutionPolicy Bypass` (linea 35).

- **Archivos creados/modificados**: `lib/MenuHelpers.ps1`, `Herramienta Avanzada.bat`

- **Codigo critico**:
```powershell
# lib/MenuHelpers.ps1 lineas 123-146: logging con rotacion
function Invoke-Log {
    param([string]$Level = "INFO", [string]$Message)
    $logDir = Get-ConfigValue "LogDir"
    $logFile = Join-Path $logDir "app.log"
    $retention = Get-ConfigValue "RetentionDays"
    if ($retention -and (Test-Path $logFile)) {
        $days = [int]$retention
        if ((Get-Date) - (Get-Item $logFile).LastWriteTime -gt [TimeSpan]::FromDays($days)) {
            Move-Item -Path $logFile -Destination "$logFile.$((Get-Date -Format 'yyyyMMdd'))" -Force
        }
    }
    Add-Content -Path $logFile -Value "[$timestamp] [$Level] $Message"
}
```

```batch
REM Herramienta Avanzada.bat linea 6-16: verificacion de admin
>nul 2>&1 "%SYSTEMROOT%\system32\fltmc.exe"
if '%errorlevel%' NEQ '0' (
    echo Set UAC = CreateObject("Shell.Application") > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)
```

- **Registro/INI/Env afectados**: `LogDir`, `RetentionDays`, `Level`, `EnableDebugLog`, `ColorSuccess`, `ColorError`, `ColorWarn` desde `settings.ini`.

---

## Dia 6: Modulos Maintenance, Network, SecurityPlus, Info

- **Que se hizo**: Se crearon 4 modulos funcionales. `Maintenance.ps1` (383 lineas): limpieza de temporales (`Invoke-CleanTemp`), SFC scan (`Invoke-SFCScan`), optimizacion de volumenes (`Invoke-OptimizeVolume`), hibernacion (`Invoke-HibernationMenu`), CHKDSK (`Invoke-CHKDSK`), restore points (`New-RestorePoint`, `Get-RestorePoints`), limpieza de Windows Update (`Invoke-CleanWUCache`), montaje/desmontaje USB (`Invoke-USBEject`, `Invoke-USBMount`). `Network.ps1` (183 lineas): configuracion de red, renovacion IP, puerto 443, DNS flush, TCP/IP reset, adaptadores, carpetas compartidas. `SecurityPlus.ps1` (168 lineas): firewall on/off/status, takeown, grant full control, force delete. `Info.ps1` (97 lineas): hardware info (WMI), programas instalados (registry).

- **Archivos creados/modificados**: `lib/Maintenance.ps1`, `lib/Network.ps1`, `lib/SecurityPlus.ps1`, `lib/Info.ps1`

- **Codigo critico**: Cada modulo sigue el patron de menu con do-while y switch:
```powershell
# lib/Maintenance.ps1 lineas 8-37: patron de submenu
function Show-MaintenanceMenu {
    do {
        Clear-Host; Write-Title "MANTENIMIENTO DEL SISTEMA"
        Write-Menu -Options @("1. ...", "2. ...", ... "0. Volver")
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 9
        switch ($opt) { 1 { Invoke-CleanTemp } 2 { Invoke-SFCScan } ... }
    } while ($opt -ne 0)
}
```

- **Registro/INI/Env afectados**: `TempDir` para limpieza de temporales; `%WINDIR%`, `%TEMP%`, `%LOCALAPPDATA%` para paths de limpieza.

---

## Dia 7: Modulos Power, ConfigSys, Users, Services

- **Que se hizo**: `Power.ps1` (78 lineas): shutdown, reboot, logoff, lock via `shutdown.exe` y `rundll32.exe`. `ConfigSys.ps1` (201 lineas): nombre del equipo (`Rename-Computer`), grupo de trabajo (`Add-Computer -WorkgroupName`), descripcion (`Set-CimInstance`), archivos ocultos/protegidos via registry `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced`. `Users.ps1` (687 lineas): el modulo mas extenso -- CRUD de usuarios locales (`New-LocalUser`, `Set-LocalUser`, `Remove-LocalUser`), grupos y permisos con SIDs (`S-1-5-32-544` para Administrators, `S-1-5-32-545` para Users), contrasenas (`Read-SecurePassword`, `Set-LocalUser -Password`), perfiles de usuario (`Win32_UserProfile`). `Services.ps1` (168 lineas): servicios (`Start-Service`, `Stop-Service`, `Restart-Service`), aplicaciones de inicio via `HKCU:\...\Run`.

- **Archivos creados/modificados**: `lib/Power.ps1`, `lib/ConfigSys.ps1`, `lib/Users.ps1`, `lib/Services.ps1`

- **Codigo critico**: Users.ps1 utiliza SIDs en vez de nombres localizados de grupo para compatibilidad ES/EN:
```powershell
# lib/Users.ps1 lineas 100-102: grupo por SID
$adminGroup = Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-544' }
if ($adminGroup) { Add-LocalGroupMember -Group $adminGroup.Name -Member $userName -ErrorAction Stop }
```

- **Registro/INI/Env afectados**: `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Hidden`, `ShowSuperHidden` para archivos ocultos. `HKCU:\Software\Microsoft\Windows\CurrentVersion\Run` para aplicaciones de inicio.

---

## Dia 8: Modulos Backup, Processes, Hosts, WiFi

- **Que se hizo**: `Backup.ps1` (221 lineas): `Get-ConfigSourcePaths` lee rutas de `settings.ini`, `Backup-Drivers` copia `Drivers`, `DriverStore\FileRepository`, `inf` y exporta registro `HKLM\SYSTEM\CurrentControlSet\Control\Class`. Soporta destino predeterminado, personalizado y USB. `Processes.ps1` (178 lineas): listar, top memoria/CPU, detalle por PID/nombre, kill por PID/nombre con `Format-Table` personalizado. `Hosts.ps1` (213 lineas): `Get-HostsEntries`, `Invoke-AddHostEntry`, `Invoke-RemoveHostEntry` (whitespace-agnostic, elimina una sola entrada), `Invoke-BlockWebsite` (redirige a `0.0.0.0`). `WiFi.ps1` (151 lineas): perfiles WiFi via `netsh wlan`, claves con `key=clear`, exportacion a XML, eliminacion.

- **Archivos creados/modificados**: `lib/Backup.ps1`, `lib/Processes.ps1`, `lib/Hosts.ps1`, `lib/WiFi.ps1`

- **Codigo critico**: Backup.ps1 obtiene rutas desde config centralizada:
```powershell
# lib/Backup.ps1 lineas 54-68: Get-ConfigSourcePaths
function Get-ConfigSourcePaths {
    $srcDrivers = Get-ConfigValue -Key "BackupSourceDrivers" -Default "$env:SystemRoot\System32\Drivers"
    $srcDriverStore = Get-ConfigValue -Key "BackupSourceDriverStore"
    $srcInf = Get-ConfigValue -Key "BackupSourceInf"
    $dest = Get-ConfigValue -Key "BackupDest" -Default ".\backups\drivers"
    return @{ SourceDrivers = $srcDrivers; SourceDriverStore = $srcDriverStore; SourceInf = $srcInf; Dest = $dest }
}
```

- **Registro/INI/Env afectados**: `BackupSourceDrivers`, `BackupSourceDriverStore`, `BackupSourceInf`, `BackupDest` desde `settings.ini`. `HKLM\SYSTEM\CurrentControlSet\Control\Class` exportado como respaldo.

---

## Dia 9: Modulos RDP, PowerPlan, TaskScheduler

- **Que se hizo**: `RDP.ps1` (109 lineas): activar/desactivar via registry `HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections` (0=activado, 1=desactivado) y reglas de firewall para "Escritorio remoto" y "Remote Desktop" (soporte bilingue). `PowerPlan.ps1` (176 lineas): `Get-PowerPlanGuid` busca GUID por nombre en `powercfg /list`, `Get-PowerPlanGuidSmart` busca ES y EN, `Invoke-SetPowerPlanSmart` activa plan con busqueda bilingue, `Invoke-CreatePowerPlan` duplica plan base y renombra. `TaskScheduler.ps1` (148 lineas): `Get-ScheduledTask`, `Start-ScheduledTask`, `Disable/Enable/Unregister-ScheduledTask`, `Register-ScheduledTask` con trigger diario.

- **Archivos creados/modificados**: `lib/RDP.ps1`, `lib/PowerPlan.ps1`, `lib/TaskScheduler.ps1`

- **Codigo critico**: PowerPlan usa busqueda bilingue para compatibilidad ES/EN:
```powershell
# lib/PowerPlan.ps1 lineas 55-62: busqueda bilingue de planes
function Get-PowerPlanGuidSmart {
    param([string]$SpanishName, [string]$EnglishName)
    $guid = Get-PowerPlanGuid $SpanishName
    if ($guid) { return $guid }
    $guid = Get-PowerPlanGuid $EnglishName
    if ($guid) { return $guid }
    return $null
}
```

- **Registro/INI/Env afectados**: `HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\fDenyTSConnections` para RDP. `HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\PortNumber` para lectura de puerto.

---

## Dia 10: Modulos WindowsFeatures, DriveMapping y cableado completo

- **Que se hizo**: `WindowsFeatures.ps1` (119 lineas): `Get-WindowsOptionalFeature -Online`, `Enable/Disable-WindowsOptionalFeature` via DISM. `DriveMapping.ps1` (95 lineas): mapeo de unidades de red (`net use`), desconexion (`net use ... /delete`), listado (`Win32_LogicalDisk DriveType=4`). Se completo el cableado del switch en `launcher.ps1` (lineas 125-143) conectando los 17 casos numericos a las funciones `Show-*Menu` correspondientes.

- **Archivos creados/modificados**: `lib/WindowsFeatures.ps1`, `lib/DriveMapping.ps1`, `launcher.ps1` (switch ya completo)

- **Codigo critico**: Switch principal en launcher.ps1:
```powershell
# launcher.ps1 lineas 125-143
switch ($choice) {
    1  { Show-MaintenanceMenu }   2  { Show-NetworkMenu }
    3  { Show-SecurityMenu }     4  { Show-InfoMenu }
    5  { Show-PowerMenu }        6  { Show-ConfigSysMenu }
    7  { Show-UsersMenu }        8  { Show-ServicesMenu }
    9  { Show-BackupMenu }       10 { Show-ProcessMenu }
    11 { Show-HostsMenu }        12 { Show-WiFiMenu }
    13 { Show-RDPMenu }          14 { Show-PowerPlanMenu }
    15 { Show-TaskSchedulerMenu } 16 { Show-WindowsFeaturesMenu }
    17 { Show-DriveMappingMenu }
}
```

- **Registro/INI/Env afectados**: ninguno nuevo.

---

## Dia 11: Correccion de bugs -- PowerPlan, Users, Maintenance, Hosts

- **Que se hizo**: **PowerPlan**: bug critico donde `Invoke-CreatePowerPlan` usaba `Select-Object -Skip 1 -First 1` que devolvia el plan original en vez del duplicado. Corregido a `Select-Object -Last 1` (linea 160). Ahora el GUID del nuevo plan se obtiene correctamente. **Users**: se reemplazaron nombres localizados de grupo por SIDs universales (`S-1-5-32-544`, `S-1-5-32-545`). Ej: al crear usuario administrador se busca `Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-544' }` (linea 101). Esto funciona en Windows ES, EN, FR, DE, etc. **Maintenance**: USBEject usando `Win32_Volume.Dismount()` (lineas 331-333) en vez de `Remove-Partition` que destruia datos. Ahora desmonta sin eliminar particiones. CHKDSK con `echo Y |` (linea 190) para evitar que se cuelgue esperando input. **Hosts**: eliminacion de entradas ahora es whitespace-agnostic (compara `$lineParts[0]` y `$lineParts[1]` en vez de string exacto, lineas 126-134) y elimina solo la primera coincidencia.

- **Archivos creados/modificados**: `lib/PowerPlan.ps1`, `lib/Users.ps1`, `lib/Maintenance.ps1`, `lib/Hosts.ps1`

- **Codigo critico**: USBEject con Dismount():
```powershell
# lib/Maintenance.ps1 lineas 331-333
$drive = Get-CimInstance Win32_Volume -Filter "DriveLetter='${letter}:'" -ErrorAction Stop
if ($drive) {
    $drive | Invoke-CimMethod -MethodName Dismount -Arguments @{Force=$false;Permanent=$false} | Out-Null
}
```

- **Registro/INI/Env afectados**: ninguno.

---

## Dia 12: Correccion de bugs -- Network, WiFi, codigo muerto, encoding

- **Que se hizo**: **Network**: `Show-Port443` (linea 73) usa `findstr :443` para filtrar puerto exacto, evitando falsos positivos (ej. puerto 4430 ya no coincide). **WiFi**: `Invoke-ShowWiFiKey` usa `Select-Object -First 1` (linea 75) antes de `-match` para evitar el bug de PowerShell donde `$matches` se comporta incorrectamente con arrays. **Codigo muerto eliminado**: `Write-Log.ps1` (reemplazado por `Invoke-Log`), `Read-Password.ps1` (reemplazado por `Read-SecurePassword`), `Read-SecureInput` (nunca usado), `$wifiProfiles` (nunca usado), `$exitRequested` (ramas identicas), `Validate-Phase2.ps1` en raiz (archivo de 0 bytes). **Encoding**: todos los `.ps1` normalizados a UTF-8 con BOM, contenido 100% ASCII (sin acentos ni caracteres especiales en el codigo).

- **Archivos creados/modificados**: `lib/Network.ps1`, `lib/WiFi.ps1`, todos los `.ps1` (normalizacion encoding)

- **Codigo critico**: WiFi con `Select-Object -First 1`:
```powershell
# lib/WiFi.ps1 lineas 75-78
$keyText = $keyLine | Select-Object -First 1
if ($keyText -match ':\s+(.+)$') {
    Write-Host "Clave: " -NoNewline
    Write-Host $matches[1].Trim() -ForegroundColor Green -BackgroundColor Black
}
```

- **Registro/INI/Env afectados**: ninguno.

---

## Dia 13: Tests automatizados -- 3 suites, 138 tests

- **Que se hizo**: Se crearon 3 suites de validacion. **`Validate-Phase1.ps1`** (10 tests): verifica existencia de `settings.ini`, parseo correcto de `Read-Config.ps1` (confirma `BackupSourceDrivers = "C:\Windows\System32\Drivers"`), funcionamiento de `Invoke-Log`, existencia de `Read-SecurePassword`, ausencia de `set /p` passwords en batch, parseo sintactico de `launcher.ps1`, existencia de 18 modulos, parametro `Mandatory=$true` en Read-Config, ausencia de referencias a modulos huerfanos (`Write-Log.ps1`, `Read-Password.ps1`), y `Write-Result` con estados OK/ERROR/WARN/INFO. **`Validate-Phase2.ps1`** (88 tests): carga todos los modulos con dot-sourcing, verifica existencia de cada modulo, wrapper .bat (< 60 lineas, invoca launcher), config con 3 secciones, funciones clave de MenuHelpers (7 funciones), cada modulo exporta su `Show-*Menu` (17 funciones), launcher importa los 18 modulos, parseo sintactico de todos los `.ps1`, Read-Config parsea INI correctamente. **`Functional-Tests.ps1`** (40 tests): carga de 18 modulos sin error, funciones base del menu (10 funciones), lectura de config keys (`BackupSourceDrivers`, `Level`, `EnableDebugLog`), `Get-PowerPlanGuid` para 3 planes (Equilibrado, Alto rendimiento, Economizador), `Get-ScheduledTask`, `Get-Process`, `ipconfig`, `Get-NetAdapter`, acceso a hosts, estado RDP via registry, `netsh wlan`, `Win32_LogicalDisk`, `Get-WindowsOptionalFeature`, launcher branding y referencias, ausencia de passwords hardcoded, `Get-ConfigSourcePaths` con 4 claves, colisiones de funciones entre modulos, branding NEXUS_CALDERON.

- **Archivos creados/modificados**: `test/Validate-Phase1.ps1`, `test/Validate-Phase2.ps1`, `test/Functional-Tests.ps1`

- **Codigo critico**: Patron de test en Phase2:
```powershell
# test/Validate-Phase2.ps1 lineas 24-42: Test-Assertion
function Test-Assertion {
    param([string]$Name, [scriptblock]$Block)
    try {
        $result = & $Block
        if ($result) { [void]$testResult.Add(@{Name=$Name; Status="PASS"}); Write-Host "  [PASS] $Name" -ForegroundColor Green }
        else { [void]$testResult.Add(@{Name=$Name; Status="FAIL"}); Write-Host "  [FAIL] $Name" -ForegroundColor Red }
    } catch { [void]$testResult.Add(@{Name=$Name; Status="FAIL"}); Write-Host "  [FAIL] $Name (exception: $_ )" -ForegroundColor Red }
}
```

- **Registro/INI/Env afectados**: ninguno.

---

## Dia 14: Documentacion y branding

- **Que se hizo**: Se agregaron bloques `<# .SYNOPSIS #>` de ayuda a todas las funciones (~80 en total) en los 18 modulos y el launcher. Se creo `publicidad.txt` con release notes (mejoras de v5.0: 100% ASCII, 5 modulos reparados, bugs corregidos, 138 tests, logging centralizado, compatibilidad ES/EN). Se agrego branding `NEXUS_CALDERON` en el titulo del launcher (linea 93), en `Write-Title` (linea 14), y en todos los modulos via herencia. Se creo `.gitignore` (18 lineas) excluyendo logs, backups, *.tmp, *.vbs, Thumbs.db, Desktop.ini, *.ps1xml, module.cache.

- **Archivos creados/modificados**: `publicidad.txt`, `.gitignore`

- **Codigo critico**: Bloque de ayuda en cada funcion:
```powershell
    <#
    .SYNOPSIS
    Limpia archivos temporales y papelera
    #>
function Invoke-CleanTemp { ... }
```

- **Registro/INI/Env afectados**: ninguno.

---

## Dia 15: Integracion final y cierre

- **Que se hizo**: Consolidacion de todos los componentes. Verificacion del flujo completo: `Herramienta Avanzada.bat` -> verifica admin con `fltmc.exe` -> eleva via VBS si no -> lanza `launcher.ps1` -> UAC elevation en PowerShell si es necesario -> carga `Read-Config.ps1` que parsea `settings.ini` expandiendo `%SYSTEMROOT%` y `%TEMP%` -> almacena en `$global:Config` -> dot-source de 18 modulos desde `lib/` -> bucle de menu principal con switch de 17 opciones -> cada submenu con do-while y su propio switch -> logging centralizado via `Invoke-Log` con rotacion por `RetentionDays`. Validacion final con las 3 suites de tests (138 tests, 100% pass rate).

- **Archivos creados/modificados**: `README.md` (este archivo)

- **Codigo critico**: Flujo completo de configuracion:
```powershell
# launcher.ps1 lineas 59-65: carga de config
$configFile = Join-Path (Join-Path $ScriptRoot "config") "settings.ini"
$configRaw = & (Join-Path $libDir "Read-Config.ps1") $configFile
$global:Config = ($configRaw -join "`n") | ConvertFrom-Json
```

- **Registro/INI/Env afectados**: `$global:Config` almacena toda la configuracion. `$global:AppVersion = "v5.0"`.

---

## Cierre del Proyecto

### Flujo de ejecucion end-to-end

```
Herramienta Avanzada.bat
  |
  +-- fltmc.exe (verifica admin)
  |     +-- Si no: VBS -> UAC -> reinicia batch elevado
  |
  +-- powershell -NoProfile -ExecutionPolicy Bypass -File launcher.ps1
        |
        +-- UAC elevation (ProcessStartInfo.Verb = "runas")
        +-- Dot-source 18 modulos desde lib/
        +-- Read-Config.ps1 parsea settings.ini -> JSON -> $global:Config
        |     +-- [Environment]::ExpandEnvironmentVariables(%SYSTEMROOT%, %TEMP%)
        |
        +-- Bucle menu principal (do-while)
              +-- switch (1..17) -> Show-*Menu()
                    +-- Cada submenu con do-while y switch interno
                    +-- Funciones compartidas via MenuHelpers.ps1
                    +-- Logging via Invoke-Log (logs/app.log, rotacion configurable)
                    +-- 0 = volver al menu principal
```

### Arbol final del proyecto

```
Herramienta Avanzada/
  Herramienta Avanzada.bat   (45 lineas, entrada via fltmc.exe + VBS UAC)
  launcher.ps1                (152 lineas, orquestador: UAC + carga + menu)
  .gitignore                  (18 lineas)
  publicidad.txt              (17 lineas, release notes)
  config/
    settings.ini              (25 lineas, 3 secciones, 11 claves)
  lib/
    MenuHelpers.ps1           (188 lineas, 10 funciones compartidas)
    Read-Config.ps1           (50 lineas, parser INI -> JSON)
    Maintenance.ps1           (383 lineas, 13 funciones)
    Network.ps1               (183 lineas, 9 funciones)
    SecurityPlus.ps1          (168 lineas, 8 funciones)
    Info.ps1                  (97 lineas, 3 funciones)
    Power.ps1                 (78 lineas, 5 funciones)
    ConfigSys.ps1             (201 lineas, 8 funciones)
    Users.ps1                 (687 lineas, 18 funciones)
    Services.ps1              (168 lineas, 8 funciones)
    Backup.ps1                (221 lineas, 7 funciones)
    Processes.ps1             (178 lineas, 8 funciones)
    Hosts.ps1                 (213 lineas, 8 funciones)
    WiFi.ps1                  (151 lineas, 5 funciones)
    RDP.ps1                   (109 lineas, 5 funciones)
    PowerPlan.ps1             (176 lineas, 7 funciones)
    TaskScheduler.ps1         (148 lineas, 7 funciones)
    WindowsFeatures.ps1       (119 lineas, 5 funciones)
    DriveMapping.ps1          (95 lineas, 4 funciones)
  test/
    Validate-Phase1.ps1       (200 lineas, 10 tests de infraestructura)
    Validate-Phase2.ps1       (166 lineas, 88 tests de modulos)
    Functional-Tests.ps1      (228 lineas, 40 tests funcionales)
```

### Cifras finales

| Metrica | Valor |
|---------|-------|
| Modulos funcionales | 18 |
| Funciones totales | ~80 |
| Lineas de codigo | ~3400 |
| Tests automatizados | 138 (3 suites) |
| Tasa de aprobacion | 100% |
| Archivos .ps1 | 20 |
| Config keys | 11 en 3 secciones |
| Bugs corregidos | 10+ |
| Codigo muerto eliminado | 5 items |
| Encoding normalizado | 100% ASCII |
| Dependencias externas | 0 (solo cmdlets nativos de Windows) |

---

## Anexo: Mapa de archivos del proyecto

Listado completo de archivos con meta-comentario de cada uno. Los contenidos literales estan en los archivos fisicos del repositorio.

| # | Archivo | Rol | Meta-comentario |
|---|---------|-----|-----------------|
| 1 | `launcher.ps1` | Orquestador principal (152 lineas) | UAC elevation via `ProcessStartInfo.Verb = "runas"` (lineas 9-25); carga 18 modulos con dot-source (lineas 28-56); parsea `settings.ini` via `Read-Config.ps1` a `$global:Config` (lineas 59-73); bucle menu con switch de 17 opciones (lineas 122-145) |
| 2 | `config/settings.ini` | Config centralizada (25 lineas) | 3 secciones: `[Paths]` (6 rutas con `%SYSTEMROOT%` y `%TEMP%`), `[Logging]` (Level, RetentionDays), `[Behavior]` (EnableDebugLog, colores hex) |
| 3 | `lib/Read-Config.ps1` | Parser INI -> JSON (50 lineas) | Parametro `[Parameter(Mandatory=$true)]`; identifica secciones `^\[(.+)\]$`; expande variables con `[Environment]::ExpandEnvironmentVariables()`; salida con `ConvertTo-Json` |
| 4 | `lib/MenuHelpers.ps1` | Funciones UI compartidas (188 lineas) | 10 funciones: `Write-Title`, `Write-Menu`, `Read-MenuChoice`, `Read-SecurePassword`, `Read-YesNo`, `Invoke-Log` (con rotacion por RetentionDays), `Get-ConfigValue` (consulta `$global:Config` con fallback al INI), `Get-ScriptDirectory` (usa `Get-PSCallStack`) |
| 5 | `Herramienta Avanzada.bat` | Entry point batch (45 lineas) | Admin check con `fltmc.exe` (linea 6); VBS UAC elevation (lineas 11-14); lanza `powershell -NoProfile -ExecutionPolicy Bypass -File launcher.ps1` (linea 35) |
| 6 | `lib/Maintenance.ps1` | Mantenimiento (383 lineas) | 13 funciones: limpieza temp, SFC, Optimize-Volume, hibernacion (powercfg), CHKDSK con `echo Y |`, restore points (Checkpoint-Computer), WU cache (takeown+icacls), USB eject (Win32_Volume.Dismount), USB mount (Add-PartitionAccessPath) |
| 7 | `lib/Network.ps1` | Red (183 lineas) | 9 funciones: ipconfig, renew/release, port 443 (netstat + findstr), flushdns, netsh int ip reset, adaptadores (Get-NetAdapter con MAC/IP), carpetas compartidas (net share) |
| 8 | `lib/SecurityPlus.ps1` | Seguridad (168 lineas) | 8 funciones: firewall on/off (netsh advfirewall), takeown, icacls con `$env:USERNAME`, Remove-Item -Recurse -Force, proceso completo (takeown + icacls + delete) |
| 9 | `lib/Info.ps1` | Informacion (97 lineas) | 3 funciones: hardware (Win32_ComputerSystem, Win32_Processor, Win32_PhysicalMemory, Win32_DiskDrive via CIM), programas instalados (HKLM:\...\Uninstall) |
| 10 | `lib/Power.ps1` | Energia (78 lineas) | 5 funciones: shutdown /s, reboot /r, logoff /l, lock (rundll32 LockWorkStation), todas con cuenta regresiva |
| 11 | `lib/ConfigSys.ps1` | Config sistema (201 lineas) | 8 funciones: Rename-Computer, Add-Computer -WorkgroupName, Set-CimInstance description, archivos ocultos (HKCU:\...\Explorer\Advanced\Hidden), archivos protegidos (ShowSuperHidden) |
| 12 | `lib/Users.ps1` | Usuarios (687 lineas) | 18 funciones: CRUD usuarios (New/Set/Remove-LocalUser), grupos via SID (`S-1-5-32-544` y `S-1-5-32-545`), contrasenas (Read-SecurePassword), perfiles (Win32_UserProfile), huérfanos |
| 13 | `lib/Services.ps1` | Servicios (168 lineas) | 8 funciones: Start/Stop/Restart-Service, aplicaciones inicio (HKCU:\...\Run) |
| 14 | `lib/Backup.ps1` | Backup drivers (221 lineas) | 7 funciones: Get-ConfigSourcePaths (4 claves del INI), copia Drivers/DriverStore/inf + exporta registry HKLM\...\Control\Class; restaura en mismo o diferente equipo |
| 15 | `lib/Processes.ps1` | Procesos (178 lineas) | 8 funciones: lista, top memoria/CPU, detalle por PID/nombre, kill por PID/nombre con Format-Table personalizado |
| 16 | `lib/Hosts.ps1` | Editor hosts (213 lineas) | 8 funciones: Get-HostsEntries (ignora # y vacios), agregar, eliminar (whitespace-agnostic, 1 entrada), bloquear (0.0.0.0), ver raw, restaurar .bak |
| 17 | `lib/WiFi.ps1` | WiFi (151 lineas) | 5 funciones: netsh wlan show profiles, key=clear (con Select-Object -First 1), export profile XML, delete profile |
| 18 | `lib/RDP.ps1` | RDP (109 lineas) | 5 funciones: Set-ItemProperty fDenyTSConnections (0=on, 1=off), firewall rules bilingues (ES/EN), query user para conexiones activas |
| 19 | `lib/PowerPlan.ps1` | Planes energia (176 lineas) | 7 funciones: Get-PowerPlanGuid con `[regex]::Escape()`, busqueda bilingue ES/EN, powercfg /s y /duplicatescheme con `Select-Object -Last 1` |
| 20 | `lib/TaskScheduler.ps1` | Tareas programadas (148 lineas) | 7 funciones: Get/Start/Disable/Enable/Unregister/Register-ScheduledTask con trigger diario y RunLevel Highest |
| 21 | `lib/WindowsFeatures.ps1` | Caracteristicas Windows (119 lineas) | 5 funciones: Get-WindowsOptionalFeature con `Select-Object -First 50` y `[Math]::Max(0, ...)`, Enable/Disable via DISM |
| 22 | `lib/DriveMapping.ps1` | Unidades red (95 lineas) | 4 funciones: net use con persistencia, net use /delete, Win32_LogicalDisk DriveType=4 |
| 23 | `test/Validate-Phase1.ps1` | Tests infraestructura (200 lineas) | 10 tests: config exists, Read-Config parseo, Invoke-Log funciona, Read-SecurePassword existe, sin set /p en .bat, launcher parseable, 18 modulos existen, Read-Config tiene Mandatory=$true, sin orphan refs, Write-Result con estados |
| 24 | `test/Validate-Phase2.ps1` | Tests modulos (166 lineas) | 88 tests: carga todos modulos con dot-source, verifica existencia, .bat<60 lineas, config 3 secciones, 7 funciones MenuHelpers, 17 Show-*Menu, 18 imports en launcher, parseo sintactico de todos .ps1, Read-Config parsea INI |
| 25 | `test/Functional-Tests.ps1` | Tests funcionales (228 lineas) | 40 tests: carga 18 modulos, 10 funciones base, config keys (BackupSourceDrivers, Level, EnableDebugLog), PowerPlanGuid 3 planes, Get-ScheduledTask, Get-Process, ipconfig, Get-NetAdapter, hosts, RDP registry, netsh wlan, Win32_LogicalDisk, Get-WindowsOptionalFeature, branding, sin colisiones, sin passwords hardcoded, Get-ConfigSourcePaths |
| 26 | `publicidad.txt` | Release notes (17 lineas) | Mejoras v5.0: 100% ASCII, 5 modulos reparados, bugs corregidos, 138 tests, logging centralizado, compatibilidad ES/EN |
| 27 | `.gitignore` | Exclusiones (18 lineas) | logs/, backups/, *.tmp, *.vbs, Thumbs.db, Desktop.ini, *.ps1xml, module.cache |

### Creditoscurso compartido eliminado" "OK"
        Invoke-Log -Message "Recurso compartido $name eliminado"
    } else { Write-Result "Error al eliminar" "ERROR" }
    Pause-Message
}
```

#### 6.3 `lib/SecurityPlus.ps1`

```powershell
    # lib/SecurityPlus.ps1
# Seguridad: firewall, permisos y eliminacion de carpetas

    <#
    .SYNOPSIS
    Menu principal del modulo de seguridad
    #>
function Show-SecurityMenu {
    do {
        Clear-Host
        Write-Title "SEGURIDAD, FIREWALL Y PERMISOS"
        Write-Menu -Options @(
            "  1. Activar Firewall",
            "  2. Desactivar Firewall",
            "  3. Mostrar estado del Firewall",
            "  4. Tomar posesion de una carpeta",
            "  5. Otorgar control total (icacls)",
            "  6. Eliminar una carpeta",
            "  7. Ejecutar todo el proceso",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 7
        switch ($opt) {
            1 { Set-FirewallOn }
            2 { Set-FirewallOff }
            3 { Show-FirewallStatus }
            4 { Invoke-TakeOwnership }
            5 { Invoke-GrantFullControl }
            6 { Invoke-ForceDelete }
            7 { Invoke-FullProcess }
        }
    } while ($opt -ne 0)
}

# === Firewall ===

   <#
   .SYNOPSIS
   Activa el firewall de Windows para todos los perfiles
   #>
function Set-FirewallOn {
    Clear-Host
    Write-Title "ACTIVAR FIREWALL"
    Write-Result "Activando Firewall para todos los perfiles..." "INFO"
    cmd /c "netsh advfirewall set allprofiles state on"
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Firewall activado correctamente" "OK"
        Invoke-Log -Message "Firewall activado"
    } else {
        Write-Result "Error al activar Firewall" "ERROR"
    }
    Pause-Message
}

   <#
   .SYNOPSIS
   Desactiva el firewall de Windows para todos los perfiles
   #>
function Set-FirewallOff {
    Clear-Host
    Write-Title "DESACTIVAR FIREWALL"
    Write-Host "ADVERTENCIA: Desactivar el firewall reduce la seguridad." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Confirmar desactivacion")) { return }
    Write-Result "Desactivando Firewall..." "INFO"
    cmd /c "netsh advfirewall set allprofiles state off"
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Firewall desactivado" "WARN"
        Write-Host "Recuerde activarlo cuando termine." -ForegroundColor Yellow
        Invoke-Log -Message "Firewall desactivado"
    } else {
        Write-Result "Error al desactivar Firewall" "ERROR"
    }
    Pause-Message
}

   <#
   .SYNOPSIS
   Muestra el estado actual de todos los perfiles del firewall
   #>
function Show-FirewallStatus {
    Clear-Host
    Write-Title "ESTADO DEL FIREWALL"
    cmd /c "netsh advfirewall show allprofiles"
    Pause-Message
}

# === Permisos ===

    <#
    .SYNOPSIS
    Toma posesion de archivos o carpetas
    #>
function Invoke-TakeOwnership {
    Clear-Host
    Write-Title "TOMAR POSESION DE CARPETA"
    $path = Read-Host "Ruta completa de la carpeta"
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    if (-not (Test-Path $path)) { Write-Result "Ruta no encontrada" "ERROR"; Pause-Message; return }
    try {
        cmd /c "takeown /f `"$path`" /r" *>$null
        if ($LASTEXITCODE -eq 0) { Write-Result "Posesion tomada correctamente" "OK" }
        else { Write-Result "Error al tomar posesion" "ERROR" }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Otorga control total sobre una carpeta mediante icacls
   #>
function Invoke-GrantFullControl {
    Clear-Host
    Write-Title "OTORGAR CONTROL TOTAL"
    $path = Read-Host "Ruta completa de la carpeta"
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    if (-not (Test-Path $path)) { Write-Result "Ruta no encontrada" "ERROR"; Pause-Message; return }
    try {
        cmd /c "icacls `"$path`" /grant `"$env:USERNAME`:F`" /t /c" *>$null
        if ($LASTEXITCODE -eq 0) { Write-Result "Control total otorgado a $env:USERNAME" "OK" }
        else { Write-Result "Error al otorgar control total" "ERROR" }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Elimina una carpeta de forma forzada con todo su contenido
   #>
function Invoke-ForceDelete {
    Clear-Host
    Write-Title "ELIMINAR CARPETA"
    $path = Read-Host "Ruta completa de la carpeta a eliminar"
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    if (-not (Test-Path $path)) { Write-Result "Ruta no encontrada" "ERROR"; Pause-Message; return }
    Write-Host "ADVERTENCIA: Se eliminara TODO el contenido permanentemente." -ForegroundColor Red
    if (-not (Read-YesNo -Prompt "Confirmar eliminacion")) { return }
    try {
        Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
        Write-Result "Carpeta eliminada correctamente" "OK"
        Invoke-Log -Message "Carpeta eliminada: $path"
    } catch { Write-Result "Error al eliminar: $_" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Ejecuta toma de posesion, control total y eliminacion de carpeta
   #>
function Invoke-FullProcess {
    Clear-Host
    Write-Title "PROCESO COMPLETO (Toma + Control + Eliminar)"
    $path = Read-Host "Ruta completa de la carpeta"
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    if (-not (Test-Path $path)) { Write-Result "Ruta no encontrada" "ERROR"; Pause-Message; return }
    Write-Result "Tomando posesion..." "INFO"
    cmd /c "takeown /f `"$path`" /r" *>$null
    if ($LASTEXITCODE -ne 0) { Write-Result "Error en takeown" "ERROR"; Pause-Message; return }
    Write-Result "Otorgando control total..." "INFO"
    cmd /c "icacls `"$path`" /grant `"$env:USERNAME`:F`" /t /c" *>$null
    if ($LASTEXITCODE -ne 0) { Write-Result "Error en icacls" "ERROR"; Pause-Message; return }
    Write-Host "ADVERTENCIA: Se eliminara TODO el contenido permanentemente." -ForegroundColor Red
    if (-not (Read-YesNo -Prompt "Confirmar eliminacion")) { return }
    Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
    Write-Result "Proceso completado - Carpeta eliminada" "OK"
    Invoke-Log -Message "Proceso completo de eliminacion: $path"
    Pause-Message
}
```

#### 6.4 `lib/Info.ps1`

```powershell
    # lib/Info.ps1
# Informacion del sistema

    <#
    .SYNOPSIS
    Menu principal del modulo de informacion
    #>
function Show-InfoMenu {
    do {
        Clear-Host
        Write-Title "INFORMACION DEL SISTEMA"
        Write-Menu -Options @(
            "  1. Informacion de hardware",
            "  2. Programas instalados",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { Show-HardwareInfo }
            2 { Show-InstalledPrograms }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra informacion detallada del hardware
    #>
function Show-HardwareInfo {
    Clear-Host
    Write-Title "INFORMACION DE HARDWARE"
    try {
        Write-Result "Recopilando informacion del sistema..." "INFO"
        $cs = Get-CimInstance Win32_ComputerSystem
        $os = Get-CimInstance Win32_OperatingSystem
        $bios = Get-CimInstance Win32_BIOS
        $cpu = Get-CimInstance Win32_Processor
        $mem = Get-CimInstance Win32_PhysicalMemory
        $disk = Get-CimInstance Win32_DiskDrive
        Write-Host "=== SISTEMA ===" -ForegroundColor Cyan
        Write-Host "  Hostname      : $($cs.Name)"
        Write-Host "  Fabricante    : $($cs.Manufacturer)"
        Write-Host "  Modelo        : $($cs.Model)"
        Write-Host "  Tipo          : $($cs.SystemType)"
        Write-Host "  RAM Total     : $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB"
        Write-Host "`n=== SISTEMA OPERATIVO ===" -ForegroundColor Cyan
        Write-Host "  SO            : $($os.Caption)"
        Write-Host "  Version       : $($os.Version)"
        Write-Host "  Build         : $($os.BuildNumber)"
        Write-Host "  Instalado     : $($os.InstallDate)"
        Write-Host "`n=== BIOS ===" -ForegroundColor Cyan
        Write-Host "  Version       : $($bios.SMBIOSBIOSVersion)"
        Write-Host "  Fabricante    : $($bios.Manufacturer)"
        Write-Host "`n=== PROCESADOR ===" -ForegroundColor Cyan
        Write-Host "  CPU           : $($cpu.Name)"
        Write-Host "  Nucleos       : $($cpu.NumberOfCores)"
        Write-Host "  Logicos       : $($cpu.NumberOfLogicalProcessors)"
        Write-Host "`n=== MEMORIA RAM ===" -ForegroundColor Cyan
        foreach ($m in $mem) {
            Write-Host "  $([math]::Round($m.Capacity/1GB,2)) GB - $($m.Speed) MHz - $($m.DeviceLocator)"
        }
        Write-Host "`n=== DISCOS ===" -ForegroundColor Cyan
        foreach ($d in $disk) {
            Write-Host "  $($d.Model) - $([math]::Round($d.Size/1GB,2)) GB - $($d.SerialNumber)"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

   <#
   .SYNOPSIS
   Muestra la lista de programas instalados en el sistema
   #>
function Show-InstalledPrograms {
    Clear-Host
    Write-Title "PROGRAMAS INSTALADOS"
    try {
        Write-Result "Obteniendo lista..." "INFO"
        $programs = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' 2>$null |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Sort-Object DisplayName
        if ($programs) {
            $programs | Format-Table DisplayName, DisplayVersion, Publisher -AutoSize -Wrap
            Write-Host "`nTotal: $($programs.Count) programas" -ForegroundColor Cyan
        } else {
            Write-Result "No se encontraron programas" "INFO"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}
```

#### 6.5 `lib/Power.ps1`

```powershell
    # lib/Power.ps1
# Apagar, Reiniciar, Bloqueo, Cerrar Sesion

    <#
    .SYNOPSIS
    Menu principal del modulo de energia
    #>
function Show-PowerMenu {
    do {
        Clear-Host
        Write-Title "APAGAR / REINICIAR / BLOQUEO"
        Write-Menu -Options @(
            "  1. Apagar el sistema",
            "  2. Reiniciar el sistema",
            "  3. Cerrar sesion",
            "  4. Bloquear pantalla",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Invoke-Shutdown }
            2 { Invoke-Reboot }
            3 { Invoke-Logoff }
            4 { Invoke-Lock }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Apaga el equipo con cuenta regresiva
    #>
function Invoke-Shutdown {
    Clear-Host
    Write-Title "APAGAR SISTEMA"
    if (-not (Read-YesNo -Prompt "Desea apagar el sistema")) { return }
    Write-Result "Apagando en 5 segundos..." "WARN"
    cmd /c "shutdown /s /t 5 /c `"Apagado iniciado desde Herramienta Avanzada`""
    exit
}

    <#
    .SYNOPSIS
    Reinicia el equipo con cuenta regresiva
    #>
function Invoke-Reboot {
    Clear-Host
    Write-Title "REINICIAR SISTEMA"
    if (-not (Read-YesNo -Prompt "Desea reiniciar el sistema")) { return }
    Write-Result "Reiniciando en 5 segundos..." "WARN"
    cmd /c "shutdown /r /t 5 /c `"Reinicio iniciado desde Herramienta Avanzada`""
    exit
}

    <#
    .SYNOPSIS
    Cierra la sesion actual
    #>
function Invoke-Logoff {
    Clear-Host
    Write-Title "CERRAR SESION"
    if (-not (Read-YesNo -Prompt "Desea cerrar la sesion")) { return }
    Write-Result "Cerrando sesion..." "WARN"
    cmd /c "shutdown /l"
    exit
}

    <#
    .SYNOPSIS
    Bloquea la sesion actual
    #>
function Invoke-Lock {
    Clear-Host
    Write-Title "BLOQUEAR PANTALLA"
    Write-Result "Bloqueando..." "INFO"
    cmd /c "rundll32.exe user32.dll,LockWorkStation"
}
```

#### 6.6 `lib/ConfigSys.ps1`

```powershell
    # lib/ConfigSys.ps1
# Configuracion del equipo: nombre, grupo de trabajo, descripcion, archivos ocultos

    <#
    .SYNOPSIS
    Menu principal de configuracion del sistema
    #>
function Show-ConfigSysMenu {
    do {
        Clear-Host
        Write-Title "CONFIGURACION DEL EQUIPO"
        Write-Menu -Options @(
            "  1. Ver informacion actual del equipo",
            "  2. Cambiar nombre del equipo",
            "  3. Cambiar grupo de trabajo",
            "  4. Cambiar descripcion del equipo",
            "  5. Mostrar/Ocultar elementos ocultos",
            "  6. Archivos protegidos del sistema",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 { Show-ComputerInfo }
            2 { Set-ComputerName }
            3 { Set-Workgroup }
            4 { Set-ComputerDescription }
            5 { Toggle-HiddenFiles }
            6 { Invoke-ProtectedFilesMenu }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra la informacion actual del equipo
    #>
function Show-ComputerInfo {
    Clear-Host
    Write-Title "INFORMACION ACTUAL DEL EQUIPO"
    try {
        $cs = Get-CimInstance Win32_ComputerSystem
        Write-Host "Nombre del equipo : $($cs.Name)" -ForegroundColor Cyan
        Write-Host "Grupo de trabajo  : $($cs.Workgroup)" -ForegroundColor Cyan
        Write-Host "Descripcion       : $($cs.Description)" -ForegroundColor Cyan
        Write-Host "Fabricante        : $($cs.Manufacturer)" -ForegroundColor Gray
        Write-Host "Modelo            : $($cs.Model)" -ForegroundColor Gray
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Cambia el nombre del equipo
    #>
function Set-ComputerName {
    Clear-Host
    Write-Title "CAMBIAR NOMBRE DEL EQUIPO"
    Write-Host "Nombre actual: " -NoNewline; Write-Host "$env:COMPUTERNAME" -ForegroundColor Cyan
    $newName = Read-Host "`nNuevo nombre del equipo"
    if ([string]::IsNullOrWhiteSpace($newName)) { return }
    Write-Host "ADVERTENCIA: Cambiar el nombre requiere reinicio." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Confirmar cambio a '$newName'")) { return }
    try {
        Rename-Computer -NewName $newName -ErrorAction Stop
        Write-Result "Nombre cambiado a '$newName'" "OK"
        Write-Host "Es necesario reiniciar para aplicar cambios." -ForegroundColor Yellow
        if (Read-YesNo -Prompt "Reiniciar ahora") {
            cmd /c "shutdown /r /t 10 /c `"Reinicio para aplicar nuevo nombre`""
            exit
        }
        Invoke-Log -Message "Nombre de equipo cambiado a $newName"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Cambia el grupo de trabajo del equipo
    #>
function Set-Workgroup {
    Clear-Host
    Write-Title "CAMBIAR GRUPO DE TRABAJO"
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "Grupo actual: " -NoNewline; Write-Host "$($cs.Workgroup)" -ForegroundColor Cyan
    $newGroup = Read-Host "`nNuevo grupo de trabajo"
    if ([string]::IsNullOrWhiteSpace($newGroup)) { return }
    Write-Host "ADVERTENCIA: Cambiar el grupo requiere reinicio." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Confirmar cambio a '$newGroup'")) { return }
    try {
        Add-Computer -WorkgroupName $newGroup -ErrorAction Stop
        Write-Result "Grupo cambiado a '$newGroup'" "OK"
        if (Read-YesNo -Prompt "Reiniciar ahora") {
            cmd /c "shutdown /r /t 10 /c `"Reinicio para aplicar grupo de trabajo`""
            exit
        }
        Invoke-Log -Message "Grupo de trabajo cambiado a $newGroup"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Cambia la descripcion del equipo
    #>
function Set-ComputerDescription {
    Clear-Host
    Write-Title "CAMBIAR DESCRIPCION DEL EQUIPO"
    $cs = Get-CimInstance Win32_ComputerSystem
    Write-Host "Descripcion actual: " -NoNewline; Write-Host "$($cs.Description)" -ForegroundColor Cyan
    $newDesc = Read-Host "`nNueva descripcion"
    if ([string]::IsNullOrWhiteSpace($newDesc)) { return }
    try {
        $cs | Set-CimInstance -Property @{ Description = $newDesc } -ErrorAction Stop
        Write-Result "Descripcion actualizada" "OK"
        Write-Host "No requiere reinicio." -ForegroundColor Green
        Invoke-Log -Message "Descripcion del equipo cambiada a $newDesc"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

# Funciones de archivos ocultos (fusionadas desde HiddenFiles.ps1)

    <#
    .SYNOPSIS
    Alterna entre mostrar y ocultar archivos ocultos
    #>
function Toggle-HiddenFiles {
    Clear-Host
    Write-Title "MOSTRAR/OCULTAR ELEMENTOS OCULTOS"
    try {
        $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        $current = (Get-ItemProperty -Path $key -Name Hidden -ErrorAction Stop).Hidden
        if ($current -eq 0) {
            Set-ItemProperty -Path $key -Name Hidden -Value 1
            Write-Result "Mostrando archivos ocultos" "OK"
        } else {
            Set-ItemProperty -Path $key -Name Hidden -Value 0
            Write-Result "Ocultando archivos ocultos" "OK"
        }
        $null = cmd /c "taskkill /f /im explorer.exe" 2>&1; Start-Process explorer.exe
        Write-Result "Explorador reiniciado para aplicar cambios" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Menu para mostrar u ocultar archivos protegidos del sistema
    #>
function Invoke-ProtectedFilesMenu {
    do {
        Clear-Host
        Write-Title "ARCHIVOS PROTEGIDOS DEL SISTEMA"
        Write-Menu -Options @(
            "  1. Ocultar archivos protegidos",
            "  2. Mostrar archivos protegidos",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { Hide-ProtectedFiles }
            2 { Show-ProtectedFiles }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Oculta los archivos protegidos del sistema
    #>
function Hide-ProtectedFiles {
    Clear-Host
    Write-Title "OCULTAR ARCHIVOS PROTEGIDOS"
    try {
        $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty -Path $key -Name ShowSuperHidden -Value 0 -ErrorAction Stop
        $null = cmd /c "taskkill /f /im explorer.exe" 2>&1; Start-Process explorer.exe
        Write-Result "Archivos protegidos ocultos" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra los archivos protegidos del sistema
    #>
function Show-ProtectedFiles {
    Clear-Host
    Write-Title "MOSTRAR ARCHIVOS PROTEGIDOS"
    try {
        $key = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty -Path $key -Name Hidden -Value 1 -ErrorAction Stop
        Set-ItemProperty -Path $key -Name ShowSuperHidden -Value 1 -ErrorAction Stop
        $null = cmd /c "taskkill /f /im explorer.exe" 2>&1; Start-Process explorer.exe
        Write-Result "Archivos protegidos visibles" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}
```

#### 6.7 `lib/Users.ps1`

```powershell
    # lib/Users.ps1
# Administracion de cuentas de usuario, grupos y contrasenas

    <#
    .SYNOPSIS
    Menu principal de administracion de usuarios
    #>
function Show-UsersMenu {
    do {
        Clear-Host
        Write-Title "ADMINISTRACION DE CUENTAS DE USUARIO"
    Write-Menu -Options @(
            "  1. Listar usuarios del sistema",
            "  2. Crear nueva cuenta de usuario",
            "  3. Modificar cuenta de usuario existente",
            "  4. Eliminar cuenta de usuario",
            "  5. Administrar permisos de usuario (grupos)",
            "  6. Gestion de contrasenas",
            "  7. Cambiar contrasena de usuario actual",
            "  8. Gestion de perfiles de usuario",
            "  0. Volver al menu principal"
        )
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 8
    switch ($opt) {
        1 { Show-UserList }
        2 { New-UserAccount }
        3 { Edit-UserAccount }
        4 { Remove-UserAccount }
        5 { Show-PermissionsMenu }
        6 { Show-PasswordMenu }
        7 { Set-CurrentUserPassword }
        8 { Show-ProfileMenu }
    }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra lista de usuarios del sistema
    #>
function Show-UserList {
    Clear-Host
    Write-Title "USUARIOS DEL SISTEMA"
    try {
        $users = Get-LocalUser | Sort-Object Name
        Write-Host "`nUsuarios locales:" -ForegroundColor Cyan
        $users | Format-Table Name, FullName, Enabled, LastLogon, PasswordLastSet, Description -AutoSize -Wrap
        $detailUser = Read-Host "`nVer detalles de un usuario (ENTER para volver)"
        if (-not [string]::IsNullOrWhiteSpace($detailUser)) {
            $user = Get-LocalUser -Name $detailUser -ErrorAction SilentlyContinue
            if ($user) {
                $user | Format-List Name, FullName, Description, Enabled, PasswordLastSet, LastLogon, SID
                $groups = Get-LocalGroup | Where-Object { $_.Description -notlike "*@microsoft*" }
                Write-Host "`nGrupos a los que pertenece:" -ForegroundColor Cyan
                foreach ($g in $groups) {
                    $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
                    if ($members.Name -contains "$env:COMPUTERNAME\$detailUser") {
                        Write-Host "  - $($g.Name)" -ForegroundColor Green
                    }
                }
            } else {
                Write-Result "Usuario no encontrado" "WARN"
            }
            Pause-Message
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
        Pause-Message
    }
}

    <#
    .SYNOPSIS
    Crea una nueva cuenta de usuario local
    #>
function New-UserAccount {
    Clear-Host
    Write-Title "CREAR NUEVA CUENTA DE USUARIO"
    $userName = Read-Host "Nombre de usuario"
    if ([string]::IsNullOrWhiteSpace($userName)) { return }
    if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
        Write-Result "El usuario ya existe" "ERROR"
        Pause-Message; return
    }
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $pass1 = Read-SecurePassword "Contrasena"
    if ([string]::IsNullOrWhiteSpace($pass1)) {
        Write-Result "La contrasena no puede estar vacia" "ERROR"
        Pause-Message; return
    }
    $pass2 = Read-SecurePassword "Confirmar contrasena"
    if ($pass1 -ne $pass2) {
        Write-Result "Las contrasenas no coinciden" "ERROR"
        Pause-Message; return
    }
    $isAdmin = Read-YesNo -Prompt "Agregar al grupo Administradores" -Default "N"
    try {
        $secPass = ConvertTo-SecureString $pass1 -AsPlainText -Force
        New-LocalUser -Name $userName -Password $secPass -PasswordNeverExpires -ErrorAction Stop
        if ($isAdmin) {
            $adminGroup = Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-544' }
            if ($adminGroup) { Add-LocalGroupMember -Group $adminGroup.Name -Member $userName -ErrorAction Stop }
        }
        Invoke-Log -Message "Usuario $userName creado (admin: $isAdmin)"
        Write-Result "Usuario $userName creado exitosamente" "OK"
        if ($isAdmin) { Write-Result "  Miembro de Administradores" "OK" }
    } catch {
        Write-Result "Error al crear usuario: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Creacion de usuario $userName fallo: $_"
    }
    $pass1 = $null; $pass2 = $null
    Pause-Message
}

    <#
    .SYNOPSIS
    Modifica propiedades de una cuenta de usuario
    #>
function Edit-UserAccount {
    Clear-Host
    Write-Title "MODIFICAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $modUser = Read-Host "`nNombre de usuario a modificar"
    if ([string]::IsNullOrWhiteSpace($modUser)) { return }
    $user = Get-LocalUser -Name $modUser -ErrorAction SilentlyContinue
    if (-not $user) { Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return }
    do {
        Clear-Host
        Write-Subtitle "MODIFICAR: $modUser"
        Write-Menu -Options @(
            "  1. Cambiar nombre completo",
            "  2. Activar/Desactivar cuenta",
            "  3. Forzar cambio de contrasena en proximo inicio",
            "  4. Cambiar fecha de caducidad de contrasena",
            "  5. Cambiar descripcion",
            "  6. Cambiar ruta del perfil",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 {
                $fullname = Read-Host "Nuevo nombre completo"
                Set-LocalUser -Name $modUser -FullName $fullname -ErrorAction Stop
                Write-Result "Nombre completo actualizado" "OK"
                Pause-Message
            }
            2 {
                $users | Format-Table Name, Enabled -AutoSize
                $enable = Read-YesNo -Prompt "Habilitar cuenta"
                try {
                    Set-LocalUser -Name $modUser -Enabled $enable -ErrorAction Stop
                    Write-Result "Cuenta actualizada (habilitada: $enable)" "OK"
                } catch { Write-Result "Error al actualizar cuenta: $_" "ERROR" }
                Pause-Message
            }
            3 {
                $forceChange = Read-YesNo -Prompt "Forzar cambio de contrasena al iniciar sesion"
                try {
                    Set-LocalUser -Name $modUser -PasswordExpires $forceChange -ErrorAction Stop
                    Write-Result "Configuracion actualizada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            4 {
                Write-Host "  1. Nunca caduca"
                Write-Host "  2. Establecer fecha"
                $expOpt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
                try {
                    if ($expOpt -eq 1) {
                        Set-LocalUser -Name $modUser -AccountExpires $null -ErrorAction Stop
                    } else {
                        $expDate = Read-Host "Fecha (YYYY-MM-DD)"
                        Set-LocalUser -Name $modUser -AccountExpires (Get-Date $expDate) -ErrorAction Stop
                    }
                    Write-Result "Fecha de caducidad configurada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            5 {
                $desc = Read-Host "Nueva descripcion"
                try {
                    Set-LocalUser -Name $modUser -Description $desc -ErrorAction Stop
                    Write-Result "Descripcion actualizada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            6 {
                $profilePath = Read-Host "Nueva ruta del perfil (ej. C:\Users\NuevoPerfil)"
                try {
                    $u = Get-CimInstance Win32_UserAccount -Filter "Name='$modUser'"
                    if ($u) {
                        Set-CimInstance -InputObject $u -Property @{ ProfilePath = $profilePath } -ErrorAction Stop
                        Write-Result "Ruta de perfil actualizada" "OK"
                    }
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Elimina una cuenta de usuario local
    #>
function Remove-UserAccount {
    Clear-Host
    Write-Title "ELIMINAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $delUser = Read-Host "`nNombre de usuario a eliminar"
    if ([string]::IsNullOrWhiteSpace($delUser)) { return }
    $currentUser = $env:USERNAME
    if ($currentUser -eq $delUser) {
        Write-Result "No puede eliminar el usuario con sesion activa" "ERROR"
        Pause-Message; return
    }
    Write-Host "ADVERTENCIA: Esta accion eliminara permanentemente la cuenta." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Confirmar eliminacion de '$delUser'")) { return }
    $keepFiles = Read-YesNo -Prompt "Conservar archivos del perfil (C:\Users\$delUser)" -Default "S"
    try {
        Remove-LocalUser -Name $delUser -ErrorAction Stop
        if (-not $keepFiles) {
            $profilePath = "C:\Users\$delUser"
            if (Test-Path $profilePath) {
                Write-Result "Eliminando carpeta de perfil..." "INFO"
                cmd /c "rmdir /s /q `"$profilePath`"" *>$null
            }
            $profile = Get-CimInstance Win32_UserProfile -Filter "LocalPath='$profilePath'" -ErrorAction SilentlyContinue
            if ($profile) {
                Remove-CimInstance -InputObject $profile -ErrorAction SilentlyContinue
            }
        }
        Invoke-Log -Message "Usuario $delUser eliminado (keepFiles: $keepFiles)"
        Write-Result "Usuario $delUser eliminado correctamente" "OK"
        if ($keepFiles) { Write-Host "  Archivos del perfil conservados en C:\Users\$delUser" -ForegroundColor Gray }
    } catch {
        Write-Result "Error al eliminar: $_" "ERROR"
        Write-Host "Cierre sesiones activas e intente nuevamente" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Menu de administracion de grupos y permisos
    #>
function Show-PermissionsMenu {
    Clear-Host
    Write-Title "ADMINISTRAR PERMISOS DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name -AutoSize
    $permUser = Read-Host "`nNombre de usuario para modificar permisos"
    if ([string]::IsNullOrWhiteSpace($permUser)) { return }
    $user = Get-LocalUser -Name $permUser -ErrorAction SilentlyContinue
    if (-not $user) { Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return }
    do {
        Clear-Host
        Write-Subtitle "PERMISOS DE: $permUser"
        Write-Host "Grupos actuales:" -ForegroundColor Cyan
        $groups = Get-LocalGroup | Where-Object { $_.Description -notlike "*@microsoft*" }
        foreach ($g in $groups) {
            $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
            if ($members.Name -contains "$env:COMPUTERNAME\$permUser") {
                Write-Host "  - $($g.Name)" -ForegroundColor Green
            }
        }
        Write-Menu -Options @(
            "  1. Agregar a grupo",
            "  2. Quitar de grupo",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 {
                $groupsAvail = Get-LocalGroup | Sort-Object Name
                $groupsAvail | Format-Table Name, Description -AutoSize
                $addGroup = Read-Host "Nombre del grupo"
                try {
                    $members = Get-LocalGroupMember -Group $addGroup -ErrorAction Stop
                    if ($members.Name -contains "$env:COMPUTERNAME\$permUser") {
                        Write-Result "El usuario ya es miembro de '$addGroup'" "WARN"
                    } else {
                        Add-LocalGroupMember -Group $addGroup -Member $permUser -ErrorAction Stop
                        Write-Result "Usuario agregado a '$addGroup'" "OK"
                        Invoke-Log -Message "$permUser agregado al grupo $addGroup"
                    }
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            2 {
                $groupsOf = @()
                $allGroups = Get-LocalGroup | Sort-Object Name
                foreach ($g in $allGroups) {
                    $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
                    if ($members.Name -contains "$env:COMPUTERNAME\$permUser") { $groupsOf += $g.Name }
                }
                if ($groupsOf.Count -eq 0) { Write-Result "Usuario no pertenece a ningun grupo" "INFO"; Pause-Message; break }
                Write-Host "Grupos: $($groupsOf -join ', ')" -ForegroundColor Cyan
                $remGroup = Read-Host "Nombre del grupo del que quitar"
                $usersGroup = Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-545' }
                if ($remGroup -eq $usersGroup.Name) {
                    if (-not (Read-YesNo -Prompt "Quitar del grupo $($usersGroup.Name) puede causar problemas. Continuar")) { break }
                }
                try {
                    Remove-LocalGroupMember -Group $remGroup -Member $permUser -ErrorAction Stop
                    Write-Result "Usuario quitado de '$remGroup'" "OK"
                    Invoke-Log -Message "$permUser quitado del grupo $remGroup"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Menu de gestion de contrasenas
    #>
function Show-PasswordMenu {
    do {
        Clear-Host
        Write-Title "GESTION DE CONTRASENAS"
        Write-Menu -Options @(
            "  1. Resetear contrasena de usuario",
            "  2. Establecer politica de contrasenas",
            "  3. Ver contrasenas almacenadas",
            "  4. Desbloquear cuenta de usuario",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Reset-UserPassword }
            2 { Set-PasswordPolicy }
            3 { Show-StoredCredentials }
            4 { Unlock-UserAccount }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Resetea la contrasena de un usuario
    #>
function Reset-UserPassword {
    Clear-Host
    Write-Title "RESETEAR CONTRASENA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name -AutoSize
    $resetUser = Read-Host "`nNombre de usuario"
    if ([string]::IsNullOrWhiteSpace($resetUser)) { return }
    if (-not (Get-LocalUser -Name $resetUser -ErrorAction SilentlyContinue)) {
        Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return
    }
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $newPass = Read-SecurePassword "Nueva contrasena"
    try {
        $secPass = ConvertTo-SecureString $newPass -AsPlainText -Force
        Set-LocalUser -Name $resetUser -Password $secPass -ErrorAction Stop
        Invoke-Log -Message "Contrasena reseteada para $resetUser"
        Write-Result "Contrasena cambiada correctamente para $resetUser" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Reset password para $resetUser fallo: $_"
    }
    $newPass = $null
    Pause-Message
}

    <#
    .SYNOPSIS
    Configura la politica de contrasenas local
    #>
function Set-PasswordPolicy {
    Clear-Host
    Write-Title "POLITICA DE CONTRASENAS (LOCAL)"
    try {
        $policy = net accounts 2>$null
        $policy | Select-String -Pattern "Longitud|Edad|Historial|vigencia|caracteres" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    } catch {}
    Write-Menu -Options @(
        "  1. Longitud minima de contrasena (0-14)",
        "  2. Edad maxima de contrasena (dias)",
        "  3. Historial de contrasenas (0-24)",
        "  0. Volver"
    )
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 3
    switch ($opt) {
        1 {
            do { $len = Read-Host "Longitud minima (0-14)" } while ($len -notmatch '^\d+$' -or [int]$len -lt 0 -or [int]$len -gt 14)
            cmd /c "net accounts /minpwlen:$len >nul"
            Write-Result "Longitud minima establecida a $len" "OK"
            Invoke-Log -Message "Password min length set to $len"
            Pause-Message
        }
        2 {
            do { $age = Read-Host "Edad maxima en dias (0=nunca)" } while ($age -notmatch '^\d+$')
            cmd /c "net accounts /maxpwage:$age >nul"
            Write-Result "Edad maxima establecida a $age dias" "OK"
            Invoke-Log -Message "Password max age set to $age"
            Pause-Message
        }
        3 {
            do { $hist = Read-Host "Historial (0-24)" } while ($hist -notmatch '^\d+$' -or [int]$hist -lt 0 -or [int]$hist -gt 24)
            cmd /c "net accounts /uniquepw:$hist >nul"
            Write-Result "Historial establecido a $hist" "OK"
            Invoke-Log -Message "Password history set to $hist"
            Pause-Message
        }
    }
}

    <#
    .SYNOPSIS
    Muestra credenciales almacenadas en el sistema
    #>
function Show-StoredCredentials {
    Clear-Host
    Write-Title "CONTRASENAS ALMACENADAS"
    Write-Host "Mostrando credenciales almacenadas en el sistema..." -ForegroundColor Cyan
    cmdkey /list
    Write-Host "`nNota: Las contrasenas de cuentas locales no son recuperables directamente." -ForegroundColor Yellow
    Pause-Message
}

    <#
    .SYNOPSIS
    Desbloquea una cuenta de usuario
    #>
function Unlock-UserAccount {
    Clear-Host
    Write-Title "DESBLOQUEAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $unlockUser = Read-Host "`nNombre de usuario a desbloquear"
    if ([string]::IsNullOrWhiteSpace($unlockUser)) { return }
    try {
        $user = Get-LocalUser -Name $unlockUser -ErrorAction Stop
        net user $unlockUser /active:yes *>$null
        if ($LASTEXITCODE -eq 0) {
            Invoke-Log -Message "Cuenta $unlockUser desbloqueada"
            Write-Result "Cuenta desbloqueada correctamente" "OK"
        } else {
            Write-Result "Error al desbloquear cuenta" "ERROR"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Cambia la contrasena del usuario actual
    #>
function Set-CurrentUserPassword {
    Clear-Host
    Write-Title "CAMBIAR CONTRASENA DE USUARIO ACTUAL"
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $currentUser = $env:USERNAME
    $newPass1 = Read-SecurePassword "Nueva contrasena"
    $newPass2 = Read-SecurePassword "Confirmar nueva contrasena"
    if ($newPass1 -ne $newPass2) {
        Write-Result "Las contrasenas no coinciden" "ERROR"
        Pause-Message; return
    }
    try {
        $secPass = ConvertTo-SecureString $newPass1 -AsPlainText -Force
        Set-LocalUser -Name $currentUser -Password $secPass -ErrorAction Stop
        net user "$currentUser" "$newPass1" /logonpasswordchg:yes *>$null
        Invoke-Log -Message "Contrasena cambiada para $currentUser"
        Write-Result "Contrasena cambiada correctamente" "OK"
    } catch {
        Write-Result "Error al cambiar contrasena: $_" "ERROR"
    }
    $newPass1 = $null; $newPass2 = $null
    Pause-Message
}

# ============================================================
# GESTION DE PERFILES DE USUARIO (Win32_UserProfile)
# ============================================================

    <#
    .SYNOPSIS
    Menu de gestion de perfiles de usuario
    #>
function Show-ProfileMenu {
    do {
        Clear-Host
        Write-Title "PERFILES DE USUARIO"
        Write-Menu -Options @(
            "  1. Listar perfiles de usuario",
            "  2. Ver detalle de un perfil",
            "  3. Eliminar perfil de usuario",
            "  4. Eliminar perfiles huerfanos",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Show-ProfileList }
            2 { Show-ProfileDetail }
            3 { Remove-UserProfile }
            4 { Remove-OrphanProfiles }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Calcula el tamano de un perfil de usuario
    #>
function Get-ProfileSize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "N/A" }
    try {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if (-not $size) { return "0 B" }
        if ($size -gt 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
        if ($size -gt 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
        return "{0:N2} KB" -f ($size / 1KB)
    } catch { return "Error" }
}

    <#
    .SYNOPSIS
    Lista todos los perfiles de usuario
    #>
function Show-ProfileList {
    Clear-Host
    Write-Title "PERFILES DE USUARIO"
    try {
        $profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop
        if (-not $profiles) { Write-Result "No se encontraron perfiles" "WARN"; Pause-Message; return }
        $users = Get-LocalUser
        Write-Host "Total: $($profiles.Count) perfiles`n" -ForegroundColor Gray
        $profiles | Sort-Object LastUseTime -Descending | ForEach-Object {
            $sid = $_.SID
            $userName = "N/A"
            $localPath = $_.LocalPath
            $loaded = if ($_.Loaded) { "SI" } else { "NO" }
            $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
            $size = Get-ProfileSize -Path $localPath
            try {
                $account = $users | Where-Object { $_.SID.Value -eq $sid } | Select-Object -First 1
                if ($account) { $userName = $account.Name }
                else { $userName = "HUERFANO" }
            } catch {}
            Write-Host ("{0,-20} {1,-12} {2,-5} {3,-12} {4}" -f $userName, $size, $loaded, $lastUse, $localPath)
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra detalle de un perfil de usuario
    #>
function Show-ProfileDetail {
    Clear-Host
    Write-Title "DETALLE DE PERFIL"
    $target = Read-Host "`nNombre de usuario o ruta del perfil"
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    try {
        $filter = "LocalPath LIKE '%$target%' OR SID='$target'"
        $profile = Get-CimInstance Win32_UserProfile -Filter $filter -ErrorAction SilentlyContinue
        if (-not $profile) {
            $profile = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { $_.SID -eq $target -or $_.LocalPath -like "*$target*" } | Select-Object -First 1
        }
        if (-not $profile) { Write-Result "Perfil no encontrado" "WARN"; Pause-Message; return }
        Write-Host "`nRuta:       $($profile.LocalPath)" -ForegroundColor White
        Write-Host "SID:        $($profile.SID)" -ForegroundColor White
        Write-Host "Cargado:    $(if ($profile.Loaded) { 'SI' } else { 'NO' })" -ForegroundColor $(if ($profile.Loaded) { 'Green' } else { 'Gray' })
        if ($profile.LastUseTime) {
            Write-Host "Ultimo uso: $($profile.LastUseTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor White
        }
        Write-Host "Tamanio:    $(Get-ProfileSize $profile.LocalPath)" -ForegroundColor White
        if ($profile.RoamingPreference) {
            Write-Host "Itinerante: $($profile.RoamingPreference)" -ForegroundColor White
        }
        try {
            $owner = Get-WmiObject Win32_UserAccount -Filter "SID='$($profile.SID)'" -ErrorAction SilentlyContinue
            if ($owner) { Write-Host "Cuenta:     $($owner.Name)" -ForegroundColor Green }
            else { Write-Host "Cuenta:     HUERFANA (sin usuario asociado)" -ForegroundColor Red }
        } catch {}
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina un perfil de usuario
    #>
function Remove-UserProfile {
    Clear-Host
    Write-Title "ELIMINAR PERFIL DE USUARIO"
    $profiles = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue
    if (-not $profiles) { Write-Result "No se encontraron perfiles" "WARN"; Pause-Message; return }
    $profiles | Sort-Object LastUseTime -Descending | ForEach-Object {
        $localPath = $_.LocalPath
        $sid = $_.SID
        $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
        try {
            $account = Get-LocalUser | Where-Object { $_.SID.Value -eq $sid } | Select-Object -First 1
            $userName = if ($account) { $account.Name } else { "HUERFANO" }
        } catch { $userName = $sid }
        Write-Host ("  {0,-20} Ultimo uso: {1}" -f $userName, $lastUse)
    }
    $delProfile = Read-Host "`nNombre de usuario o ruta del perfil a eliminar"
    if ([string]::IsNullOrWhiteSpace($delProfile)) { return }
    $sidMatch = whoami /user 2>$null | Select-String "S-1-5-21-[0-9-]+"
    $currentSID = if ($sidMatch) { $sidMatch.Matches.Value } else { $null }
    try {
        $target = $profiles | Where-Object { $_.LocalPath -like "*$delProfile*" -or $_.SID -eq $delProfile } | Select-Object -First 1
        if (-not $target) { Write-Result "Perfil no encontrado" "ERROR"; Pause-Message; return }
        if ($target.SID -eq $currentSID) {
            Write-Result "No puede eliminar el perfil de la sesion activa" "ERROR"
            Pause-Message; return
        }
        if ($target.Loaded) {
            Write-Result "El perfil esta cargado. Cierre sesion del usuario e intente nuevamente." "WARN"
            Pause-Message; return
        }
        $folderName = Split-Path $target.LocalPath -Leaf
        Write-Host "`nSe eliminara: $folderName ($($target.LocalPath))" -ForegroundColor Yellow
        if (-not (Read-YesNo -Prompt "Confirmar eliminacion")) { return }
        if (Test-Path $target.LocalPath) {
            cmd /c "rmdir /s /q `"$($target.LocalPath)`"" *>$null
        }
        Remove-CimInstance -InputObject $target -ErrorAction Stop
        Invoke-Log -Message "Perfil de usuario $folderName eliminado"
        Write-Result "Perfil eliminado correctamente" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina perfiles huerfanos (sin usuario asociado)
    #>
function Remove-OrphanProfiles {
    Clear-Host
    Write-Title "PERFILES HUERFANOS"
    try {
        $profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop
        $users = Get-LocalUser
        $orphans = @()
        foreach ($p in $profiles) {
            $hasUser = $users | Where-Object { $_.SID.Value -eq $p.SID } | Select-Object -First 1
            if (-not $hasUser) { $orphans += $p }
        }
        if ($orphans.Count -eq 0) {
            Write-Result "No se encontraron perfiles huerfanos" "OK"
            Pause-Message; return
        }
        Write-Host "Perfiles huerfanos encontrados: $($orphans.Count)`n" -ForegroundColor Yellow
        $orphans | ForEach-Object {
            $size = Get-ProfileSize $_.LocalPath
            $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
            Write-Host "  $($_.LocalPath) | $size | Ultimo uso: $lastUse"
        }
        if (-not (Read-YesNo -Prompt "Eliminar TODOS los perfiles huerfanos")) { return }
        $deleted = 0; $errors = 0
        foreach ($p in $orphans) {
            if ($p.Loaded) {
                Write-Result "Perfil cargado: $($p.LocalPath) -- se omite" "WARN"
                $errors++; continue
            }
            try {
                if (Test-Path $p.LocalPath) {
                    cmd /c "rmdir /s /q `"$($p.LocalPath)`"" *>$null
                }
                Remove-CimInstance -InputObject $p -ErrorAction Stop
                $deleted++
                Invoke-Log -Message "Perfil huerfano eliminado: $($p.LocalPath)"
            } catch { $errors++ }
        }
        $resultStatus = "WARN"
        if ($errors -eq 0) { $resultStatus = "OK" }
        Write-Result "$deleted perfiles eliminados, $errors errores" $resultStatus
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}
```

#### 6.8 `lib/Services.ps1`

```powershell
    # lib/Services.ps1
# Administracion de servicios y aplicaciones de inicio

    <#
    .SYNOPSIS
    Menu principal de gestion de servicios
    #>
function Show-ServicesMenu {
    do {
        Clear-Host
        Write-Title "ADMINISTRACION DE SERVICIOS E INICIO"
        Write-Menu -Options @(
            "  1. Listar servicios en ejecucion",
            "  2. Iniciar servicio",
            "  3. Detener servicio",
            "  4. Reiniciar servicio",
            "  5. Ver aplicaciones de inicio",
            "  6. Agregar aplicacion de inicio",
            "  7. Inhabilitar aplicacion de inicio",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 7
        switch ($opt) {
            1 { Show-RunningServices }
            2 { Start-ServicePrompt }
            3 { Stop-ServicePrompt }
            4 { Restart-ServicePrompt }
            5 { Show-StartupApps }
            6 { Add-StartupApp }
            7 { Remove-StartupApp }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Lista los servicios en ejecucion
    #>
function Show-RunningServices {
    Clear-Host
    Write-Title "SERVICIOS EN EJECUCION"
    cmd /c "net start"
    Pause-Message
}

    <#
    .SYNOPSIS
    Solicita el nombre e inicia un servicio
    #>
function Start-ServicePrompt {
    Clear-Host
    Write-Title "INICIAR SERVICIO"
    $svcName = Read-Host "Nombre del servicio a iniciar"
    if ([string]::IsNullOrWhiteSpace($svcName)) { return }
    try {
        Start-Service -Name $svcName -ErrorAction Stop
        Write-Result "Servicio '$svcName' iniciado" "OK"
        Invoke-Log -Message "Servicio $svcName iniciado"
    } catch {
        Write-Result "Error al iniciar: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Solicita el nombre y detiene un servicio
    #>
function Stop-ServicePrompt {
    Clear-Host
    Write-Title "DETENER SERVICIO"
    $svcName = Read-Host "Nombre del servicio a detener"
    if ([string]::IsNullOrWhiteSpace($svcName)) { return }
    try {
        Stop-Service -Name $svcName -Force -ErrorAction Stop
        Write-Result "Servicio '$svcName' detenido" "OK"
        Invoke-Log -Message "Servicio $svcName detenido"
    } catch {
        Write-Result "Error al detener: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Solicita el nombre y reinicia un servicio
    #>
function Restart-ServicePrompt {
    Clear-Host
    Write-Title "REINICIAR SERVICIO"
    $svcName = Read-Host "Nombre del servicio a reiniciar"
    if ([string]::IsNullOrWhiteSpace($svcName)) { return }
    try {
        Restart-Service -Name $svcName -Force -ErrorAction Stop
        Write-Result "Servicio '$svcName' reiniciado" "OK"
        Invoke-Log -Message "Servicio $svcName reiniciado"
    } catch {
        Write-Result "Error al reiniciar: $_" "ERROR"
    }
    Pause-Message
}

# Funciones de inicio (fusionadas desde StartupApps.ps1)

    <#
    .SYNOPSIS
    Muestra las aplicaciones configuradas para iniciar con el usuario
    #>
function Show-StartupApps {
    Clear-Host
    Write-Title "APLICACIONES DE INICIO (USUARIO)"
    try {
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $apps = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($apps) {
            $apps.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } |
                Select-Object Name, Value |
                Format-Table Name, Value -AutoSize -Wrap
        } else { Write-Result "No hay aplicaciones de inicio" "INFO" }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Agrega una aplicacion al inicio del usuario
    #>
function Add-StartupApp {
    Clear-Host
    Write-Title "AGREGAR APLICACION DE INICIO"
    $name = Read-Host "Nombre de la entrada"
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $path = Read-Host "Ruta completa del ejecutable"
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) {
        Write-Result "Ruta no valida" "ERROR"; Pause-Message; return
    }
    try {
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        Set-ItemProperty -Path $key -Name $name -Value $path -ErrorAction Stop
        Write-Result "Aplicacion '$name' agregada al inicio" "OK"
        Invoke-Log -Message "Aplicacion $name agregada al inicio"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Inhabilita una aplicacion de inicio del usuario
    #>
function Remove-StartupApp {
    Clear-Host
    Write-Title "INHABILITAR APLICACION DE INICIO"
    try {
        $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $apps = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        $appNames = $apps.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | Select-Object -ExpandProperty Name
        if (-not $appNames) { Write-Result "No hay aplicaciones" "INFO"; Pause-Message; return }
        Write-Host "Aplicaciones de inicio:" -ForegroundColor Cyan
        $appNames | ForEach-Object { Write-Host "  - $_" }
        $removeName = Read-Host "`nNombre de la aplicacion a inhabilitar"
        if ([string]::IsNullOrWhiteSpace($removeName)) { return }
        Remove-ItemProperty -Path $key -Name $removeName -ErrorAction Stop
        Write-Result "Aplicacion '$removeName' inhabilitada" "OK"
        Invoke-Log -Message "Aplicacion de inicio $removeName inhabilitada"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}
```

#### 6.9 `lib/Backup.ps1`

```powershell
    # lib/Backup.ps1
# Copia de seguridad y restauracion de controladores

    <#
    .SYNOPSIS
    Menu principal de copias de seguridad
    #>
function Show-BackupMenu {
    do {
        Clear-Host
        Write-Title "COPIA DE SEGURIDAD DE CONTROLADORES"
        Write-Menu -Options @(
            "  1. Crear copia en ruta predeterminada",
            "  2. Crear copia en ruta personalizada",
            "  3. Crear copia en disco USB",
            "  4. Restaurar desde copia de seguridad",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Backup-Drivers }
            2 { Backup-DriversCustom }
            3 { Backup-DriversUSB }
            4 { Show-RestoreMenu }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Menu de restauracion de copias
    #>
function Show-RestoreMenu {
    do {
        Clear-Host
        Write-Title "RESTAURACION DE COPIAS DE SEGURIDAD"
        Write-Menu -Options @(
            "  1. Restaurar en el mismo equipo",
            "  2. Restaurar en equipo diferente",
            "  0. Volver al menu anterior"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { Restore-DriversSame }
            2 { Restore-DriversDifferent }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Obtiene rutas de origen y destino desde configuracion
    #>
function Get-ConfigSourcePaths {
    $srcDrivers = Get-ConfigValue -Key "BackupSourceDrivers" -Default "$env:SystemRoot\System32\Drivers"
    $srcDriverStore = Get-ConfigValue -Key "BackupSourceDriverStore" -Default "$env:SystemRoot\System32\DriverStore\FileRepository"
    $srcInf = Get-ConfigValue -Key "BackupSourceInf" -Default "$env:SystemRoot\inf"
    $dest = Get-ConfigValue -Key "BackupDest" -Default ".\backups\drivers"
    if (-not [IO.Path]::IsPathRooted($dest)) {
        $dest = Join-Path (Get-ScriptDirectory) $dest
    }
    return @{
        SourceDrivers = $srcDrivers
        SourceDriverStore = $srcDriverStore
        SourceInf = $srcInf
        Dest = $dest
    }
}

    <#
    .SYNOPSIS
    Realiza copia de seguridad de controladores
    #>
function Backup-Drivers {
    param([string]$DestPath = "")
    $paths = Get-ConfigSourcePaths
    if ([string]::IsNullOrWhiteSpace($DestPath)) {
        $DestPath = $paths.Dest
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path $DestPath "BackupDrivers_$timestamp"
    try {
        if (-not (Test-Path $DestPath)) { New-Item -ItemType Directory -Path $DestPath -Force | Out-Null }
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Write-Result "Copiando controladores..." "INFO"
        if (Test-Path $paths.SourceDrivers) {
            Copy-Item -Path "$($paths.SourceDrivers)\*" -Destination (Join-Path $backupFolder "Drivers") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceDrivers)" "WARN" }
        if (Test-Path $paths.SourceDriverStore) {
            Copy-Item -Path "$($paths.SourceDriverStore)\*" -Destination (Join-Path $backupFolder "DriverStore") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceDriverStore)" "WARN" }
        if (Test-Path $paths.SourceInf) {
            Copy-Item -Path "$($paths.SourceInf)\*" -Destination (Join-Path $backupFolder "inf") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceInf)" "WARN" }
        $regFile = Join-Path $backupFolder "DriversRegistry.reg"
        Write-Result "Exportando registro de controladores..." "INFO"
        cmd /c "reg export `"HKLM\SYSTEM\CurrentControlSet\Control\Class`" `"$regFile`"" *>$null
        Invoke-Log -Message "Backup de controladores: $backupFolder"
        Write-Result "Copia de seguridad completada en:`n  $backupFolder" "OK"
    } catch {
        Write-Result "Error en backup: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Backup fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Realiza copia en ruta personalizada
    #>
function Backup-DriversCustom {
    Write-Host "`nRutas sugeridas:" -ForegroundColor Cyan
    Write-Host "  1. Escritorio: $env:USERPROFILE\Desktop"
    Write-Host "  2. Descargas: $env:USERPROFILE\Downloads"
    Write-Host "  3. Documentos: $env:USERPROFILE\Documents"
    $customPath = Read-Host "`nIngrese la ruta de destino"
    if ([string]::IsNullOrWhiteSpace($customPath)) { return }
    Backup-Drivers -DestPath $customPath
}

    <#
    .SYNOPSIS
    Realiza copia en unidad USB
    #>
function Backup-DriversUSB {
    $usbDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter }
    if (-not $usbDrives) {
        Write-Result "No se detectaron unidades USB" "WARN"
        Pause-Message
        return
    }
    Write-Host "`nUnidades USB detectadas:" -ForegroundColor Cyan
    $usbDrives | Format-Table DriveLetter, FileSystemLabel, @{N='Libre(GB)';E={[math]::Round($_.SizeRemaining/1GB,2)}} -AutoSize
    $letter = Read-Host "Ingrese la letra de la unidad USB"
    if ([string]::IsNullOrWhiteSpace($letter)) { return }
    $usbPath = "$($letter[0]):\"
    if (-not (Test-Path $usbPath)) {
        Write-Result "Unidad $usbPath no encontrada" "ERROR"
        Pause-Message
        return
    }
    Backup-Drivers -DestPath $usbPath
}

    <#
    .SYNOPSIS
    Restaura controladores en el mismo equipo
    #>
function Restore-DriversSame {
    $backupFolder = Read-Host "`nIngrese la ruta de la carpeta de copia de seguridad"
    if ([string]::IsNullOrWhiteSpace($backupFolder) -or -not (Test-Path $backupFolder)) {
        Write-Result "Carpeta no encontrada" "ERROR"
        Pause-Message
        return
    }
    try {
        $paths = Get-ConfigSourcePaths
        $subfolders = @("Drivers", "DriverStore", "inf")
        $targets = @($paths.SourceDrivers, $paths.SourceDriverStore, $paths.SourceInf)
        for ($i = 0; $i -lt $subfolders.Count; $i++) {
            $src = Join-Path $backupFolder $subfolders[$i]
            if (Test-Path $src) {
                Write-Result "Restaurando $($subfolders[$i])..." "INFO"
                Copy-Item -Path "$src\*" -Destination $targets[$i] -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        $regFile = Join-Path $backupFolder "DriversRegistry.reg"
        if (Test-Path $regFile) {
            Write-Result "Importando registro..." "INFO"
            cmd /c "reg import `"$regFile`"" *>$null
        }
        Invoke-Log -Message "Restauracion de controladores desde $backupFolder"
        Write-Result "Restauracion completada" "OK"
    } catch {
        Write-Result "Error en restauracion: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Restauracion fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Restaura controladores en equipo diferente
    #>
function Restore-DriversDifferent {
    $backupFolder = Read-Host "`nIngrese la ruta de la carpeta de copia de seguridad"
    if ([string]::IsNullOrWhiteSpace($backupFolder) -or -not (Test-Path $backupFolder)) {
        Write-Result "Carpeta no encontrada" "ERROR"
        Pause-Message
        return
    }
    Write-Host "`nOPCIONES DE RESTAURACION:" -ForegroundColor Yellow
    Write-Host "  1. Verificar compatibilidad primero"
    Write-Host "  2. Restaurar sin verificar"
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
    if ($opt -eq 1) {
        Write-Result "Verificando compatibilidad..." "INFO"
        $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
        Write-Host "  Version SO actual: $osVersion" -ForegroundColor Gray
        if (-not (Read-YesNo -Prompt "Desea continuar con la restauracion")) { return }
    }
    try {
        $paths = Get-ConfigSourcePaths
        $subfolders = @("Drivers", "DriverStore", "inf")
        $targets = @($paths.SourceDrivers, $paths.SourceDriverStore, $paths.SourceInf)
        for ($i = 0; $i -lt $subfolders.Count; $i++) {
            $src = Join-Path $backupFolder $subfolders[$i]
            if (Test-Path $src) {
                Write-Result "Restaurando $($subfolders[$i])..." "INFO"
                Copy-Item -Path "$src\*" -Destination $targets[$i] -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Invoke-Log -Message "Restauracion (equipo diferente) desde $backupFolder"
        Write-Result "Restauracion completada" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Restauracion fallo: $_"
    }
    Pause-Message
}
```

#### 6.10 `lib/Processes.ps1`

```powershell
    # lib/Processes.ps1
# Gestor de procesos: listar, kill, ver detalles

    <#
    .SYNOPSIS
    Menu principal del gestor de procesos
    #>
function Show-ProcessMenu {
    do {
        Clear-Host
        Write-Title "GESTOR DE PROCESOS"
        Write-Menu -Options @(
            "  1. Listar procesos en ejecucion",
            "  2. Top procesos por uso de memoria",
            "  3. Top procesos por uso de CPU",
            "  4. Detalle de un proceso por PID",
            "  5. Detalle de un proceso por nombre",
            "  6. Finalizar proceso por PID",
            "  7. Finalizar proceso por nombre",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 7
        switch ($opt) {
            1 { Invoke-ListProcesses }
            2 { Invoke-TopMemory }
            3 { Invoke-TopCPU }
            4 { Invoke-ProcessByPID }
            5 { Invoke-ProcessByName }
            6 { Invoke-KillByPID }
            7 { Invoke-KillByName }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra una tabla formateada de procesos
    #>
function Show-ProcessTable {
    param([array]$Processes, [string]$Title)
    if ($Processes.Count -eq 0) {
        Write-Result "No se encontraron procesos" "WARN"
        return
    }
    $Processes | Format-Table @(
        @{N='PID';E={$_.Id};Width=8},
        @{N='Nombre';E={$_.ProcessName};Width=30},
        @{N='CPU(s)';E={try {[math]::Round($_.TotalProcessorTime.TotalSeconds,1)} catch {0}};Width=10},
        @{N='Memoria(MB)';E={try {[math]::Round($_.WorkingSet64/1MB,1)} catch {0}};Width=14},
        @{N='Hilos';E={$_.Threads.Count};Width=8},
        @{N='Respondiendo';E={if ($_.Responding) {'Si'} else {'No'}};Width=14}
    ) -AutoSize -Wrap
}

    <#
    .SYNOPSIS
    Lista procesos en ejecucion con detalles
    #>
function Invoke-ListProcesses {
    Clear-Host
    Write-Title "PROCESOS EN EJECUCION"
    try {
        $procs = Get-Process | Sort-Object ProcessName
        Write-Host "Total: $($procs.Count) procesos`n" -ForegroundColor Gray
        Show-ProcessTable -Processes $procs -Title "Procesos"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra los 20 procesos con mayor uso de memoria
    #>
function Invoke-TopMemory {
    Clear-Host
    Write-Title "TOP 20 PROCESOS POR MEMORIA"
    try {
        $procs = Get-Process | Sort-Object { try { $_.WorkingSet64 } catch { 0 } } -Descending | Select-Object -First 20
        Show-ProcessTable -Processes $procs -Title "Top 20 Memoria"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra los 20 procesos con mayor uso de CPU
    #>
function Invoke-TopCPU {
    Clear-Host
    Write-Title "TOP 20 PROCESOS POR CPU"
    try {
        $procs = Get-Process | Sort-Object { try { $_.TotalProcessorTime.TotalSeconds } catch { 0 } } -Descending | Select-Object -First 20
        Show-ProcessTable -Processes $procs -Title "Top 20 CPU"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el detalle de un proceso por su PID
    #>
function Invoke-ProcessByPID {
    Clear-Host
    Write-Title "DETALLE DE PROCESO POR PID"
    $pidInput = Read-Host "`nPID"
    if ($pidInput -notmatch '^\d+$') { Write-Result "PID invalido" "WARN"; Pause-Message; return }
    try {
        $p = Get-Process -Id [int]$pidInput -ErrorAction Stop
        Write-Host "`nNombre           : $($p.ProcessName)" -ForegroundColor White
        Write-Host "PID              : $($p.Id)" -ForegroundColor White
        Write-Host "Memoria (MB)     : $([math]::Round($p.WorkingSet64/1MB, 2))" -ForegroundColor White
        Write-Host "CPU total (s)    : $([math]::Round($p.TotalProcessorTime.TotalSeconds, 2))" -ForegroundColor White
        Write-Host "Hilos            : $($p.Threads.Count)" -ForegroundColor White
        Write-Host "Handles          : $($p.HandleCount)" -ForegroundColor White
        Write-Host "Respondiendo     : $(if ($p.Responding) { 'Si' } else { 'No' })" -ForegroundColor White
        Write-Host "Ruta             : $(try { $p.MainModule.FileName } catch { '[No accesible]' })" -ForegroundColor Gray
        Write-Host "Inicio           : $(try { $p.StartTime } catch { '[No accesible]' })" -ForegroundColor Gray
    } catch { Write-Result "Error: PID $pidInput no encontrado" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el detalle de procesos por su nombre
    #>
function Invoke-ProcessByName {
    Clear-Host
    Write-Title "DETALLE DE PROCESO POR NOMBRE"
    $name = Read-Host "`nNombre del proceso (ej: chrome)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Result "Nombre invalido" "WARN"; Pause-Message; return }
    try {
        $procs = Get-Process -Name $name -ErrorAction Stop
        Write-Host "`nProcesos encontrados: $($procs.Count)`n" -ForegroundColor Gray
        Show-ProcessTable -Processes $procs -Title $name
    } catch { Write-Result "Error: proceso '$name' no encontrado" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Finaliza un proceso por su PID
    #>
function Invoke-KillByPID {
    Clear-Host
    Write-Title "FINALIZAR PROCESO POR PID"
    $pidInput = Read-Host "`nPID a finalizar"
    if ($pidInput -notmatch '^\d+$') { Write-Result "PID invalido" "WARN"; Pause-Message; return }
    try {
        $p = Get-Process -Id [int]$pidInput -ErrorAction Stop
        $name = $p.ProcessName
        if (-not (Read-YesNo -Prompt "Finalizar $name (PID: $pidInput)?")) { return }
        $p.Kill()
        Invoke-Log -Message "Proceso finalizado: $name (PID: $pidInput)"
        Write-Result "Proceso $name (PID: $pidInput) finalizado" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Finaliza todos los procesos por su nombre
    #>
function Invoke-KillByName {
    Clear-Host
    Write-Title "FINALIZAR PROCESO POR NOMBRE"
    $name = Read-Host "`nNombre del proceso (ej: notepad)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Result "Nombre invalido" "WARN"; Pause-Message; return }
    try {
        $procs = Get-Process -Name $name -ErrorAction Stop
        $count = $procs.Count
        if (-not (Read-YesNo -Prompt "Finalizar $count instancia(s) de '$name'?")) { return }
        $procs | ForEach-Object { $_.Kill() }
        Invoke-Log -Message "Procesos finalizados: $name ($count instancias)"
        Write-Result "Se finalizaron $count instancia(s) de $name" "OK"
    } catch { Write-Result "Error: proceso '$name' no encontrado" "ERROR" }
    Pause-Message
}
```

#### 6.11 `lib/Hosts.ps1`

```powershell
    # lib/Hosts.ps1
# Editor de archivo hosts: listar, agregar, quitar entradas

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsBackup = "$env:windir\System32\drivers\etc\hosts.bak"

    <#
    .SYNOPSIS
    Menu principal del editor de hosts
    #>
function Show-HostsMenu {
    do {
        Clear-Host
        Write-Title "EDITOR DE ARCHIVO HOSTS"
        Write-Menu -Options @(
            "  1. Listar entradas activas",
            "  2. Agregar entrada (IP + hostname)",
            "  3. Eliminar entrada por hostname",
            "  4. Bloquear sitio web (redirigir a 0.0.0.0)",
            "  5. Ver contenido completo del hosts",
            "  6. Restaurar copia de seguridad (.bak)",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 { Invoke-ListHosts }
            2 { Invoke-AddHostEntry }
            3 { Invoke-RemoveHostEntry }
            4 { Invoke-BlockWebsite }
            5 { Invoke-ViewHostsRaw }
            6 { Invoke-RestoreHostsBackup }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Obtiene entradas activas del archivo hosts
    #>
function Get-HostsEntries {
    if (-not (Test-Path $hostsPath)) { return @() }
    $entries = Get-Content $hostsPath | Where-Object {
        $_.Trim() -ne '' -and $_.Trim() -notmatch '^#'
    }
    return $entries
}

    <#
    .SYNOPSIS
    Muestra entradas activas del archivo hosts
    #>
function Invoke-ListHosts {
    Clear-Host
    Write-Title "ENTRADAS ACTIVAS EN HOSTS"
    $entries = Get-HostsEntries
    if ($entries.Count -eq 0) {
        Write-Result "No hay entradas activas (comentarios y vacios ignorados)" "INFO"
    } else {
        Write-Host "`n  IP`t`t`tHOSTNAME" -ForegroundColor Cyan
        Write-Host "  " + ("-" * 55) -ForegroundColor Gray
        foreach ($e in $entries) {
            $parts = $e.Trim() -split '\s+'
            if ($parts.Count -ge 2) {
                Write-Host ("  {0,-20} {1}" -f $parts[0], $parts[1]) -ForegroundColor White
            }
        }
        Write-Host "`n  Total: $($entries.Count) entradas" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Agrega una entrada al archivo hosts
    #>
function Invoke-AddHostEntry {
    Clear-Host
    Write-Title "AGREGAR ENTRADA AL HOSTS"
    $ip = Read-Host "`nDireccion IP (ej: 127.0.0.1)"
    $hostname = Read-Host "Hostname (ej: ejemplo.local)"
    if ([string]::IsNullOrWhiteSpace($ip) -or [string]::IsNullOrWhiteSpace($hostname)) {
        Write-Result "Operacion cancelada - datos incompletos" "WARN"
        Pause-Message; return
    }
    try {
        Add-Content -Path $hostsPath -Value "`n$ip`t$hostname" -ErrorAction Stop
        Invoke-Log -Message "Hosts: agregada entrada $ip $hostname"
        Write-Result "Entrada agregada: $ip  $hostname" "OK"
        Write-Result "Ejecute 'ipconfig /flushdns' si el cambio no se refleja" "INFO"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina una entrada del archivo hosts
    #>
function Invoke-RemoveHostEntry {
    Clear-Host
    Write-Title "ELIMIN
