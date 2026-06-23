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

