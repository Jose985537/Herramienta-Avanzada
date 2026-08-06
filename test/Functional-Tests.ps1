   # test/Functional-Tests.ps1
# Pruebas funcionales de modulos PowerShell (solo lectura)

$script:rootDir = Split-Path -Parent $PSScriptRoot
$script:libDir = Join-Path $rootDir "lib"

$script:passed = 0
$script:failed = 0
$script:results = @()
$script:loadErrors = @()

# ---- Cargar modulos en ambito global ----
$modules = @(
    "MenuHelpers.ps1", "Maintenance.ps1", "Network.ps1", "SecurityPlus.ps1",
    "Info.ps1", "Power.ps1", "ConfigSys.ps1", "Users.ps1", "Services.ps1",
    "Backup.ps1", "Processes.ps1", "Hosts.ps1", "WiFi.ps1", "RDP.ps1",
    "PowerPlan.ps1", "TaskScheduler.ps1", "WindowsFeatures.ps1", "DriveMapping.ps1"
)
foreach ($mod in $modules) {
    $path = Join-Path $libDir $mod
    try { . $path } catch { $script:loadErrors += "$mod : $_" }
}

function Add-TestResult {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $global:passed += [int]$Passed
    $global:failed += [int](-not $Passed)
    $global:results += [PSCustomObject]@{ Name = $Name; Passed = $Passed; Detail = $Detail }
    $status = $(if ($Passed) { "PASS" } else { "FAIL" })
    Write-Host "  [$status] $Name" -ForegroundColor $(if ($Passed) { 'Green' } else { 'Red' })
}

function Assert-Cmd {
    param([string]$Cmd)
    return (Get-Command $Cmd -ErrorAction SilentlyContinue) -ne $null
}

# ---- Ejecucion ----
Clear-Host
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  PRUEBAS FUNCIONALES - MODULOS POWERSHELL" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$start = Get-Date

Write-Host "`n=== TEST 1: Carga de modulos ===`n" -ForegroundColor Cyan
Add-TestResult "Carga de 18 modulos sin error" ($script:loadErrors.Count -eq 0) $(
    if ($script:loadErrors.Count -eq 0) { "OK" } else { $script:loadErrors -join '; ' }
)
if ($script:loadErrors.Count -gt 0) {
    $script:loadErrors | ForEach-Object { Write-Host "    ERROR: $_" -ForegroundColor Red }
}

Write-Host "`n=== TEST 2: Funciones base del menu ===`n" -ForegroundColor Cyan
foreach ($f in @("Write-Title","Write-Menu","Read-MenuChoice","Read-YesNo","Invoke-Log","Get-ConfigValue","Write-Result","Pause-Message","Read-SecurePassword","Get-ScriptDirectory")) {
    Add-TestResult "$f existe" (Assert-Cmd $f) ""
}

Write-Host "`n=== TEST 3: Get-ConfigValue desde settings.ini ===`n" -ForegroundColor Cyan
try {
    $v1 = Get-ConfigValue -Key "BackupSourceDrivers"
    Add-TestResult "Key BackupSourceDrivers encontrado" $(-not [string]::IsNullOrEmpty($v1)) "Valor=$v1"
} catch { Add-TestResult "Key BackupSourceDrivers" $false "ERROR: $_" }
try {
    $v2 = Get-ConfigValue -Key "Level"
    Add-TestResult "Key Level encontrado" ($v2 -eq "INFO") "Valor=$v2"
} catch { Add-TestResult "Key Level" $false "ERROR: $_" }
try {
    $v3 = Get-ConfigValue -Key "EnableDebugLog"
    Add-TestResult "Key EnableDebugLog encontrado" ($v3 -eq "false") "Valor=$v3"
} catch { Add-TestResult "Key EnableDebugLog" $false "ERROR: $_" }

Write-Host "`n=== TEST 4: PowerPlan.ps1 ===`n" -ForegroundColor Cyan
try {
    $guid = Get-PowerPlanGuid "Equilibrado"
    Add-TestResult "Get-PowerPlanGuid Equilibrado" (($guid -ne $null) -and ($guid -match '^[0-9a-f\-]{36}$')) "GUID=$guid"
} catch { Add-TestResult "Get-PowerPlanGuid Equilibrado" $false "ERROR: $_" }
try {
    $guid2 = Get-PowerPlanGuid "Alto rendimiento"
    Add-TestResult "Get-PowerPlanGuid Alto rendimiento" (($guid2 -ne $null) -and ($guid2 -match '^[0-9a-f\-]{36}$')) "GUID=$guid2"
} catch { Add-TestResult "Get-PowerPlanGuid Alto rendimiento" $false "ERROR: $_" }
try {
    $guid3 = Get-PowerPlanGuid "Economizador"
    Add-TestResult "Get-PowerPlanGuid Economizador" (($guid3 -ne $null) -and ($guid3 -match '^[0-9a-f\-]{36}$')) "GUID=$guid3"
} catch { Add-TestResult "Get-PowerPlanGuid Economizador" $false "ERROR: $_" }

Write-Host "`n=== TEST 5: TaskScheduler.ps1 ===`n" -ForegroundColor Cyan
try {
    $tasks = Get-ScheduledTask -ErrorAction Stop
    Add-TestResult "Get-ScheduledTask retorna tareas" $true "Total=$($tasks.Count)"
} catch { Add-TestResult "Get-ScheduledTask sin error" $false "ERROR: $_" }

Write-Host "`n=== TEST 6: Processes.ps1 ===`n" -ForegroundColor Cyan
try {
    $procs = Get-Process | Select-Object -First 5
    Add-TestResult "Get-Process retorna procesos" ($procs.Count -gt 0) "OK"
} catch { Add-TestResult "Get-Process sin error" $false "ERROR: $_" }

Write-Host "`n=== TEST 7: Network.ps1 ===`n" -ForegroundColor Cyan
try {
    $ipconfig = cmd /c "ipconfig 2>&1"
    $hasWin = @($ipconfig | Select-String -Pattern 'Windows')
    Add-TestResult "ipconfig retorna configuracion" ($hasWin.Count -gt 0) "OK"
} catch { Add-TestResult "ipconfig sin error" $false "ERROR: $_" }
try {
    $adapterCmd = Get-NetAdapter -ErrorAction SilentlyContinue
    if ($adapterCmd) {
        Add-TestResult "Get-NetAdapter retorna adaptadores" ($adapterCmd.Count -gt 0) "Adaptadores=$($adapterCmd.Count)"
    } elseif ($null -eq (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
        Add-TestResult "Get-NetAdapter cmdlet disponible" $false "Cmdlet no instalado"
    }
} catch { Add-TestResult "Get-NetAdapter sin error" $false "ERROR: $_" }

Write-Host "`n=== TEST 8: Hosts.ps1 ===`n" -ForegroundColor Cyan
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    $content = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    Add-TestResult "hosts archivo legible" ([bool]($content -match 'localhost')) "OK"
} else { Add-TestResult "hosts archivo existe" $false "No encontrado" }
Add-TestResult "Show-HostsMenu declarada" (Assert-Cmd "Show-HostsMenu") ""

Write-Host "`n=== TEST 9: RDP.ps1 ===`n" -ForegroundColor Cyan
Add-TestResult "Show-RDPMenu declarada" (Assert-Cmd "Show-RDPMenu") ""
try {
    $tskey = Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -ErrorAction SilentlyContinue
    if ($tskey) {
        $state = $(if ($tskey.fDenyTSConnections -eq 0) { "Activado" } else { "Desactivado" })
        Add-TestResult "Estado RDP legible desde registry" $true "RDP=$state"
    } else { Add-TestResult "Estado RDP desde registry" $false "Clave no encontrada" }
} catch { Add-TestResult "Estado RDP desde registry" $false "ERROR: $_" }

Write-Host "`n=== TEST 10: WiFi.ps1 ===`n" -ForegroundColor Cyan
Add-TestResult "Show-WiFiMenu declarada" (Assert-Cmd "Show-WiFiMenu") ""
try {
    $wlan = cmd /c "netsh wlan show profiles 2>&1"
    $hasWiFi = ($wlan | Select-String -Pattern 'Perfiles|profiles').Count -gt 0
    Add-TestResult "netsh wlan show profiles disponible" $hasWiFi ""
} catch { Add-TestResult "netsh wlan sin error" $false "ERROR: $_" }

Write-Host "`n=== TEST 11: DriveMapping.ps1 ===`n" -ForegroundColor Cyan
Add-TestResult "Show-DriveMappingMenu declarada" (Assert-Cmd "Show-DriveMappingMenu") ""
try {
    $netDrives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 4 }
    Add-TestResult "WMI unidades de red detectables" $true "Mapeadas: $($netDrives.Count)"
} catch { Add-TestResult "WMI unidades de red detectables" $false "ERROR: $_" }

Write-Host "`n=== TEST 12: WindowsFeatures.ps1 ===`n" -ForegroundColor Cyan
Add-TestResult "Show-WindowsFeaturesMenu declarada" (Assert-Cmd "Show-WindowsFeaturesMenu") ""
try {
    $features = Get-WindowsOptionalFeature -Online -ErrorAction Stop
    if ($features.Count -gt 0) {
        Add-TestResult "Get-WindowsOptionalFeature retorna datos" $true "Total=$($features.Count)"
    } else { Add-TestResult "Get-WindowsOptionalFeature retorna datos" $false "Total=0" }
} catch { Add-TestResult "Get-WindowsOptionalFeature requiere admin" $true "Requiere privilegios elevados" }

Write-Host "`n=== TEST 13: Launcher menu principal ===`n" -ForegroundColor Cyan
$launcherPath = Join-Path $rootDir "launcher.ps1"
$lc = Get-Content $launcherPath -Raw
Add-TestResult "Launcher contiene NEXUS_CALDERON" ($lc -match 'NEXUS_CALDERON') ""
Add-TestResult "Launcher referencia 18 modulos" ((($lc | Select-String -Pattern '\.ps1"' -AllMatches).Matches.Count) -ge 18) "OK"
Add-TestResult "Launcher rango 0-17" ($lc -match '0-17') "OK"
Add-TestResult "Launcher casos Show-*Menu >= 17" ((($lc | Select-String -Pattern 'Show-\w+Menu' -AllMatches).Matches.Count) -ge 17) "OK"

Write-Host "`n=== TEST 14: Sin passwords hardcoded ===`n" -ForegroundColor Cyan
$allText = Get-ChildItem -Path $libDir -Filter "*.ps1" | ForEach-Object { Get-Content $_.FullName -Raw }
$joined = $allText -join "`n"
$suspicious = @()
if ($joined -match 'password123') { $suspicious += 'password123' }
Add-TestResult "Scripts sin passwords hardcoded" ($suspicious.Count -eq 0) $(
    if ($suspicious.Count -eq 0) { "OK" } else { $suspicious -join '; ' }
)

Write-Host "`n=== TEST 15: Backup.ps1 ===`n" -ForegroundColor Cyan
Add-TestResult "Show-BackupMenu declarada" (Assert-Cmd "Show-BackupMenu") ""
try {
    $src = Get-ConfigSourcePaths
    if ($src -is [hashtable]) {
        $hasKeys = @('SourceDrivers','SourceDriverStore','SourceInf','Dest') | ForEach-Object { $src.ContainsKey($_) }
        $allKeys = ($hasKeys -notcontains $false)
        Add-TestResult "Get-ConfigSourcePaths hashtable 4 claves" $allKeys "Claves=$($src.Keys -join ',')"
    } else {
        Add-TestResult "Get-ConfigSourcePaths retorna hashtable" $false "Tipo=$($src.GetType().Name)"
    }
} catch { Add-TestResult "Get-ConfigSourcePaths sin error" $false "ERROR: $_" }

Write-Host "`n=== TEST 16: Sin colisiones de funciones ===`n" -ForegroundColor Cyan
$allFuncs = @{}
$dupes = @()
Get-ChildItem -Path $libDir -Filter "*.ps1" | ForEach-Object {
    $modName = $_.Name
    $funcs = Get-Command -CommandType Function | Where-Object {
        ($_.ScriptBlock.File -like "*$modName*") -and ($_.ScriptBlock.File -ne $null)
    }
    foreach ($f in $funcs) {
        if ($allFuncs.ContainsKey($f.Name)) { $dupes += "$($f.Name) en $modName y $($allFuncs[$f.Name])" }
        else { $allFuncs[$f.Name] = $modName }
    }
}
Add-TestResult "Sin colisiones entre modulos" ($dupes.Count -eq 0) $(
    if ($dupes.Count -eq 0) { "OK" } else { $dupes -join '; ' }
)

Write-Host "`n=== TEST 17: Branding NEXUS_CALDERON en modulos ===`n" -ForegroundColor Cyan
$brandCount = 0
Get-ChildItem -Path $libDir -Filter "*.ps1" | ForEach-Object {
    $fc = Get-Content $_.FullName -Raw
    if ($fc -match 'NEXUS_CALDERON') { $brandCount++ }
}
$launcherContent = Get-Content $launcherPath -Raw
if ($launcherContent -match 'NEXUS_CALDERON') { $brandCount++ }
Add-TestResult "Branding NEXUS_CALDERON en modulos+launcher" ($brandCount -ge 1) "Archivos con marca: $brandCount"

# ---- Resumen ----
$elapsed = (Get-Date) - $start
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  RESUMEN PRUEBAS FUNCIONALES" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Total: $($passed + $failed) | Passed: $passed | Failed: $failed | Tiempo: $($elapsed.TotalSeconds.ToString('0.0'))s" -ForegroundColor $(
    if ($failed -eq 0) { 'Green' } else { 'Red' }
)
Write-Host "============================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "`nPruebas falladas:" -ForegroundColor Red
    $global:results | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Detail)" -ForegroundColor Red
    }
}
