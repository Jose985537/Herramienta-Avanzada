   # lib/Info.ps1
# Informacion del sistema

    <#
    .SYNOPSIS
    Menu principal del modulo de informacion
    #>
function Show-InfoMenu {
    do {
        Clear-Host
        Write-Title "INFORMACION DEL SISTEMA"
        Write-Menu -Options @(
            "  1. Informacion de hardware",
            "  2. Programas instalados",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 { Show-HardwareInfo }
            2 { Show-InstalledPrograms }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra informacion detallada del hardware
    #>
function Show-HardwareInfo {
    Clear-Host
    Write-Title "INFORMACION DE HARDWARE"
    try {
        Write-Result "Recopilando informacion del sistema..." "INFO"
        $cs = Get-CimInstance Win32_ComputerSystem
        $os = Get-CimInstance Win32_OperatingSystem
        $bios = Get-CimInstance Win32_BIOS
        $cpu = Get-CimInstance Win32_Processor
        $mem = Get-CimInstance Win32_PhysicalMemory
        $disk = Get-CimInstance Win32_DiskDrive
        Write-Host "=== SISTEMA ===" -ForegroundColor Cyan
        Write-Host "  Hostname      : $($cs.Name)"
        Write-Host "  Fabricante    : $($cs.Manufacturer)"
        Write-Host "  Modelo        : $($cs.Model)"
        Write-Host "  Tipo          : $($cs.SystemType)"
        Write-Host "  RAM Total     : $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB"
        Write-Host "`n=== SISTEMA OPERATIVO ===" -ForegroundColor Cyan
        Write-Host "  SO            : $($os.Caption)"
        Write-Host "  Version       : $($os.Version)"
        Write-Host "  Build         : $($os.BuildNumber)"
        Write-Host "  Instalado     : $($os.InstallDate)"
        Write-Host "`n=== BIOS ===" -ForegroundColor Cyan
        Write-Host "  Version       : $($bios.SMBIOSBIOSVersion)"
        Write-Host "  Fabricante    : $($bios.Manufacturer)"
        Write-Host "`n=== PROCESADOR ===" -ForegroundColor Cyan
        Write-Host "  CPU           : $($cpu.Name)"
        Write-Host "  Nucleos       : $($cpu.NumberOfCores)"
        Write-Host "  Logicos       : $($cpu.NumberOfLogicalProcessors)"
        Write-Host "`n=== MEMORIA RAM ===" -ForegroundColor Cyan
        foreach ($m in $mem) {
            Write-Host "  $([math]::Round($m.Capacity/1GB,2)) GB - $($m.Speed) MHz - $($m.DeviceLocator)"
        }
        Write-Host "`n=== DISCOS ===" -ForegroundColor Cyan
        foreach ($d in $disk) {
            Write-Host "  $($d.Model) - $([math]::Round($d.Size/1GB,2)) GB - $($d.SerialNumber)"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

   <#
   .SYNOPSIS
   Muestra la lista de programas instalados en el sistema
   #>
function Show-InstalledPrograms {
    Clear-Host
    Write-Title "PROGRAMAS INSTALADOS"
    try {
        Write-Result "Obteniendo lista..." "INFO"
        $programs = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' 2>$null |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher |
            Sort-Object DisplayName
        if ($programs) {
            $programs | Format-Table DisplayName, DisplayVersion, Publisher -AutoSize -Wrap
            Write-Host "`nTotal: $($programs.Count) programas" -ForegroundColor Cyan
        } else {
            Write-Result "No se encontraron programas" "INFO"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

