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

