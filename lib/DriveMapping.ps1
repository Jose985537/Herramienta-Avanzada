   # lib/DriveMapping.ps1
# Mapeo de unidades de red

    <#
    .SYNOPSIS
    Menu principal de mapeo de unidades
    #>
function Show-DriveMappingMenu {
    do {
        Clear-Host
        Write-Title "MAPEO DE UNIDADES DE RED"
        Write-Menu -Options @(
            "  1. Mapear unidad de red",
            "  2. Desconectar unidad de red",
            "  3. Listar unidades mapeadas",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 3
        switch ($opt) {
            1 { Invoke-MapDrive }
            2 { Invoke-UnmapDrive }
            3 { Invoke-ListMappedDrives }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Lista unidades de red mapeadas
    #>
function Invoke-ListMappedDrives {
    Clear-Host
    Write-Title "UNIDADES DE RED MAPEADAS"
    try {
        $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 4 }
        if (-not $drives) {
            Write-Result "No hay unidades de red mapeadas" "INFO"
        } else {
            $drives | ForEach-Object {
                Write-Host "$($_.DeviceID) -> $($_.ProviderName)" -ForegroundColor White
            }
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Mapea una unidad de red
    #>
function Invoke-MapDrive {
    Clear-Host
    Write-Title "MAPEAR UNIDAD DE RED"
    $letter = Read-Host "`nLetra de unidad (ej: Z)"
    if ([string]::IsNullOrWhiteSpace($letter)) { return }
    $letter = $letter[0].ToString().ToUpper()
    $path = Read-Host "Ruta UNC (ej: \\servidor\carpeta)"
    if ([string]::IsNullOrWhiteSpace($path)) { return }
    $persist = Read-YesNo -Prompt "Conexion persistente (reconectar al inicio)"
    $cmd = "net use ${letter}: `"$path`""
    if ($persist) { $cmd += " /persistent:Yes" } else { $cmd += " /persistent:No" }
    try {
        cmd /c "$cmd" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Result "Unidad ${letter}: mapeada a $path" "OK"
            Invoke-Log -Message "Unidad ${letter}: mapeada a $path"
        } else {
            Write-Result "Error al mapear unidad ${letter}: $path" "ERROR"
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Desconecta una unidad de red mapeada
    #>
function Invoke-UnmapDrive {
    Clear-Host
    Write-Title "DESCONECTAR UNIDAD DE RED"
    Invoke-ListMappedDrives
    $letter = Read-Host "`nLetra de unidad a desconectar"
    if ([string]::IsNullOrWhiteSpace($letter)) { return }
    $letter = $letter[0].ToString().ToUpper()
    if (-not (Read-YesNo -Prompt "Desconectar unidad ${letter}:")) { return }
    try {
        cmd /c "net use ${letter}: /delete" *>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Result "Unidad ${letter}: desconectada" "OK"
            Invoke-Log -Message "Unidad ${letter}: desconectada"
        } else { Write-Result "Error al desconectar" "ERROR" }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

