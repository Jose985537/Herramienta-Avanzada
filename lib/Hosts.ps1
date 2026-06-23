   # lib/Hosts.ps1
# Editor de archivo hosts: listar, agregar, quitar entradas

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsBackup = "$env:windir\System32\drivers\etc\hosts.bak"

    <#
    .SYNOPSIS
    Menu principal del editor de hosts
    #>
function Show-HostsMenu {
    do {
        Clear-Host
        Write-Title "EDITOR DE ARCHIVO HOSTS"
        Write-Menu -Options @(
            "  1. Listar entradas activas",
            "  2. Agregar entrada (IP + hostname)",
            "  3. Eliminar entrada por hostname",
            "  4. Bloquear sitio web (redirigir a 0.0.0.0)",
            "  5. Ver contenido completo del hosts",
            "  6. Restaurar copia de seguridad (.bak)",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 { Invoke-ListHosts }
            2 { Invoke-AddHostEntry }
            3 { Invoke-RemoveHostEntry }
            4 { Invoke-BlockWebsite }
            5 { Invoke-ViewHostsRaw }
            6 { Invoke-RestoreHostsBackup }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Obtiene entradas activas del archivo hosts
    #>
function Get-HostsEntries {
    if (-not (Test-Path $hostsPath)) { return @() }
    $entries = Get-Content $hostsPath | Where-Object {
        $_.Trim() -ne '' -and $_.Trim() -notmatch '^#'
    }
    return $entries
}

    <#
    .SYNOPSIS
    Muestra entradas activas del archivo hosts
    #>
function Invoke-ListHosts {
    Clear-Host
    Write-Title "ENTRADAS ACTIVAS EN HOSTS"
    $entries = Get-HostsEntries
    if ($entries.Count -eq 0) {
        Write-Result "No hay entradas activas (comentarios y vacios ignorados)" "INFO"
    } else {
        Write-Host "`n  IP`t`t`tHOSTNAME" -ForegroundColor Cyan
        Write-Host "  " + ("-" * 55) -ForegroundColor Gray
        foreach ($e in $entries) {
            $parts = $e.Trim() -split '\s+'
            if ($parts.Count -ge 2) {
                Write-Host ("  {0,-20} {1}" -f $parts[0], $parts[1]) -ForegroundColor White
            }
        }
        Write-Host "`n  Total: $($entries.Count) entradas" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Agrega una entrada al archivo hosts
    #>
function Invoke-AddHostEntry {
    Clear-Host
    Write-Title "AGREGAR ENTRADA AL HOSTS"
    $ip = Read-Host "`nDireccion IP (ej: 127.0.0.1)"
    $hostname = Read-Host "Hostname (ej: ejemplo.local)"
    if ([string]::IsNullOrWhiteSpace($ip) -or [string]::IsNullOrWhiteSpace($hostname)) {
        Write-Result "Operacion cancelada - datos incompletos" "WARN"
        Pause-Message; return
    }
    try {
        Add-Content -Path $hostsPath -Value "`n$ip`t$hostname" -ErrorAction Stop
        Invoke-Log -Message "Hosts: agregada entrada $ip $hostname"
        Write-Result "Entrada agregada: $ip  $hostname" "OK"
        Write-Result "Ejecute 'ipconfig /flushdns' si el cambio no se refleja" "INFO"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina una entrada del archivo hosts
    #>
function Invoke-RemoveHostEntry {
    Clear-Host
    Write-Title "ELIMINAR ENTRADA DEL HOSTS"
    $entries = Get-HostsEntries
    if ($entries.Count -eq 0) {
        Write-Result "No hay entradas para eliminar" "WARN"
        Pause-Message; return
    }
    Write-Host "`nEntradas actuales:" -ForegroundColor Cyan
    $i = 1
    $lookup = @{}
    foreach ($e in $entries) {
        $parts = $e.Trim() -split '\s+'
        $display = if ($parts.Count -ge 2) { "$($parts[0])  $($parts[1])" } else { $e.Trim() }
        Write-Host "  $i. $display" -ForegroundColor White
        $lookup[$i] = $e.Trim()
        $i++
    }
    $sel = Read-Host "`nNumero a eliminar (0 = cancelar)"
    if ($sel -notmatch '^\d+$' -or [int]$sel -lt 1 -or [int]$sel -gt $lookup.Count) {
        Write-Result "Operacion cancelada" "WARN"; Pause-Message; return
    }
    $target = $lookup[[int]$sel]
    $targetParts = $target -split '\s+'
    try {
        $content = Get-Content $hostsPath
        $removed = $false
        $newContent = $content | Where-Object {
            if ($removed) { return $true }
            $lineParts = $_.Trim() -split '\s+'
            if ($lineParts.Count -ge 2 -and $targetParts.Count -ge 2 -and $lineParts[0] -eq $targetParts[0] -and $lineParts[1] -eq $targetParts[1]) {
                $removed = $true; return $false
            }
            if ($_.Trim() -eq $target) {
                $removed = $true; return $false
            }
            return $true
        }
        Set-Content -Path $hostsPath -Value $newContent -Force -ErrorAction Stop
        Invoke-Log -Message "Hosts: eliminada entrada '$target'"
        Write-Result "Entrada eliminada: $target" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Bloquea un sitio web via archivo hosts
    #>
function Invoke-BlockWebsite {
    Clear-Host
    Write-Title "BLOQUEAR SITIO WEB"
    $domain = Read-Host "`nDominio a bloquear (ej: facebook.com)"
    if ([string]::IsNullOrWhiteSpace($domain)) {
        Write-Result "Operacion cancelada" "WARN"; Pause-Message; return
    }
    try {
        $exists = Get-HostsEntries | Where-Object { $_ -match [regex]::Escape($domain) }
        if ($exists) {
            Write-Result "El dominio ya tiene una entrada en hosts" "WARN"
            Write-Host "Existente: $exists" -ForegroundColor Yellow
            Pause-Message; return
        }
        Add-Content -Path $hostsPath -Value "`n0.0.0.0`t$domain" -ErrorAction Stop
        Add-Content -Path $hostsPath -Value "0.0.0.0`twww.$domain" -ErrorAction Stop
        Invoke-Log -Message "Hosts: bloqueado $domain y www.$domain"
        Write-Result "Sitio bloqueado: $domain (redirigido a 0.0.0.0)" "OK"
        Write-Result "Ejecute 'ipconfig /flushdns' si el cambio no se refleja" "INFO"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el contenido completo del archivo hosts
    #>
function Invoke-ViewHostsRaw {
    Clear-Host
    Write-Title "CONTENIDO COMPLETO DEL ARCHIVO HOSTS"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    $lines = Get-Content $hostsPath
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        if ($line.Trim() -eq '' -or $line.Trim() -match '^#') {
            Write-Host ("{0,4}: {1}" -f $lineNum, $line) -ForegroundColor DarkGray
        } else {
            Write-Host ("{0,4}: {1}" -f $lineNum, $line) -ForegroundColor White
        }
    }
    Write-Host "`n  $lineNum lineas totales" -ForegroundColor Gray
    Pause-Message
}

    <#
    .SYNOPSIS
    Restaura archivo hosts desde backup
    #>
function Invoke-RestoreHostsBackup {
    Clear-Host
    Write-Title "RESTAURAR COPIA DE SEGURIDAD"
    if (-not (Test-Path $hostsBackup)) {
        Write-Result "No se encontro copia de seguridad (hosts.bak)" "WARN"
        Pause-Message; return
    }
    if (-not (Read-YesNo -Prompt "Restaurar hosts.bak? Se perdera el contenido actual")) { return }
    try {
        Copy-Item -Path $hostsBackup -Destination $hostsPath -Force -ErrorAction Stop
        Invoke-Log -Message "Hosts: restaurado desde hosts.bak"
        Write-Result "Archivo hosts restaurado desde backup" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

