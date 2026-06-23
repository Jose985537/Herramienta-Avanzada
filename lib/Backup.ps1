   # lib/Backup.ps1
# Copia de seguridad y restauracion de controladores

    <#
    .SYNOPSIS
    Menu principal de copias de seguridad
    #>
function Show-BackupMenu {
    do {
        Clear-Host
        Write-Title "COPIA DE SEGURIDAD DE CONTROLADORES"
        Write-Menu -Options @(
            "  1. Crear copia en ruta predeterminada",
            "  2. Crear copia en ruta personalizada",
            "  3. Crear copia en disco USB",
            "  4. Restaurar desde copia de seguridad",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Backup-Drivers }
            2 { Backup-DriversCustom }
            3 { Backup-DriversUSB }
            4 { Show-RestoreMenu }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Menu de restauracion de copias
    #>
function Show-RestoreMenu {
    do {
        Clear-Host
        Write-Title "RESTAURACION DE COPIAS DE SEGURIDAD"
        Write-Menu -Options @(
            "  1. Restaurar en el mismo equipo",
            "  2. Restaurar en equipo diferente",
            "  0. Volver al menu anterior"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { Restore-DriversSame }
            2 { Restore-DriversDifferent }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Obtiene rutas de origen y destino desde configuracion
    #>
function Get-ConfigSourcePaths {
    $srcDrivers = Get-ConfigValue -Key "BackupSourceDrivers" -Default "$env:SystemRoot\System32\Drivers"
    $srcDriverStore = Get-ConfigValue -Key "BackupSourceDriverStore" -Default "$env:SystemRoot\System32\DriverStore\FileRepository"
    $srcInf = Get-ConfigValue -Key "BackupSourceInf" -Default "$env:SystemRoot\inf"
    $dest = Get-ConfigValue -Key "BackupDest" -Default ".\backups\drivers"
    if (-not [IO.Path]::IsPathRooted($dest)) {
        $dest = Join-Path (Get-ScriptDirectory) $dest
    }
    return @{
        SourceDrivers = $srcDrivers
        SourceDriverStore = $srcDriverStore
        SourceInf = $srcInf
        Dest = $dest
    }
}

    <#
    .SYNOPSIS
    Realiza copia de seguridad de controladores
    #>
function Backup-Drivers {
    param([string]$DestPath = "")
    $paths = Get-ConfigSourcePaths
    if ([string]::IsNullOrWhiteSpace($DestPath)) {
        $DestPath = $paths.Dest
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path $DestPath "BackupDrivers_$timestamp"
    try {
        if (-not (Test-Path $DestPath)) { New-Item -ItemType Directory -Path $DestPath -Force | Out-Null }
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Write-Result "Copiando controladores..." "INFO"
        if (Test-Path $paths.SourceDrivers) {
            Copy-Item -Path "$($paths.SourceDrivers)\*" -Destination (Join-Path $backupFolder "Drivers") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceDrivers)" "WARN" }
        if (Test-Path $paths.SourceDriverStore) {
            Copy-Item -Path "$($paths.SourceDriverStore)\*" -Destination (Join-Path $backupFolder "DriverStore") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceDriverStore)" "WARN" }
        if (Test-Path $paths.SourceInf) {
            Copy-Item -Path "$($paths.SourceInf)\*" -Destination (Join-Path $backupFolder "inf") -Recurse -Force -ErrorAction SilentlyContinue
        } else { Write-Result "Origen no encontrado: $($paths.SourceInf)" "WARN" }
        $regFile = Join-Path $backupFolder "DriversRegistry.reg"
        Write-Result "Exportando registro de controladores..." "INFO"
        cmd /c "reg export `"HKLM\SYSTEM\CurrentControlSet\Control\Class`" `"$regFile`"" *>$null
        Invoke-Log -Message "Backup de controladores: $backupFolder"
        Write-Result "Copia de seguridad completada en:`n  $backupFolder" "OK"
    } catch {
        Write-Result "Error en backup: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Backup fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Realiza copia en ruta personalizada
    #>
function Backup-DriversCustom {
    Write-Host "`nRutas sugeridas:" -ForegroundColor Cyan
    Write-Host "  1. Escritorio: $env:USERPROFILE\Desktop"
    Write-Host "  2. Descargas: $env:USERPROFILE\Downloads"
    Write-Host "  3. Documentos: $env:USERPROFILE\Documents"
    $customPath = Read-Host "`nIngrese la ruta de destino"
    if ([string]::IsNullOrWhiteSpace($customPath)) { return }
    Backup-Drivers -DestPath $customPath
}

    <#
    .SYNOPSIS
    Realiza copia en unidad USB
    #>
function Backup-DriversUSB {
    $usbDrives = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' -and $_.DriveLetter }
    if (-not $usbDrives) {
        Write-Result "No se detectaron unidades USB" "WARN"
        Pause-Message
        return
    }
    Write-Host "`nUnidades USB detectadas:" -ForegroundColor Cyan
    $usbDrives | Format-Table DriveLetter, FileSystemLabel, @{N='Libre(GB)';E={[math]::Round($_.SizeRemaining/1GB,2)}} -AutoSize
    $letter = Read-Host "Ingrese la letra de la unidad USB"
    if ([string]::IsNullOrWhiteSpace($letter)) { return }
    $usbPath = "$($letter[0]):\"
    if (-not (Test-Path $usbPath)) {
        Write-Result "Unidad $usbPath no encontrada" "ERROR"
        Pause-Message
        return
    }
    Backup-Drivers -DestPath $usbPath
}

    <#
    .SYNOPSIS
    Restaura controladores en el mismo equipo
    #>
function Restore-DriversSame {
    $backupFolder = Read-Host "`nIngrese la ruta de la carpeta de copia de seguridad"
    if ([string]::IsNullOrWhiteSpace($backupFolder) -or -not (Test-Path $backupFolder)) {
        Write-Result "Carpeta no encontrada" "ERROR"
        Pause-Message
        return
    }
    try {
        $paths = Get-ConfigSourcePaths
        $subfolders = @("Drivers", "DriverStore", "inf")
        $targets = @($paths.SourceDrivers, $paths.SourceDriverStore, $paths.SourceInf)
        for ($i = 0; $i -lt $subfolders.Count; $i++) {
            $src = Join-Path $backupFolder $subfolders[$i]
            if (Test-Path $src) {
                Write-Result "Restaurando $($subfolders[$i])..." "INFO"
                Copy-Item -Path "$src\*" -Destination $targets[$i] -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        $regFile = Join-Path $backupFolder "DriversRegistry.reg"
        if (Test-Path $regFile) {
            Write-Result "Importando registro..." "INFO"
            cmd /c "reg import `"$regFile`"" *>$null
        }
        Invoke-Log -Message "Restauracion de controladores desde $backupFolder"
        Write-Result "Restauracion completada" "OK"
    } catch {
        Write-Result "Error en restauracion: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Restauracion fallo: $_"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Restaura controladores en equipo diferente
    #>
function Restore-DriversDifferent {
    $backupFolder = Read-Host "`nIngrese la ruta de la carpeta de copia de seguridad"
    if ([string]::IsNullOrWhiteSpace($backupFolder) -or -not (Test-Path $backupFolder)) {
        Write-Result "Carpeta no encontrada" "ERROR"
        Pause-Message
        return
    }
    Write-Host "`nOPCIONES DE RESTAURACION:" -ForegroundColor Yellow
    Write-Host "  1. Verificar compatibilidad primero"
    Write-Host "  2. Restaurar sin verificar"
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
    if ($opt -eq 1) {
        Write-Result "Verificando compatibilidad..." "INFO"
        $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
        Write-Host "  Version SO actual: $osVersion" -ForegroundColor Gray
        if (-not (Read-YesNo -Prompt "Desea continuar con la restauracion")) { return }
    }
    try {
        $paths = Get-ConfigSourcePaths
        $subfolders = @("Drivers", "DriverStore", "inf")
        $targets = @($paths.SourceDrivers, $paths.SourceDriverStore, $paths.SourceInf)
        for ($i = 0; $i -lt $subfolders.Count; $i++) {
            $src = Join-Path $backupFolder $subfolders[$i]
            if (Test-Path $src) {
                Write-Result "Restaurando $($subfolders[$i])..." "INFO"
                Copy-Item -Path "$src\*" -Destination $targets[$i] -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        Invoke-Log -Message "Restauracion (equipo diferente) desde $backupFolder"
        Write-Result "Restauracion completada" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Restauracion fallo: $_"
    }
    Pause-Message
}

