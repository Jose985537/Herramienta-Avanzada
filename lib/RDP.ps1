   # lib/RDP.ps1
# Activar/Desactivar Escritorio Remoto

    <#
    .SYNOPSIS
    Menu principal de configuracion RDP
    #>
function Show-RDPMenu {
    do {
        Clear-Host
        Write-Title "ESCRITORIO REMOTO (RDP)"
        Write-Menu -Options @(
            "  1. Activar Escritorio Remoto",
            "  2. Desactivar Escritorio Remoto",
            "  3. Mostrar estado actual",
            "  4. Ver lista de conexiones activas",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Invoke-RDPOn }
            2 { Invoke-RDPOff }
            3 { Invoke-RDPStatus }
            4 { Invoke-RDPConnections }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Activa el servicio de Escritorio Remoto
    #>
function Invoke-RDPOn {
    Clear-Host
    Write-Title "ACTIVAR ESCRITORIO REMOTO"
    try {
        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        Set-ItemProperty -Path $regPath -Name fDenyTSConnections -Value 0 -Type DWord -ErrorAction Stop
        $null = cmd /c "netsh advfirewall firewall set rule group=`"Escritorio remoto`" new enable=Yes" 2>&1
        $null = cmd /c "netsh advfirewall firewall set rule group=`"Remote Desktop`" new enable=Yes" 2>&1
        Write-Result "Escritorio Remoto activado" "OK"
        Write-Host "Puerto por defecto: 3389" -ForegroundColor Gray
        Invoke-Log -Message "RDP activado"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Desactiva el servicio de Escritorio Remoto
    #>
function Invoke-RDPOff {
    Clear-Host
    Write-Title "DESACTIVAR ESCRITORIO REMOTO"
    if (-not (Read-YesNo -Prompt "Desactivar Escritorio Remoto")) { return }
    try {
        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        Set-ItemProperty -Path $regPath -Name fDenyTSConnections -Value 1 -Type DWord -ErrorAction Stop
        $null = cmd /c "netsh advfirewall firewall set rule group=`"Escritorio remoto`" new enable=No" 2>&1
        $null = cmd /c "netsh advfirewall firewall set rule group=`"Remote Desktop`" new enable=No" 2>&1
        Write-Result "Escritorio Remoto desactivado" "OK"
        Invoke-Log -Message "RDP desactivado"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el estado actual del Escritorio Remoto
    #>
function Invoke-RDPStatus {
    Clear-Host
    Write-Title "ESTADO DEL ESCRITORIO REMOTO"
    try {
        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
        $val = (Get-ItemProperty -Path $regPath -Name fDenyTSConnections -ErrorAction Stop).fDenyTSConnections
        $status = if ($val -eq 0) { "ACTIVADO" } else { "DESACTIVADO" }
        Write-Host "Escritorio Remoto: " -NoNewline
        Write-Host $status -ForegroundColor $(if ($val -eq 0) { "Green" } else { "Red" })
        $port = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name PortNumber -ErrorAction SilentlyContinue).PortNumber
        if ($port) { Write-Host "Puerto: $port" -ForegroundColor Gray }
        $fwRule = cmd /c "netsh advfirewall firewall show rule name=`"Remote Desktop*`" 2>nul | findstr /i `"Enabled:`""
        Write-Host "Firewall: " -NoNewline
        Write-Host $(if ($fwRule) { $fwRule.Trim() } else { "No disponible" }) -ForegroundColor Gray
        Write-Host "`nConexiones activas:" -ForegroundColor Cyan
        cmd /c "netstat -n | findstr :3389"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Lista las conexiones RDP activas en el sistema
    #>
function Invoke-RDPConnections {
    Clear-Host
    Write-Title "CONEXIONES RDP ACTIVAS"
    try {
        $sessions = cmd /c "query user" 2>&1
        $count = ($sessions | Measure-Object -Line).Lines
        if ($count -le 1) {
            Write-Result "No hay sesiones activas de Escritorio Remoto" "INFO"
        } else {
            $sessions | ForEach-Object { Write-Host $_ }
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

