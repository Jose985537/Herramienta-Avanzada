    # test/Validate-Phase1.ps1
# Validacion automatizada de FASE 1

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "FASE 1 VALIDATION - Herramienta Avanzada" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$pass = 0
$total = 0
$errors = @()
$rootDir = Resolve-Path (Join-Path $PSScriptRoot "..")

# Test 1: Config file exists
$total++
Write-Host "Test 1: Config file exists..." -ForegroundColor Yellow -NoNewline
$configPath = Join-Path $rootDir "config\settings.ini"
if (Test-Path $configPath) {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "config\settings.ini not found"
}

# Test 2: Read-Config.ps1 works
$total++
Write-Host "Test 2: Read-Config.ps1 parses INI..." -ForegroundColor Yellow -NoNewline
$readConfigPath = Join-Path $rootDir "lib\Read-Config.ps1"
if (Test-Path $readConfigPath) {
    try {
        $configJson = & $readConfigPath $configPath
        $config = ($configJson -join "`n") | ConvertFrom-Json
        if ($config.Paths.BackupSourceDrivers -eq "C:\Windows\System32\Drivers") {
            Write-Host " PASS" -ForegroundColor Green
            $pass++
        } else {
            Write-Host " FAIL (wrong value)" -ForegroundColor Red
            $errors += "Read-Config returned wrong BackupSourceDrivers"
        }
    } catch {
        Write-Host " FAIL ($($_.Exception.Message))" -ForegroundColor Red
        $errors += "Read-Config threw: $($_.Exception.Message)"
    }
} else {
    Write-Host " FAIL (file not found)" -ForegroundColor Red
    $errors += "lib\Read-Config.ps1 not found"
}

# Test 3: Invoke-Log funcion desde MenuHelpers
$total++
Write-Host "Test 3: Invoke-Log crea entradas de log..." -ForegroundColor Yellow -NoNewline
. (Join-Path $rootDir "lib\MenuHelpers.ps1")
$logDir = Join-Path $rootDir "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "app.log"
Invoke-Log -Message "Test validation entry"
Start-Sleep -Milliseconds 200
if (Test-Path $logFile) {
    $content = Get-Content $logFile
    $newEntries = $content | Where-Object { $_ -match "Test validation entry" }
    if ($newEntries.Count -gt 0) {
        Write-Host " PASS" -ForegroundColor Green
        $pass++
    } else {
        Write-Host " FAIL (entry not found)" -ForegroundColor Red
        $errors += "Log entry not found"
    }
} else {
    Write-Host " FAIL (no log file)" -ForegroundColor Red
    $errors += "Log file was not created"
}

# Test 4: Read-SecurePassword funcion existe
$total++
Write-Host "Test 4: Read-SecurePassword funcion existe..." -ForegroundColor Yellow -NoNewline
if ((Get-Command "Read-SecurePassword" -ErrorAction SilentlyContinue) -ne $null) {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "Read-SecurePassword function not found"
}

# Test 5: No set /p for passwords in batch
$total++
Write-Host "Test 5: No 'set /p' password prompts in .bat..." -ForegroundColor Yellow -NoNewline
$batPath = Join-Path $rootDir "Herramienta Avanzada.bat"
if (Test-Path $batPath) {
    $pwdMatches = Select-String -Path $batPath -Pattern 'set /p "[^"]*[Pp]ass' -ErrorAction SilentlyContinue
    if ($null -eq $pwdMatches -or $pwdMatches.Count -eq 0) {
        Write-Host " PASS" -ForegroundColor Green
        $pass++
    } else {
        Write-Host " FAIL ($($pwdMatches.Count) found)" -ForegroundColor Red
        foreach ($m in $pwdMatches) {
            $errors += "Line $($m.LineNumber): $($m.Line.Trim())"
        }
    }
} else {
    Write-Host " FAIL (file not found)" -ForegroundColor Red
    $errors += "Herramienta Avanzada.bat not found"
}

# Test 6: launcher.ps1 existe y es valido
$total++
Write-Host "Test 6: launcher.ps1 existe y es valido..." -ForegroundColor Yellow -NoNewline
$launcherPath = Join-Path $rootDir "launcher.ps1"
if (Test-Path $launcherPath) {
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile($launcherPath, [ref]$null, [ref]$null)
        Write-Host " PASS" -ForegroundColor Green
        $pass++
    } catch {
        Write-Host " FAIL (parse error)" -ForegroundColor Red
        $errors += "launcher.ps1 parse error: $_"
    }
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "launcher.ps1 not found"
}

# Test 7: Todos los 18 modulos existen
$total++
Write-Host "Test 7: Todos los 18 modulos existen..." -ForegroundColor Yellow -NoNewline
$libDir = Join-Path $rootDir "lib"
$modules = @("MenuHelpers.ps1","Maintenance.ps1","Network.ps1","SecurityPlus.ps1","Info.ps1","Power.ps1","ConfigSys.ps1","Users.ps1","Services.ps1","Backup.ps1","Processes.ps1","Hosts.ps1","WiFi.ps1","RDP.ps1","PowerPlan.ps1","TaskScheduler.ps1","WindowsFeatures.ps1","DriveMapping.ps1")
$missing = $modules | Where-Object { -not (Test-Path (Join-Path $libDir $_)) }
if ($missing.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "Modulos faltantes: $($missing -join ', ')"
}

# Test 8: Read-Config.ps1 tiene parametro ConfigPath obligatorio
$total++
Write-Host "Test 8: Read-Config.ps1 requiere ConfigPath..." -ForegroundColor Yellow -NoNewline
$readConfigContent = Get-Content $readConfigPath -Raw
if ($readConfigContent -match 'Mandatory=\$true' -and $readConfigContent -match 'ConfigPath') {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "Read-Config.ps1 missing mandatory ConfigPath parameter"
}

# Test 9: Sin referencias a modulos huerfanos
$total++
Write-Host "Test 9: Sin referencias a modulos huerfanos..." -ForegroundColor Yellow -NoNewline
$allCode = Get-ChildItem -Path $libDir -Filter "*.ps1" | Get-Content -Raw
$orphanRefs = @("Write-Log.ps1", "Read-Password.ps1")
$found = @()
foreach ($ref in $orphanRefs) {
    if ($allCode -match [regex]::Escape($ref)) { $found += $ref }
}
if ($found.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL ($($found -join ', ') referenced in code)" -ForegroundColor Red
    $errors += "Orphan references: $($found -join ', ')"
}

# Test 10: Write-Result funcion con estados
$total++
Write-Host "Test 10: Write-Result con estados OK/ERROR/WARN/INFO..." -ForegroundColor Yellow -NoNewline
$menuHelpersCode = Get-Content (Join-Path $libDir "MenuHelpers.ps1") -Raw
if ($menuHelpersCode -match 'Write-Result' -and $menuHelpersCode -match '"OK"|"ERROR"|"WARN"|"INFO"') {
    Write-Host " PASS" -ForegroundColor Green
    $pass++
} else {
    Write-Host " FAIL" -ForegroundColor Red
    $errors += "Write-Result status codes not found"
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
$resultColor = if ($pass -eq $total) { "Green" } elseif ($pass -ge ($total * 0.7)) { "Yellow" } else { "Red" }
Write-Host "RESULT: $pass / $total PASSED" -ForegroundColor $resultColor
Write-Host "======================================" -ForegroundColor Cyan

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "ERRORS:" -ForegroundColor Red
    foreach ($e in $errors) {
        Write-Host "  - $e" -ForegroundColor Red
    }
}

if ($pass -eq $total) {
    Write-Host ""
    Write-Host "FASE 1 VALIDATED SUCCESSFULLY" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "FASE 1 HAS ISSUES - review errors above" -ForegroundColor Yellow
    exit 1
}
