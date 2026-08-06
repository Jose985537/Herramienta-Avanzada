    # lib/Hosts.ps1
# Editor de archivo hosts: listar, agregar, bloquear, desbloquear, redirigir y restaurar

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$hostsBackup = "$env:windir\System32\drivers\etc\hosts.bak"
$script:hostsAvStatusCache = @{ Time = [DateTime]::MinValue; Data = $null }

    <#
    .SYNOPSIS
    Menu principal del editor de hosts
    #>
function Show-HostsMenu {
    do {
        Clear-Host
        Write-Title "EDITOR DE ARCHIVO HOSTS"
        Show-AntivirusBanner
        Write-Menu -Options @(
            "  1. Listar entradas activas",
            "  2. Agregar entrada (IP + hostname)",
            "  3. Eliminar entrada por hostname",
            "  4. Bloquear sitio web (redirigir a 0.0.0.0)",
            "  5. Bloquear sitios desde archivo de texto",
            "  6. Habilitar/Deshabilitar entrada (toggle)",
            "  7. Ver contenido completo del hosts",
            "  8. Resumen y estadisticas",
            "  9. Crear copia de seguridad (.bak)",
            " 10. Restaurar copia de seguridad (.bak)",
            " 11. Restaurar hosts por defecto de Windows",
            " 12. Ver y desbloquear sitios bloqueados",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 12
        switch ($opt) {
            1  { Invoke-ListHosts }
            2  { Invoke-AddHostEntry }
            3  { Invoke-RemoveHostEntry }
            4  { Invoke-BlockWebsite }
            5  { Invoke-BlockListFromFile }
            6  { Invoke-ToggleHostEntry }
            7  { Invoke-ViewHostsRaw }
            8  { Show-HostsSummary }
            9  { Invoke-CreateHostsBackup }
            10 { Invoke-RestoreHostsBackup }
            11 { Invoke-RestoreDefaultHosts }
            12 { Invoke-UnblockFromList }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Detecta el antivirus instalado y su estado (SecurityCenter2 + proceso avp.exe)
    Resultado: hashtable con Detected, Name, Active, Source. Con cache de 30 s.
    #>
function Get-AntivirusStatus {
    $now = [DateTime]::Now
    if ($script:hostsAvStatusCache.Data -and ($now - $script:hostsAvStatusCache.Time).TotalSeconds -lt 30) {
        return $script:hostsAvStatusCache.Data
    }
    $st = @{ Detected = $false; Name = ""; Active = $false; Source = "" }
    $engineRunning = $false
    $names = @()
    try {
        foreach ($p in @(Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue)) {
            if ($p.displayName) { $names += ($p.displayName.Trim() -replace '\u00A0', ' ') }
            if (($p.productState -band 0x1000) -eq 0x1000) { $engineRunning = $true }
        }
    } catch {}
    $kasp = @($names | Where-Object { $_ -match 'Kaspersky' })
    $avpUp = [bool](Get-Process avp -ErrorAction SilentlyContinue)
    if ($kasp.Count -gt 0) {
        $st.Detected = $true; $st.Name = $kasp[0]
        $st.Active = $avpUp -or $engineRunning; $st.Source = "SecurityCenter2+proceso"
    } elseif ($avpUp) {
        $st.Detected = $true; $st.Name = "Kaspersky"; $st.Active = $true; $st.Source = "proceso avp.exe"
    } elseif ($names.Count -gt 0) {
        $st.Detected = $true; $st.Name = $names[0]; $st.Active = $engineRunning; $st.Source = "SecurityCenter2"
    }
    $script:hostsAvStatusCache.Time = $now
    $script:hostsAvStatusCache.Data = $st
    return $st
}

    <#
    .SYNOPSIS
    Muestra el banner de estado del antivirus en el editor de hosts
    #>
function Show-AntivirusBanner {
    $av = Get-AntivirusStatus
    Write-Host ""
    if (-not $av.Detected) {
        Write-Host "[SEGURIDAD] NO SE DETECTA ANTIVIRUS" -ForegroundColor Red
        Write-Host "            Requisito de seguridad no cumplido." -ForegroundColor Red
    } elseif ($av.Active) {
        Write-Host ("[SEGURIDAD] Antivirus activo : {0}" -f $av.Name) -ForegroundColor Green
        Write-Host "            Motor            : EN EJECUCION" -ForegroundColor Green
        if ($av.Name -match 'Kaspersky') {
            Write-Host "            Aviso            : Kaspersky puede bloquear cambios en hosts." -ForegroundColor Yellow
            Write-Host "                              Si una operacion falla, pausa su proteccion." -ForegroundColor Yellow
        }
    } else {
        Write-Host ("[SEGURIDAD] Antivirus detectado : {0}" -f $av.Name) -ForegroundColor Yellow
        Write-Host "            Motor               : INACTIVO" -ForegroundColor Yellow
        Write-Host "            Aviso               : Active la proteccion antes de continuar." -ForegroundColor Yellow
    }
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
        Invoke-EnsureHostsBackup
        Invoke-HostsWrite -Append -Value "`n$ip`t$hostname"
        Invoke-Log -Message "Hosts: agregada entrada $ip $hostname"
        Write-Result "Entrada agregada: $ip  $hostname" "OK"
        Invoke-FlushDns
    } catch { Invoke-HostsWriteError $_ }
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
        Invoke-EnsureHostsBackup
        Invoke-HostsWrite -Value $newContent
        Invoke-Log -Message "Hosts: eliminada entrada '$target'"
        Write-Result "Entrada eliminada: $target" "OK"
    } catch { Invoke-HostsWriteError $_ }
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
    $domain = $domain.Trim()
    $domain = $domain -replace '^www\.\s*', ''
    try {
        $esc = [regex]::Escape($domain)
        $exists = @(Get-HostsEntries | Where-Object { $_ -match "^\s*(0\.0\.0\.0|::)\s+(www\.\s*)?$esc\s*$" })
        if ($exists) {
            Write-Result "El dominio ya tiene una entrada en hosts" "WARN"
            Write-Host "Existente: $exists" -ForegroundColor Yellow
            Pause-Message; return
        }
        Invoke-EnsureHostsBackup
        Invoke-HostsWrite -Append -Value "`n0.0.0.0`t$domain"
        Invoke-HostsWrite -Append -Value "0.0.0.0`twww.$domain"
        Invoke-HostsWrite -Append -Value "`n::`t$domain"
        Invoke-HostsWrite -Append -Value "::`twww.$domain"
        Invoke-Log -Message "Hosts: bloqueado $domain y www.$domain (IPv4+IPv6)"
        Write-Result "Sitio bloqueado: $domain (redirigido a 0.0.0.0 y ::)" "OK"
        Invoke-FlushDns
    } catch { Invoke-HostsWriteError $_ }
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
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Desbloquea un sitio web eliminando sus entradas 0.0.0.0 del hosts
    #>
function Invoke-UnblockWebsite {
    param([string]$Domain = "")
    Clear-Host
    Write-Title "DESBLOQUEAR SITIO WEB"
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        $Domain = Read-Host "`nDominio a desbloquear (ej: facebook.com)"
    }
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        Write-Result "Operacion cancelada" "WARN"; Pause-Message; return
    }
    $Domain = $Domain.Trim()
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    $esc = [regex]::Escape($Domain)
    $pattern = "^\s*(0\.0\.0\.0|::)\s+(www\.\s*)?$esc\s*$"
    $content = Get-Content $hostsPath
    $blocked = @($content | Where-Object { $_ -match $pattern })
    if ($blocked.Count -eq 0) {
        Write-Result "No se encontro bloqueo para $Domain" "WARN"
        Pause-Message; return
    }
    Write-Host "`nEntradas a eliminar:" -ForegroundColor Cyan
    foreach ($b in $blocked) { Write-Host "  $b" -ForegroundColor White }
    if (-not (Read-YesNo -Prompt "Confirmar desbloqueo")) { return }
    try {
        $newContent = $content | Where-Object { $_ -notmatch $pattern }
        Invoke-EnsureHostsBackup
        Invoke-HostsWrite -Value $newContent
        Invoke-Log -Message "Hosts: desbloqueado $Domain"
        Write-Result "Sitio desbloqueado: $Domain" "OK"
        Invoke-FlushDns
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Lista los sitios bloqueados y permite desbloquearlos por seleccion
    #>
function Invoke-UnblockFromList {
    Clear-Host
    Write-Title "SITIOS BLOQUEADOS"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    $filter = ""
    while ($true) {
        Clear-Host
        Write-Title "SITIOS BLOQUEADOS"
        $domains = @()
        foreach ($b in @(Get-HostsEntries | Where-Object { ($_ -split '\s+')[0] -in @('0.0.0.0', '127.0.0.1', '::') })) {
            $name = ($b.Trim() -replace '^\S+\s+', '').Trim()
            $name = $name -replace '^www\.\s*', ''
            if ($name -ne '' -and $domains -notcontains $name) { $domains += $name }
        }
        if ($filter) {
            $domains = @($domains | Where-Object { $_ -match [regex]::Escape($filter) })
        }
        if ($domains.Count -eq 0) {
            Write-Result "No hay sitios bloqueados$(if ($filter) { " que coincidan con '$filter'" })" "WARN"
            Pause-Message; return
        }
        Write-Host "`nSitios bloqueados: $($domains.Count)$(if ($filter) { " (filtro: '$filter')" })" -ForegroundColor Cyan
        $n = 1
        foreach ($d in $domains) {
            Write-Host ("  {0,3}. {1}" -f $n, $d) -ForegroundColor White
            $n++
        }
        Write-Host ""
        $sel = Read-Host "Numero a desbloquear (0 = volver, o escriba texto para filtrar)"
        if ($sel.Trim() -eq "0") { return }
        if ($sel -match '^\d+$') {
            $num = [int]$sel
            if ($num -ge 1 -and $num -le $domains.Count) {
                Invoke-UnblockWebsite -Domain $domains[$num - 1]
            } else {
                Write-Host "Numero fuera de rango" -ForegroundColor Red
                Pause-Message
            }
        } else {
            $filter = $sel.Trim()
        }
    }
}

    <#
    .SYNOPSIS
    Bloquea multiples sitios web desde un archivo de texto
    #>
function Invoke-BlockListFromFile {
    Clear-Host
    Write-Title "BLOQUEAR SITIOS DESDE ARCHIVO"
    $file = Read-Host "`nRuta del archivo (1 dominio por linea)"
    if ([string]::IsNullOrWhiteSpace($file)) {
        Write-Result "Operacion cancelada" "WARN"; Pause-Message; return
    }
    if (-not (Test-Path $file)) {
        Write-Result "Archivo no encontrado: $file" "ERROR"; Pause-Message; return
    }
    $domains = Get-Content $file | Where-Object {
        $_.Trim() -ne '' -and $_.Trim() -notmatch '^#'
    }
    if ($domains.Count -eq 0) {
        Write-Result "El archivo no contiene dominios validos" "WARN"; Pause-Message; return
    }
    Write-Host "`nSe bloquearan $($domains.Count) dominios:" -ForegroundColor Cyan
    foreach ($d in $domains) { Write-Host "  $($d.Trim())" -ForegroundColor White }
    if (-not (Read-YesNo -Prompt "Confirmar bloqueo masivo")) { return }
    try {
        $added = 0
        $skipped = 0
        $newLines = @()
        foreach ($d in $domains) {
            $domain = $d.Trim()
            $domain = $domain -replace '^www\.\s*', ''
            if ([string]::IsNullOrWhiteSpace($domain)) { continue }
            $esc = [regex]::Escape($domain)
            $pattern = "^\s*0\.0\.0\.0\s+(www\.)?$esc\s*$"
            $exists = Get-HostsEntries | Where-Object { $_ -match $pattern }
            if ($exists) { $skipped++; continue }
            if ($newLines.Count -eq 0) {
                $newLines += "`n0.0.0.0`t$domain"
            } else {
                $newLines += "0.0.0.0`t$domain"
            }
            $newLines += "0.0.0.0`twww.$domain"
            $added++
        }
        if ($newLines.Count -gt 0) {
            Invoke-EnsureHostsBackup
            Invoke-HostsWrite -Append -Value $newLines
        }
        Invoke-Log -Message "Hosts: bloqueo masivo completado ($added agregados, $skipped omitidos)"
        Write-Result "Bloqueo completado: $added agregados, $skipped omitidos" "OK"
        Invoke-FlushDns
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Comenta o descomenta una entrada del hosts (toggle con #)
    #>
function Invoke-ToggleHostEntry {
    Clear-Host
    Write-Title "HABILITAR/DESHABILITAR ENTRADA"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    $lines = Get-Content $hostsPath
    $toggleable = @()
    $idx = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $clean = $lines[$i].Trim() -replace '^#+\s*', ''
        $parts = $clean -split '\s+'
        if ($parts.Count -ge 2 -and [net.ipaddress]::TryParse($parts[0], [ref]$null)) {
            $toggleable += $lines[$i]
            $idx += $i
        }
    }
    if ($toggleable.Count -eq 0) {
        Write-Result "No hay entradas para alternar" "WARN"; Pause-Message; return
    }
    Write-Host "`nEntradas (IP + hostname):" -ForegroundColor Cyan
    $n = 1
    foreach ($t in $toggleable) {
        $clean = $t.Trim() -replace '^#+\s*', ''
        $parts = $clean -split '\s+'
        $state = if ($t.Trim().StartsWith('#')) { "DESHABILITADA" } else { "habilitada" }
        Write-Host ("  {0,2}. {1,-20} {2}  [{3}]" -f $n, $parts[0], $parts[1], $state) -ForegroundColor White
        $n++
    }
    $sel = Read-Host "`nNumero a alternar (0 = cancelar)"
    if ($sel -notmatch '^\d+$' -or [int]$sel -lt 1 -or [int]$sel -gt $toggleable.Count) {
        Write-Result "Operacion cancelada" "WARN"; Pause-Message; return
    }
    $lineNum = $idx[[int]$sel - 1]
    $target = $lines[$lineNum]
    try {
        if ($target.Trim().StartsWith('#')) {
            $lines[$lineNum] = ($target -replace '^#+\s*', '')
        } else {
            $lines[$lineNum] = "# " + $target
        }
        Invoke-EnsureHostsBackup
        Invoke-HostsWrite -Value $lines
        Invoke-Log -Message "Hosts: toggle sobre '$($target.Trim())'"
        Write-Result "Entrada alternada: $($lines[$lineNum])" "OK"
        Invoke-FlushDns
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra resumen y estadisticas del archivo hosts
    #>
function Show-HostsSummary {
    Clear-Host
    Write-Title "RESUMEN Y ESTADISTICAS DEL HOSTS"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    $lines = Get-Content $hostsPath
    $total = $lines.Count
    $active = @(Get-HostsEntries).Count
    $commented = @($lines | Where-Object { $_.Trim() -match '^#' }).Count
    $empty = @($lines | Where-Object { $_.Trim() -eq '' }).Count
    $activeLines = Get-HostsEntries
    $blocks = @($activeLines | Where-Object { ($_ -split '\s+')[0] -in @('0.0.0.0', '127.0.0.1', '::') }).Count
    $malformed = @($activeLines | Where-Object { (@($_ -split '\s+')).Count -lt 2 }).Count
    Write-Host ""
    Write-Host "  Lineas totales        : $total" -ForegroundColor White
    Write-Host "  Entradas activas      : $active" -ForegroundColor Cyan
    Write-Host "  Entradas comentadas   : $commented" -ForegroundColor Gray
    Write-Host "  Lineas vacias         : $empty" -ForegroundColor Gray
    Write-Host "  Sitios bloqueados     : $blocks" -ForegroundColor Yellow
    Write-Host "  Entradas malformadas  : $malformed" -ForegroundColor $(if ($malformed -gt 0) { "Red" } else { "Green" })
    if ($malformed -gt 0) {
        Write-Host "`n  Aviso: entradas activas sin hostname detectadas:" -ForegroundColor Yellow
        foreach ($m in $activeLines) {
            if ((@($m -split '\s+')).Count -lt 2) { Write-Host "    $m" -ForegroundColor White }
        }
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Crea hosts.bak automatico solo si no existe (idempotente)
    #>
function Invoke-EnsureHostsBackup {
    if (-not (Test-Path $hostsPath)) { return }
    if (-not (Test-Path $hostsBackup)) {
        Copy-Item -Path $hostsPath -Destination $hostsBackup -Force -ErrorAction SilentlyContinue
        Invoke-Log -Message "Hosts: backup automatico creado (hosts.bak)"
    }
}

    <#
    .SYNOPSIS
    Ejecuta ipconfig /flushdns si AutoFlushDns esta habilitado
    #>
function Invoke-FlushDns {
    $auto = Get-ConfigValue "AutoFlushDns"
    if ($auto -ne "0" -and $auto -ne "false") {
        & ipconfig /flushdns 2>&1 | Out-Null
        Write-Result "Cache DNS limpiada (ipconfig /flushdns)" "INFO"
    } else {
        Write-Result "Ejecute 'ipconfig /flushdns' si el cambio no se refleja" "INFO"
    }
}

    <#
    .SYNOPSIS
    Escribe en el hosts con reintentos si otro proceso lo bloquea temporalmente
    #>
function Invoke-HostsWrite {
    param($Value, [switch]$Append, [int]$Attempts = 5)
    $tempPath = ""
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $text = if ($Value -is [array]) { [string]::Join([Environment]::NewLine, [string[]]$Value) } else { [string]$Value }
            if (-not $text.EndsWith("`n")) { $text += [Environment]::NewLine }
            if ($Append) {
                [System.IO.File]::AppendAllText($hostsPath, $text, [System.Text.Encoding]::Default)
            } else {
                $tempPath = Join-Path (Split-Path -Parent $hostsPath) (".hosts.tmp." + [Guid]::NewGuid().ToString("N"))
                [System.IO.File]::WriteAllText($tempPath, $text, [System.Text.Encoding]::Default)
                Move-Item -LiteralPath $tempPath -Destination $hostsPath -Force -ErrorAction Stop
                $tempPath = ""
            }
            return
        } catch {
            if ($tempPath -and (Test-Path -LiteralPath $tempPath)) {
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
                $tempPath = ""
            }
            if ($i -lt $Attempts) { Start-Sleep -Milliseconds 400; continue }
            throw
        }
    }
}

    <#
    .SYNOPSIS
    Crea una copia de seguridad del archivo hosts (.bak)
    #>
function Invoke-CreateHostsBackup {
    Clear-Host
    Write-Title "CREAR COPIA DE SEGURIDAD"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    if (Test-Path $hostsBackup) {
        Write-Host "Ya existe hosts.bak" -ForegroundColor Yellow
        if (-not (Read-YesNo -Prompt "Sobrescribir la copia existente")) { return }
    }
    try {
        Copy-Item -Path $hostsPath -Destination $hostsBackup -Force -ErrorAction Stop
        Invoke-Log -Message "Hosts: creada copia de seguridad hosts.bak"
        Write-Result "Copia de seguridad creada: hosts.bak" "OK"
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Restaura el contenido por defecto del archivo hosts de Windows
    #>
function Invoke-RestoreDefaultHosts {
    Clear-Host
    Write-Title "RESTAURAR HOSTS POR DEFECTO"
    if (-not (Test-Path $hostsPath)) {
        Write-Result "Archivo hosts no encontrado" "ERROR"; Pause-Message; return
    }
    Write-Host "ADVERTENCIA: Se perdera TODO el contenido actual del hosts." -ForegroundColor Red
    if (-not (Read-YesNo -Prompt "Confirmar restauracion")) { return }
    try {
        if (-not (Test-Path $hostsBackup)) {
            Copy-Item -Path $hostsPath -Destination $hostsBackup -Force -ErrorAction Stop
            Invoke-Log -Message "Hosts: backup automatico creado antes de restaurar por defecto"
        }
        $defaultLines = @(
            "# Copyright (c) 1993-2009 Microsoft Corp.",
            "#",
            "# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.",
            "#",
            "# This file contains the mappings of IP addresses to host names. Each",
            "# entry should be kept on an individual line. The IP address should",
            "# be placed in the first column followed by the corresponding host name.",
            "#",
            "# Local hostname resolution is handled within DNS itself.",
            "#",
            "127.0.0.1 localhost",
            "::1 localhost"
        )
        Invoke-HostsWrite -Value $defaultLines
        Invoke-Log -Message "Hosts: restaurado contenido por defecto"
        Write-Result "Archivo hosts restaurado a su contenido por defecto" "OK"
        Write-Result "Ejecute 'ipconfig /flushdns' si el cambio no se refleja" "INFO"
    } catch { Invoke-HostsWriteError $_ }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra diagnostico accionable cuando falla la escritura del archivo hosts
    #>
function Invoke-HostsWriteError {
    param($Err)
    $ex = if ($Err.Exception) { $Err.Exception } else { $Err }
    Write-Result "Error: $($ex.Message)" "ERROR"
    if ($ex -is [System.UnauthorizedAccessException] -or $ex.Message -match 'denegado|denied') {
        Write-Host "`nDiagnostico: no se pudo escribir el archivo hosts." -ForegroundColor Yellow
        Write-Host "  - Asegurese de que la aplicacion se ejecute como administrador (UAC)." -ForegroundColor Yellow
        Write-Host "  - Si usa un antivirus (ej: Kaspersky), anada 'C:\Windows\System32\drivers\etc\hosts' a las exclusiones o pausa temporalmente la proteccion del archivo hosts." -ForegroundColor Yellow
        Write-Host "  - Tambien puede crear el backup primero (opcion 9) y restaurar (opcion 10)." -ForegroundColor Yellow
    } elseif ($ex.Message -match 'utilizado en otro proceso|being used by another process|ocupado') {
        Write-Host "`nDiagnostico: el archivo hosts esta en uso por otro proceso." -ForegroundColor Yellow
        Write-Host "  - Cierre editores de texto u otras instancias de la herramienta que tengan el hosts abierto." -ForegroundColor Yellow
        Write-Host "  - Pause temporalmente el antivirus si monitoriza el archivo hosts." -ForegroundColor Yellow
        Write-Host "  - Reintente; el bloqueo suele ser temporal y la herramienta ya reintenta automaticamente." -ForegroundColor Yellow
    }
    Invoke-Log -Level "ERROR" -Message "Hosts: escritura fallida - $($ex.Message)"
}

