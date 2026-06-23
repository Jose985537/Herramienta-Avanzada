   <#
.SYNOPSIS
    Validacion FASE 2 - Herramienta Avanzada modular PowerShell.
    Verifica que el ecosistema completo funcione correctamente.
#>

$ScriptRoot = Split-Path -Parent $PSScriptRoot
$testResult = [System.Collections.ArrayList]@()

# ====== LOAD ALL MODULES FIRST ======
$libDir = Join-Path $ScriptRoot "lib"
$requiredModules = @(
    "MenuHelpers.ps1", "Maintenance.ps1", "Network.ps1", "SecurityPlus.ps1",
    "Info.ps1", "Power.ps1", "ConfigSys.ps1", "Users.ps1", "Services.ps1",
    "Backup.ps1", "Processes.ps1", "Hosts.ps1", "WiFi.ps1", "RDP.ps1", "PowerPlan.ps1",
    "TaskScheduler.ps1", "WindowsFeatures.ps1", "DriveMapping.ps1"
)
foreach ($mod in $requiredModules) {
    . (Join-Path $libDir $mod)
}
# Script paths for later tests
$readConfigPath = Join-Path $libDir "Read-Config.ps1"

function Test-Assertion {
    param([string]$Name, [scriptblock]$Block)
    try {
        $result = & $Block
        if ($result) {
            [void]$testResult.Add(@{Name=$Name; Status="PASS"})
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            return $true
        } else {
            [void]$testResult.Add(@{Name=$Name; Status="FAIL"})
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            return $false
        }
    } catch {
        [void]$testResult.Add(@{Name=$Name; Status="FAIL"})
        Write-Host "  [FAIL] $Name (exception: $_ )" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  VALIDACION FASE 2 - MODULOS POWERSHELL" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ====== 1. launcher.ps1 ======
Write-Host "[Test 1/10] Archivos del proyecto" -ForegroundColor Yellow
$launcherPath = Join-Path $ScriptRoot "launcher.ps1"
Test-Assertion -Name "1. launcher.ps1 existe" -Block { Test-Path $launcherPath }

# ====== 2. Modulos ======
foreach ($mod in $requiredModules) {
    $modPath = Join-Path $libDir $mod
    Test-Assertion -Name "2. Modulo $mod existe" -Block { Test-Path $modPath }
}

# ====== 3. Wrapper .bat ======
Write-Host "`n[Test 3/10] Wrapper .bat" -ForegroundColor Yellow
$batPath = Join-Path $ScriptRoot "Herramienta Avanzada.bat"
Test-Assertion -Name "3a. Bat existe" -Block { Test-Path $batPath }
Test-Assertion -Name "3b. Bat <= 60 lineas" -Block { (Get-Content $batPath).Count -le 60 }
Test-Assertion -Name "3c. Bat invoca launcher.ps1" -Block {
    (Get-Content $batPath -Raw) -match "launcher\.ps1"
}

# ====== 4. Config ======
Write-Host "`n[Test 4/10] Configuracion" -ForegroundColor Yellow
$configPath = Join-Path (Join-Path $ScriptRoot "config") "settings.ini"
Test-Assertion -Name "4a. settings.ini existe" -Block { Test-Path $configPath }
Test-Assertion -Name "4b. settings.ini tiene secciones" -Block {
    $content = Get-Content $configPath -Raw
    $content -match "\[Paths\]" -and $content -match "\[Logging\]" -and $content -match "\[Behavior\]"
}

# ====== 5. MenuHelpers funciones clave ======
Write-Host "`n[Test 5/10] MenuHelpers funciones compartidas" -ForegroundColor Yellow
$expectedFunctions = @(
    "Write-Title", "Write-Menu", "Read-MenuChoice",
    "Read-SecurePassword", "Read-YesNo", "Invoke-Log", "Get-ConfigValue"
)
foreach ($func in $expectedFunctions) {
    Test-Assertion -Name "5. Funcion $func existe" -Block {
        (Get-Command $func -ErrorAction SilentlyContinue) -ne $null
    }
}

# ====== 6. Cada modulo exporta Show-*Menu ======
Write-Host "`n[Test 6/10] Exportacion de menus por modulo" -ForegroundColor Yellow
$menuExports = @{
    "Maintenance.ps1"  = "Show-MaintenanceMenu"
    "Network.ps1"      = "Show-NetworkMenu"
    "SecurityPlus.ps1" = "Show-SecurityMenu"
    "Info.ps1"         = "Show-InfoMenu"
    "Power.ps1"        = "Show-PowerMenu"
    "ConfigSys.ps1"    = "Show-ConfigSysMenu"
    "Users.ps1"        = "Show-UsersMenu"
    "Services.ps1"     = "Show-ServicesMenu"
    "Backup.ps1"       = "Show-BackupMenu"
    "Processes.ps1"    = "Show-ProcessMenu"
    "Hosts.ps1"        = "Show-HostsMenu"
    "WiFi.ps1"         = "Show-WiFiMenu"
    "RDP.ps1"          = "Show-RDPMenu"
    "PowerPlan.ps1"    = "Show-PowerPlanMenu"
    "TaskScheduler.ps1"= "Show-TaskSchedulerMenu"
    "WindowsFeatures.ps1"="Show-WindowsFeaturesMenu"
    "DriveMapping.ps1" = "Show-DriveMappingMenu"
}
foreach ($mod in $menuExports.Keys) {
    $func = $menuExports[$mod]
    Test-Assertion -Name "6. $mod exporta $func" -Block {
        (Get-Command $func -ErrorAction SilentlyContinue) -ne $null
    }
}

# ====== 7. Launcher importa todos los modulos ======
Write-Host "`n[Test 7/10] Launcher importa modulos" -ForegroundColor Yellow
$launcherContent = Get-Content $launcherPath -Raw
foreach ($mod in $requiredModules) {
    Test-Assertion -Name "7. Launcher importa $mod" -Block {
        $launcherContent -match [regex]::Escape($mod)
    }
}

# ====== 8. Sintaxis PowerShell ======
Write-Host "`n[Test 8/10] Sintaxis PowerShell (Parse)" -ForegroundColor Yellow
$allPs1 = Get-ChildItem -Path $ScriptRoot -Recurse -Filter "*.ps1" | Where-Object { $_.FullName -notlike "*\test\*" }
foreach ($psFile in $allPs1) {
    Test-Assertion -Name "8. Parse $($psFile.Name)" -Block {
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $psFile.FullName, [ref]$null, [ref]$null
        )
        $true
    }
}

# ====== 9. Read-Config.ps1 ======
Write-Host "`n[Test 9/9] Read-Config.ps1" -ForegroundColor Yellow
Test-Assertion -Name "9a. Read-Config.ps1 existe" -Block { Test-Path $readConfigPath }
Test-Assertion -Name "9b. Read-Config parsea settings.ini" -Block {
    $raw = & $readConfigPath $configPath
    $parsed = ($raw -join "`n") | ConvertFrom-Json
    $parsed.Paths.BackupSourceDrivers -ne $null
}

# ====== RESUMEN ======
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FASE 2" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
$passed = ($testResult | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResult | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResult.Count
Write-Host "  Total: $total | Passed: $passed | Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "============================================`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "Tests fallados:" -ForegroundColor Red
    $testResult | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "Todos los tests pasaron. FASE 2 completa." -ForegroundColor Green
    exit 0
}
