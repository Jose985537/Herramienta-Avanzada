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

