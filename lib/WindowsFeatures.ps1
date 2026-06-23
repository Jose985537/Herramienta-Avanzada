   # lib/WindowsFeatures.ps1
# Caracteristicas de Windows via DISM

    <#
    .SYNOPSIS
    Menu principal de caracteristicas de Windows
    #>
function Show-WindowsFeaturesMenu {
    do {
        Clear-Host
        Write-Title "CARACTERISTICAS DE WINDOWS (DISM)"
        Write-Menu -Options @(
            "  1. Listar caracteristicas disponibles",
            "  2. Habilitar una caracteristica",
            "  3. Deshabilitar una caracteristica",
            "  4. Ver estado de una caracteristica",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Invoke-ListFeatures }
            2 { Invoke-EnableFeature }
            3 { Invoke-DisableFeature }
            4 { Invoke-GetFeatureStatus }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Lista caracteristicas opcionales de Windows
    #>
function Invoke-ListFeatures {
    Clear-Host
    Write-Title "CARACTERISTICAS DISPONIBLES"
    try {
        Write-Result "Obteniendo lista (puede tardar unos segundos)..." "INFO"
        $features = Get-WindowsOptionalFeature -Online -ErrorAction Stop
        if (-not $features) { Write-Result "No se encontraron caracteristicas" "WARN"; Pause-Message; return }
        $enabled = $features | Where-Object { $_.State -eq 'Enabled' }
        $disabled = $features | Where-Object { $_.State -eq 'Disabled' }
        Write-Host "`nHabilitadas: $($enabled.Count)" -ForegroundColor Green
        Write-Host "Deshabilitadas: $($disabled.Count)" -ForegroundColor Yellow
        Write-Host "`nCaracteristicas deshabilitadas (primeras 50):`n" -ForegroundColor Cyan
        $disabled | Sort-Object FeatureName | Select-Object -First 50 |
            Format-Table FeatureName, State -AutoSize -Wrap
        if ($disabled.Count -gt 50) {
            Write-Host "... y $([Math]::Max(0, $disabled.Count - 50)) mas" -ForegroundColor Gray
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el estado de una caracteristica
    #>
function Invoke-GetFeatureStatus {
    Clear-Host
    Write-Title "ESTADO DE CARACTERISTICA"
    $feature = Read-Host "`nNombre de la caracteristica (ej: Microsoft-Windows-Subsystem-Linux)"
    if ([string]::IsNullOrWhiteSpace($feature)) { return }
    try {
        $result = Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction Stop
        Write-Host "`nCaracteristica: $($result.FeatureName)" -ForegroundColor Cyan
        Write-Host "Estado: " -NoNewline
        $color = if ($result.State -eq 'Enabled') { 'Green' } else { 'Red' }
        Write-Host $result.State -ForegroundColor $color
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Habilita una caracteristica de Windows
    #>
function Invoke-EnableFeature {
    Clear-Host
    Write-Title "HABILITAR CARACTERISTICA"
    $feature = Read-Host "`nNombre exacto de la caracteristica"
    if ([string]::IsNullOrWhiteSpace($feature)) { return }
    Write-Host "ADVERTENCIA: Puede requerir reinicio y descargar archivos." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Habilitar '$feature'")) { return }
    try {
        Write-Result "Habilitando... (puede tardar varios minutos)" "INFO"
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -ErrorAction Stop
        Write-Result "Caracteristica '$feature' habilitada" "OK"
        Invoke-Log -Message "Caracteristica Windows '$feature' habilitada"
        if (Read-YesNo -Prompt "Reiniciar ahora") {
            cmd /c "shutdown /r /t 10"
            return
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Deshabilita una caracteristica de Windows
    #>
function Invoke-DisableFeature {
    Clear-Host
    Write-Title "DESHABILITAR CARACTERISTICA"
    $feature = Read-Host "`nNombre exacto de la caracteristica"
    if ([string]::IsNullOrWhiteSpace($feature)) { return }
    if (-not (Read-YesNo -Prompt "Deshabilitar '$feature'")) { return }
    try {
        Write-Result "Deshabilitando..." "INFO"
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction Stop
        Write-Result "Caracteristica '$feature' deshabilitada" "OK"
        Invoke-Log -Message "Caracteristica Windows '$feature' deshabilitada"
        if (Read-YesNo -Prompt "Reiniciar ahora") {
            cmd /c "shutdown /r /t 10"
            return
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

