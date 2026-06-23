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

