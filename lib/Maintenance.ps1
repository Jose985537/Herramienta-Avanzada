   # lib/Maintenance.ps1
# Mantenimiento del sistema: limpieza, SFC, CHKDSK, optimizacion, restore points, WU cache, USB

    <#
    .SYNOPSIS
    Menu principal del modulo de mantenimiento
    #>
function Show-MaintenanceMenu {
    do {
        Clear-Host
        Write-Title "MANTENIMIENTO DEL SISTEMA"
        Write-Menu -Options @(
            "  1. Limpiar archivos temporales",
            "  2. Reparar archivos del sistema (sfc /scannow)",
            "  3. Optimizar unidades (HDD/SSD)",
            "  4. Desactivar hibernacion (liberar espacio)",
            "  5. Comprobar disco (CHKDSK)",
            "  6. Gestion de puntos de restauracion",
            "  7. Limpiar cache de Windows Update",
            "  8. Desconectar dispositivo USB",
            "  9. Montar dispositivo USB",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 9
        switch ($opt) {
            1 { Invoke-CleanTemp }
            2 { Invoke-SFCScan }
            3 { Invoke-OptimizeVolume }
            4 { Invoke-HibernationMenu }
            5 { Invoke-CHKDSK }
            6 { Invoke-RestorePointMenu }
            7 { Invoke-CleanWUCache }
            8 { Invoke-USBEject }
            9 { Invoke-USBMount }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Limpia archivos temporales y papelera
    #>
function Invoke-CleanTemp {
    Clear-Host
    Write-Title "LIMPIEZA SEGURA DE ARCHIVOS TEMPORALES"
    try {
        Write-Result "Eliminando archivos temporales..." "INFO"
        $tempPaths = @(
            $env:TEMP,
            "$env:WINDIR\Temp",
            "$env:LOCALAPPDATA\Temp"
        )
        foreach ($path in $tempPaths) {
            if (Test-Path $path) {
                try {
                    Remove-Item "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Result "  Limpiado: $path" "OK"
                } catch { Write-Result ("  Error en $path : $_") "WARN" }
            }
        }
        Write-Result "Vaciando papelera de reciclaje..." "INFO"
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Invoke-Log -Message "Limpieza de temporales completada"
        Write-Result "Limpieza completada" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Limpieza fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Ejecuta sfc /scannow para reparar archivos del sistema
    #>
function Invoke-SFCScan {
    Clear-Host
    Write-Title "REPARACION DE ARCHIVOS DEL SISTEMA (SFC)"
    Write-Host "Este proceso puede tardar bastante tiempo." -ForegroundColor Yellow
    Write-Host "No cierre la ventana durante el proceso.`n" -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Desea ejecutar sfc /scannow")) { return }
    try {
        Write-Result "Ejecutando sfc /scannow..." "INFO"
        $result = cmd /c "sfc /scannow"
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) {
            Write-Result "SFC completado exitosamente - No se encontraron errores" "OK"
        } else {
            Write-Result "SFC finalizo con codigo $exitCode" "WARN"
            Write-Host "Revise: $env:windir\Logs\CBS\CBS.log" -ForegroundColor Gray
            Write-Host "Puede ser necesario ejecutar: DISM /Online /Cleanup-Image /RestoreHealth" -ForegroundColor Gray
        }
        Invoke-Log -Message "SFC /scannow ejecutado (codigo: $exitCode)"
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Optimiza unidad HDD/SSD
    #>
function Invoke-OptimizeVolume {
    Clear-Host
    Write-Title "OPTIMIZACION DE UNIDADES (HDD/SSD)"
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
        if (-not $volumes) { Write-Result "No se detectaron unidades fijas" "WARN"; Pause-Message; return }
        Write-Host "Unidades disponibles:`n" -ForegroundColor Cyan
        $volumes | Format-Table DriveLetter, FileSystemLabel,
            @{N='Tamano(GB)';E={[math]::Round($_.Size/1GB,2)}},
            @{N='Libre(GB)';E={[math]::Round($_.SizeRemaining/1GB,2)}},
            HealthStatus -AutoSize
        $letter = Read-Host "`nIngrese la letra de la unidad a optimizar"
        if ([string]::IsNullOrWhiteSpace($letter)) { return }
        $vol = Get-Volume -DriveLetter $letter[0] -ErrorAction SilentlyContinue
        if (-not $vol) { Write-Result "Unidad $letter no valida" "ERROR"; Pause-Message; return }
        Write-Result "Optimizando unidad ${letter}:..." "INFO"
        Optimize-Volume -DriveLetter $letter[0] -Verbose -ErrorAction SilentlyContinue
        Invoke-Log -Message "Optimizacion de unidad ${letter}: completada"
        Write-Result "Optimizacion completada" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Menu de gestion de hibernacion
    #>
function Invoke-HibernationMenu {
    do {
        Clear-Host
        Write-Title "GESTION DE HIBERNACION"
        $hiberStatus = if (Test-Path "$env:WINDIR\hiberfil.sys") { "ACTIVADA" } else { "DESACTIVADA" }
        Write-Host "Estado: $hiberStatus" -ForegroundColor Gray
        Write-Menu -Options @(
            "  1. Desactivar hibernacion",
            "  2. Activar hibernacion",
            "  3. Mostrar estado",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 3
        switch ($opt) {
            1 {
                $null = cmd /c "powercfg /h off" 2>&1
                if ($LASTEXITCODE -eq 0) { Write-Result "Hibernacion DESACTIVADA" "OK" }
                else { Write-Result "Error al desactivar hibernacion" "ERROR" }
                Pause-Message
            }
            2 {
                $null = cmd /c "powercfg /h on" 2>&1
                if ($LASTEXITCODE -eq 0) { Write-Result "Hibernacion ACTIVADA" "OK" }
                else { Write-Result "Error al activar hibernacion" "ERROR" }
                Pause-Message
            }
            3 {
                Write-Result "Estado de hibernacion:" "INFO"
                cmd /c "powercfg /h"
                Pause-Message
            }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Ejecuta comprobacion de disco (CHKDSK) en una unidad
    #>
function Invoke-CHKDSK {
    Clear-Host
    Write-Title "COMPROBACION DE DISCO (CHKDSK)"
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
        if (-not $volumes) { Write-Result "No hay unidades fijas" "WARN"; Pause-Message; return }
        Write-Host "Unidades disponibles:`n" -ForegroundColor Cyan
        $volumes | Format-Table DriveLetter, HealthStatus, SizeRemaining -AutoSize
        $letter = Read-Host "`nIngrese la letra de la unidad a comprobar"
        if ([string]::IsNullOrWhiteSpace($letter)) { return }
        $vol = Get-Volume -DriveLetter $letter[0] -ErrorAction SilentlyContinue
        if (-not $vol) { Write-Result "Unidad $letter no valida" "ERROR"; Pause-Message; return }
        Write-Host "`nADVERTENCIA:" -ForegroundColor Red
        Write-Host "  /f: corrige errores" -ForegroundColor Yellow
        Write-Host "  /r: localiza sectores defectuosos (incluye /f)" -ForegroundColor Yellow
        Write-Host "  Puede tardar horas y requerir reinicio.`n" -ForegroundColor Yellow
        if (-not (Read-YesNo -Prompt "Ejecutar CHKDSK ${letter}: /f /r")) { return }
        Write-Result "Ejecutando CHKDSK ${letter}: /f /r..." "INFO"
        cmd /c "echo Y | chkdsk ${letter}: /f /r"
        $exitCode = $LASTEXITCODE
        switch ($exitCode) {
            0 { Write-Result "CHKDSK completado - Sin errores" "OK" }
            1 { Write-Result "CHKDSK completado - Errores corregidos" "OK" }
            2 { Write-Result "CHKDSK realizo limpieza (codigo: $exitCode)" "WARN" }
            3 { Write-Result "CHKDSK no pudo completarse (codigo: $exitCode)" "ERROR" }
            default { Write-Result "CHKDSK finalizo con codigo: $exitCode" "WARN" }
        }
        Invoke-Log -Message "CHKDSK ${letter}: ejecutado (codigo: $exitCode)"
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Menu de puntos de restauracion
    #>
function Invoke-RestorePointMenu {
    do {
        Clear-Host
        Write-Title "GESTION DE PUNTOS DE RESTAURACION"
        Write-Menu -Options @(
            "  1. Crear punto de restauracion",
            "  2. Listar puntos de restauracion",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { New-RestorePoint }
            2 { Get-RestorePoints }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Crea un nuevo punto de restauracion del sistema
    #>
function New-RestorePoint {
    Clear-Host
    Write-Title "CREAR PUNTO DE RESTAURACION"
    if (-not (Read-YesNo -Prompt "Desea crear un punto de restauracion")) { return }
    try {
        $desc = "Punto creado por Herramienta Avanzada $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Invoke-Log -Message "Punto de restauracion creado"
        Write-Result "Punto de restauracion creado exitosamente" "OK"
    } catch {
        Write-Result "Error al crear punto de restauracion: $_" "ERROR"
        Write-Host "Asegurese de que: el servicio VSS este activo y la proteccion del sistema este habilitada" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Lista todos los puntos de restauracion disponibles
    #>
function Get-RestorePoints {
    Clear-Host
    Write-Title "LISTA DE PUNTOS DE RESTAURACION"
    try {
        $points = Get-ComputerRestorePoint -ErrorAction Stop
        if ($points) {
            $points | Format-Table SequenceNumber, CreationTime, Description, RestorePointType -AutoSize
        } else {
            Write-Result "No hay puntos de restauracion" "INFO"
        }
    } catch {
        Write-Result "No se pudieron obtener puntos de restauracion" "WARN"
        Write-Host "Asegurese de que la Proteccion del Sistema este activa" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Limpia la cache de Windows Update
    #>
function Invoke-CleanWUCache {
    Clear-Host
    Write-Title "LIMPIEZA DE CACHE DE WINDOWS UPDATE"
    try {
        Write-Result "Deteniendo servicios de Windows Update..." "INFO"
        $services = @('wuauserv', 'bits', 'dosvc')
        foreach ($svc in $services) {
            Stop-Service $svc -Force -ErrorAction SilentlyContinue
        }
        $wuFolder = "$env:WINDIR\SoftwareDistribution"
        if (Test-Path $wuFolder) {
            Write-Result "Tomando posesion de SoftwareDistribution..." "INFO"
            cmd /c "takeown /f `"$wuFolder`" /r /d Y" *>$null
            cmd /c "icacls `"$wuFolder`" /grant administrators:F /t /c /l /q" *>$null
            Write-Result "Eliminando carpeta SoftwareDistribution..." "INFO"
            Remove-Item $wuFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $wuFolder -Force | Out-Null
        Write-Result "Reiniciando servicios..." "INFO"
        foreach ($svc in $services) {
            Start-Service $svc -ErrorAction SilentlyContinue
        }
        Invoke-Log -Message "Cache de Windows Update limpiada"
        Write-Result "Cache de Windows Update limpiada correctamente" "OK"
        Write-Host "Se recomienda reiniciar el equipo" -ForegroundColor Yellow
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Limpieza WU fallo: $_"
    }
    Pause-Message
}

# Funciones USB (fusionadas desde USB.ps1)

    <#
    .SYNOPSIS
    Desmonta de forma segura un dispositivo USB
    #>
function Invoke-USBEject {
    Clear-Host
    Write-Title "DESCONEXION DE DISPOSITIVOS USB"
    try {
        $usbVolumes = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter }
        if (-not $usbVolumes) {
            Write-Result "No se detectaron dispositivos USB con letra asignada" "WARN"
            Pause-Message; return
        }
        Write-Host "Dispositivos USB detectados:`n" -ForegroundColor Cyan
        $usbVolumes | Format-Table DriveLetter, FileSystemLabel,
            @{N='Libre(GB)';E={[math]::Round($_.SizeRemaining/1GB,2)}},
            @{N='Total(GB)';E={[math]::Round($_.Size/1GB,2)}} -AutoSize
        $letter = Read-Host "`nIngrese la letra de la unidad a expulsar"
        if ([string]::IsNullOrWhiteSpace($letter)) { return }
        $vol = Get-Volume -DriveLetter $letter[0] -ErrorAction SilentlyContinue
        if (-not $vol -or $vol.DriveType -ne 'Removable') {
            Write-Result "Unidad $letter no valida o no es extraible" "ERROR"
            Pause-Message; return
        }
        if (-not (Read-YesNo -Prompt "Desmontar unidad ${letter}:")) { return }
        $drive = Get-CimInstance Win32_Volume -Filter "DriveLetter='${letter}:'" -ErrorAction Stop
        if ($drive) {
            $drive | Invoke-CimMethod -MethodName Dismount -Arguments @{Force=$false;Permanent=$false} | Out-Null
        }
        Write-Result "Unidad ${letter}: desmontada correctamente" "OK"
        Write-Host "Puede retirar el dispositivo de forma segura." -ForegroundColor Green
        Invoke-Log -Message "USB ${letter}: desmontado"
    } catch {
        Write-Result "Error al desmontar: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Desmontaje USB fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Asigna letra de unidad a un disco USB
    #>
function Invoke-USBMount {
    Clear-Host
    Write-Title "MONTAR / ASIGNAR LETRA A USB"
    try {
        $disks = Get-Disk | Where-Object { $_.BusType -eq 'USB' }
        if (-not $disks) {
            Write-Result "No se detectaron discos USB" "WARN"
            Pause-Message; return
        }
        Write-Host "Discos USB detectados:`n" -ForegroundColor Cyan
        foreach ($d in $disks) {
            Write-Host "Disco $($d.Number): $($d.FriendlyName) ($([math]::Round($d.Size/1GB,2)) GB) - $($d.OperationalStatus)"
            $parts = Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue
            if ($parts) { $parts | Format-Table DiskNumber, PartitionNumber, DriveLetter, Size, Type -AutoSize }
        }
        $diskNum = Read-Host "`nNumero de disco (DiskNumber)"
        $partNum = Read-Host "Numero de particion (PartitionNumber)"
        $newLetter = Read-Host "Letra a asignar"
        if ([string]::IsNullOrWhiteSpace($newLetter)) { return }
        $newLetter = $newLetter[0].ToString().ToUpper()
        $existingVol = Get-Volume -DriveLetter $newLetter -ErrorAction SilentlyContinue
        if ($existingVol) {
            Write-Result "La letra $newLetter ya esta en uso" "ERROR"
            Pause-Message; return
        }
        $part = Get-Partition -DiskNumber $diskNum -PartitionNumber $partNum -ErrorAction Stop
        Add-PartitionAccessPath -InputObject $part -AccessPath "${newLetter}:" -ErrorAction Stop
        Write-Result "Letra ${newLetter}: asignada correctamente" "OK"
        Invoke-Log -Message "USB disco $diskNum particion $partNum montado como ${newLetter}:"
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

