   # lib/PowerPlan.ps1
# Planes de energia del sistema

    <#
    .SYNOPSIS
    Menu principal de planes de energia
    #>
function Show-PowerPlanMenu {
    do {
        Clear-Host
        Write-Title "PLANES DE ENERGIA"
        Write-Menu -Options @(
            "  1. Plan equilibrado (Balanceado)",
            "  2. Plan maximo rendimiento",
            "  3. Plan ahorro de energia",
            "  4. Listar todos los planes",
            "  5. Ver plan activo actual",
            "  6. Crear plan personalizado",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 { Invoke-SetPowerPlanSmart "Equilibrado" "Balanced" }
            2 { Invoke-SetPowerPlanSmart "Alto rendimiento" "High performance" }
            3 { Invoke-SetPowerPlanSmart "Ahorro de energia" "Power saver" }
            4 { Invoke-ListPowerPlans }
            5 { Invoke-ShowActivePlan }
            6 { Invoke-CreatePowerPlan }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Obtiene el GUID de un plan de energia por nombre
    #>
function Get-PowerPlanGuid {
    param([string]$PlanName)
    $plans = cmd /c "powercfg /list" 2>&1
    $escaped = [regex]::Escape($PlanName)
    foreach ($p in $plans) {
        if ($p -match $escaped) {
            if ($p -match '([0-9a-f\-]{36})') {
                return $matches[1]
            }
        }
    }
    return $null
}

    <#
    .SYNOPSIS
    Obtiene GUID buscando por nombre ES y EN
    #>
function Get-PowerPlanGuidSmart {
    param([string]$SpanishName, [string]$EnglishName)
    $guid = Get-PowerPlanGuid $SpanishName
    if ($guid) { return $guid }
    $guid = Get-PowerPlanGuid $EnglishName
    if ($guid) { return $guid }
    return $null
}

    <#
    .SYNOPSIS
    Activa un plan de energia por nombre
    #>
function Invoke-SetPowerPlan {
    param([string]$PlanName)
    Clear-Host
    Write-Title "PLAN DE ENERGIA: $PlanName"
    try {
        $guid = Get-PowerPlanGuid $PlanName
        if (-not $guid) {
            Write-Result "Plan '$PlanName' no encontrado" "WARN"
            Write-Host "Ejecute powercfg /list para ver planes disponibles" -ForegroundColor Gray
            Pause-Message; return
        }
        cmd /c "powercfg /s $guid" *>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Result "Plan '$PlanName' activado" "OK"
            Invoke-Log -Message "Plan de energia cambiado a $PlanName"
        } else {
            Write-Result "Error al cambiar plan" "ERROR"
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Activa plan de energia con busqueda bilingue
    #>
function Invoke-SetPowerPlanSmart {
    param([string]$SpanishName, [string]$EnglishName)
    $guid = Get-PowerPlanGuidSmart $SpanishName $EnglishName
    if (-not $guid) {
        Write-Result "Plan '$SpanishName/$EnglishName' no encontrado" "WARN"
        Write-Host "Ejecute powercfg /list para ver planes disponibles" -ForegroundColor Gray
        Pause-Message; return
    }
    cmd /c "powercfg /s $guid" *>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Plan activado" "OK"
        Invoke-Log -Message "Plan de energia cambiado"
    } else {
        Write-Result "Error al cambiar plan" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Lista todos los planes de energia
    #>
function Invoke-ListPowerPlans {
    Clear-Host
    Write-Title "PLANES DE ENERGIA DISPONIBLES"
    try {
        $output = cmd /c "powercfg /list" 2>&1
        $output | ForEach-Object { Write-Host $_ }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el plan de energia activo actual
    #>
function Invoke-ShowActivePlan {
    Clear-Host
    Write-Title "PLAN DE ENERGIA ACTIVO"
    try {
        $output = cmd /c "powercfg /getactivescheme" 2>&1
        Write-Host "Plan activo: " -NoNewline
        if ($output -match ': (.+)$') {
            Write-Host $matches[1] -ForegroundColor Green
        } else {
            Write-Host $output -ForegroundColor Green
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Crea un plan de energia personalizado
    #>
function Invoke-CreatePowerPlan {
    Clear-Host
    Write-Title "CREAR PLAN PERSONALIZADO"
    $name = Read-Host "`nNombre del nuevo plan"
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    try {
        $guid = Get-PowerPlanGuidSmart "Equilibrado" "Balanced"
        if (-not $guid) {
            Write-Result "No se encontro plan base 'Balanced/Equilibrado'" "ERROR"; Pause-Message; return
        }
        $null = cmd /c "powercfg /duplicatescheme $guid" 2>&1
        $newGuid = cmd /c "powercfg /list" 2>&1 | Select-Object -Last 1
        if ($newGuid -match '([0-9a-f\-]{36})') {
            $newGuid = $matches[1]
            $null = cmd /c "powercfg /changename $newGuid `"$name`"" 2>&1
            Write-Result "Plan '$name' creado" "OK"
            if (Read-YesNo -Prompt "Activar este plan ahora") {
                $null = cmd /c "powercfg /s $newGuid" 2>&1
                Write-Result "Plan '$name' activado" "OK"
            }
            Invoke-Log -Message "Plan de energia '$name' creado"
        } else {
            Write-Result "Error al crear plan" "ERROR"
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

