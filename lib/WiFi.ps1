   # lib/WiFi.ps1
# Gestion de perfiles WiFi: listar, ver claves, eliminar

    <#
    .SYNOPSIS
    Menu principal de gestion WiFi
    #>
function Show-WiFiMenu {
    do {
        Clear-Host
        Write-Title "GESTION DE PERFILES WIFI"
        Write-Menu -Options @(
            "  1. Listar perfiles WiFi guardados",
            "  2. Ver clave de un perfil WiFi",
            "  3. Exportar perfil WiFi a XML",
            "  4. Eliminar perfil WiFi",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Invoke-ListWiFi }
            2 { Invoke-ShowWiFiKey }
            3 { Invoke-ExportWiFi }
            4 { Invoke-RemoveWiFi }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Lista los perfiles WiFi guardados en el sistema
    #>
function Invoke-ListWiFi {
    Clear-Host
    Write-Title "PERFILES WIFI GUARDADOS"
    try {
        $profiles = cmd /c "netsh wlan show profiles" 2>&1 | Where-Object { $_ -match 'Perfil de todos los usuarios|User Profile|:\s+' }
        if (-not $profiles) {
            $profiles = cmd /c "netsh wlan show profiles" 2>&1
        }
        $profileNames = $profiles | ForEach-Object {
            if ($_ -match ':\s+(.+)$') { $matches[1].Trim() }
        } | Where-Object { $_ }
        if (-not $profileNames) {
            Write-Result "No se encontraron perfiles WiFi" "WARN"
            Pause-Message; return
        }
        Write-Host "Perfiles encontrados: $($profileNames.Count)" -ForegroundColor Cyan
        $i = 1
        foreach ($p in $profileNames) {
            Write-Host ("  {0,2}. {1}" -f $i, $p) -ForegroundColor White
            $i++
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra la clave de seguridad de un perfil WiFi
    #>
function Invoke-ShowWiFiKey {
    Clear-Host
    Write-Title "VER CLAVE DE PERFIL WIFI"
    $ssid = Read-Host "Nombre del perfil WiFi"
    if ([string]::IsNullOrWhiteSpace($ssid)) { return }
    try {
        $result = cmd /c "netsh wlan show profile `"$ssid`" key=clear" 2>&1
        $keyLine = $result | Where-Object { $_ -match 'Contenido de la clave|Key Content|Key Content\s+:\s+(.+)$' }
        if (-not $keyLine) { $keyLine = $result | Where-Object { $_ -match 'Key Content' } }
        if ($keyLine) {
            Write-Host "--- Perfil: $ssid ---" -ForegroundColor Cyan
            $keyText = $keyLine | Select-Object -First 1
            if ($keyText -match ':\s+(.+)$') {
                Write-Host "Clave: " -NoNewline
                Write-Host $matches[1].Trim() -ForegroundColor Green -BackgroundColor Black
            } else {
                $result | ForEach-Object { Write-Host $_ }
            }
        } else {
            $result | ForEach-Object { Write-Host $_ }
        }
        Invoke-Log -Message "Clave WiFi consultada: $ssid"
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Exporta un perfil WiFi a un archivo XML
    #>
function Invoke-ExportWiFi {
    Clear-Host
    Write-Title "EXPORTAR PERFIL WIFI A XML"
    $ssid = Read-Host "Nombre del perfil a exportar"
    if ([string]::IsNullOrWhiteSpace($ssid)) { return }
    $exportPath = Read-Host "Ruta de destino (Enter = Escritorio)"
    if ([string]::IsNullOrWhiteSpace($exportPath)) {
        $exportPath = Join-Path $env:USERPROFILE "Desktop"
    }
    if (-not (Test-Path $exportPath)) {
        Write-Result "Ruta no encontrada" "ERROR"; Pause-Message; return
    }
    try {
        $outFile = Join-Path $exportPath "$ssid.xml"
        $null = cmd /c "netsh wlan export profile `"$ssid`" folder=`"$exportPath`" key=clear" 2>&1
        if (Test-Path $outFile) {
            Write-Result "Perfil exportado a: $outFile" "OK"
            Invoke-Log -Message "Perfil WiFi $ssid exportado a $outFile"
        } else {
            $found = Get-ChildItem $exportPath -Filter "*$ssid*.xml" | Select-Object -First 1
            if ($found) {
                Write-Result "Perfil exportado a: $($found.FullName)" "OK"
            } else {
                Write-Result "Error al exportar perfil" "ERROR"
            }
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina un perfil WiFi del sistema
    #>
function Invoke-RemoveWiFi {
    Clear-Host
    Write-Title "ELIMINAR PERFIL WIFI"
    $ssid = Read-Host "Nombre del perfil a eliminar"
    if ([string]::IsNullOrWhiteSpace($ssid)) { return }
    if (-not (Read-YesNo -Prompt "Eliminar perfil '$ssid'")) { return }
    try {
        $null = cmd /c "netsh wlan delete profile name=`"$ssid`"" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Result "Perfil '$ssid' eliminado" "OK"
            Invoke-Log -Message "Perfil WiFi $ssid eliminado"
        } else {
            Write-Result "Error al eliminar perfil" "ERROR"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

