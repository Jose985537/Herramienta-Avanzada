   # lib/Network.ps1
# Red, conexiones y carpetas compartidas

    <#
    .SYNOPSIS
    Menu principal del modulo de red
    #>
function Show-NetworkMenu {
    do {
        Clear-Host
        Write-Title "RED, CONEXIONES Y CARPETAS COMPARTIDAS"
        Write-Menu -Options @(
            "  1. Ver configuracion de red",
            "  2. Renovar direccion IP",
            "  3. Ver aplicaciones usando puerto 443",
            "  4. Limpiar cache DNS",
            "  5. Restablecer TCP/IP",
            "  6. Adaptadores de red",
            "  7. Listar carpetas compartidas",
            "  8. Compartir una carpeta",
            "  9. Eliminar una carpeta compartida",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 9
        switch ($opt) {
            1 { Show-NetworkConfig }
            2 { Renew-IP }
            3 { Show-Port443 }
            4 { Flush-DNS }
            5 { Reset-TCPIP }
            6 { Show-NetAdapters }
            7 { Show-Shares }
            8 { New-Share }
            9 { Remove-Share }
        }
    } while ($opt -ne 0)
}

   <#
   .SYNOPSIS
   Muestra la configuracion de red actual del equipo
   #>
function Show-NetworkConfig {
    Clear-Host
    Write-Title "CONFIGURACION DE RED ACTUAL"
    ipconfig /all
    Pause-Message
}

   <#
   .SYNOPSIS
   Renueva la direccion IP de los adaptadores de red
   #>
function Renew-IP {
    Clear-Host
    Write-Title "RENOVACION DE DIRECCION IP"
    Write-Result "Liberando IP..." "INFO"
    cmd /c "ipconfig /release" | Out-Null
    Write-Result "Renovando IP..." "INFO"
    cmd /c "ipconfig /renew" | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Result "IP renovada correctamente" "OK" }
    else { Write-Result "Error al renovar IP" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Lista las aplicaciones que usan el puerto 443
   #>
function Show-Port443 {
    Clear-Host
    Write-Title "APLICACIONES USANDO PUERTO 443"
    cmd /c "netstat -ano | findstr :443"
    Pause-Message
}

   <#
   .SYNOPSIS
   Limpia la cache de resolucion DNS del sistema
   #>
function Flush-DNS {
    Clear-Host
    Write-Title "LIMPIEZA DE CACHE DNS"
    cmd /c "ipconfig /flushdns"
    if ($LASTEXITCODE -eq 0) { Write-Result "Cache DNS limpiada" "OK" }
    else { Write-Result "Error al limpiar cache DNS" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Restablece la pila TCP/IP a configuracion predeterminada
   #>
function Reset-TCPIP {
    Clear-Host
    Write-Title "RESTABLECER CONFIGURACION TCP/IP"
    Write-Result "Restableciendo TCP/IP..." "INFO"
    cmd /c "netsh int ip reset"
    if ($LASTEXITCODE -eq 0) { Write-Result "TCP/IP restablecido" "OK" }
    else { Write-Result "Error al restablecer TCP/IP" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Muestra informacion detallada de los adaptadores de red
   #>
function Show-NetAdapters {
    Clear-Host
    Write-Title "ADAPTADORES DE RED DETALLADOS"
    try {
        $adapters = Get-NetAdapter | Sort-Object Name
        if (-not $adapters) { Write-Result "No se detectaron adaptadores" "WARN"; Pause-Message; return }
        foreach ($adapter in $adapters) {
            $mac = $adapter.MacAddress
            if ($mac.Length -eq 12) { $mac = ($mac -replace '(..(?!$))', '$1-').ToUpper() }
            $status = if ($adapter.Status -eq 'Up') { "Conectado" } else { "Desconectado" }
            $type = if ($adapter.InterfaceDescription -like "*Virtual*") { "Virtual" } else { "Fisico" }
            $ipInfo = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $ip = if ($ipInfo) { $ipInfo.IPAddress } else { "No asignada" }
            Write-Host "=== $($adapter.Name) ($($adapter.InterfaceDescription)) ===" -ForegroundColor Cyan
            Write-Host "  Tipo   : $type"
            Write-Host "  Estado : $status"
            Write-Host "  MAC    : $mac"
            Write-Host "  IPv4   : $ip"
            Write-Host "  Veloc. : $($adapter.LinkSpeed)"
        }
    } catch {
        Write-Result "Error al obtener adaptadores: $_" "ERROR"
    }
    Pause-Message
}

   <#
   .SYNOPSIS
   Lista los recursos compartidos de red actuales
   #>
function Show-Shares {
    Clear-Host
    Write-Title "CARPETAS COMPARTIDAS"
    cmd /c "net share"
    Pause-Message
}

   <#
   .SYNOPSIS
   Crea un nuevo recurso compartido de red
   #>
function New-Share {
    Clear-Host
    Write-Title "COMPARTIR UNA CARPETA"
    $path = Read-Host "Ruta de la carpeta a compartir"
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) {
        Write-Result "Ruta no valida" "ERROR"; Pause-Message; return
    }
    $name = Read-Host "Nombre del recurso compartido"
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    cmd /c "net share `"$name`"=`"$path`""
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Carpeta compartida correctamente" "OK"
        Invoke-Log -Message "Carpeta $path compartida como $name"
    } else { Write-Result "Error al compartir" "ERROR" }
    Pause-Message
}

   <#
   .SYNOPSIS
   Elimina un recurso compartido de red existente
   #>
function Remove-Share {
    Clear-Host
    Write-Title "ELIMINAR CARPETA COMPARTIDA"
    $name = Read-Host "Nombre del recurso compartido a eliminar"
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    if (-not (Read-YesNo -Prompt "Eliminar recurso compartido '$name'")) { return }
    cmd /c "net share `"$name`" /delete"
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Recurso compartido eliminado" "OK"
        Invoke-Log -Message "Recurso compartido $name eliminado"
    } else { Write-Result "Error al eliminar" "ERROR" }
    Pause-Message
}

