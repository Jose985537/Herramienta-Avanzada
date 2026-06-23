   # lib/Processes.ps1
# Gestor de procesos: listar, kill, ver detalles

    <#
    .SYNOPSIS
    Menu principal del gestor de procesos
    #>
function Show-ProcessMenu {
    do {
        Clear-Host
        Write-Title "GESTOR DE PROCESOS"
        Write-Menu -Options @(
            "  1. Listar procesos en ejecucion",
            "  2. Top procesos por uso de memoria",
            "  3. Top procesos por uso de CPU",
            "  4. Detalle de un proceso por PID",
            "  5. Detalle de un proceso por nombre",
            "  6. Finalizar proceso por PID",
            "  7. Finalizar proceso por nombre",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 7
        switch ($opt) {
            1 { Invoke-ListProcesses }
            2 { Invoke-TopMemory }
            3 { Invoke-TopCPU }
            4 { Invoke-ProcessByPID }
            5 { Invoke-ProcessByName }
            6 { Invoke-KillByPID }
            7 { Invoke-KillByName }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra una tabla formateada de procesos
    #>
function Show-ProcessTable {
    param([array]$Processes, [string]$Title)
    if ($Processes.Count -eq 0) {
        Write-Result "No se encontraron procesos" "WARN"
        return
    }
    $Processes | Format-Table @(
        @{N='PID';E={$_.Id};Width=8},
        @{N='Nombre';E={$_.ProcessName};Width=30},
        @{N='CPU(s)';E={try {[math]::Round($_.TotalProcessorTime.TotalSeconds,1)} catch {0}};Width=10},
        @{N='Memoria(MB)';E={try {[math]::Round($_.WorkingSet64/1MB,1)} catch {0}};Width=14},
        @{N='Hilos';E={$_.Threads.Count};Width=8},
        @{N='Respondiendo';E={if ($_.Responding) {'Si'} else {'No'}};Width=14}
    ) -AutoSize -Wrap
}

    <#
    .SYNOPSIS
    Lista procesos en ejecucion con detalles
    #>
function Invoke-ListProcesses {
    Clear-Host
    Write-Title "PROCESOS EN EJECUCION"
    try {
        $procs = Get-Process | Sort-Object ProcessName
        Write-Host "Total: $($procs.Count) procesos`n" -ForegroundColor Gray
        Show-ProcessTable -Processes $procs -Title "Procesos"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra los 20 procesos con mayor uso de memoria
    #>
function Invoke-TopMemory {
    Clear-Host
    Write-Title "TOP 20 PROCESOS POR MEMORIA"
    try {
        $procs = Get-Process | Sort-Object { try { $_.WorkingSet64 } catch { 0 } } -Descending | Select-Object -First 20
        Show-ProcessTable -Processes $procs -Title "Top 20 Memoria"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra los 20 procesos con mayor uso de CPU
    #>
function Invoke-TopCPU {
    Clear-Host
    Write-Title "TOP 20 PROCESOS POR CPU"
    try {
        $procs = Get-Process | Sort-Object { try { $_.TotalProcessorTime.TotalSeconds } catch { 0 } } -Descending | Select-Object -First 20
        Show-ProcessTable -Processes $procs -Title "Top 20 CPU"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el detalle de un proceso por su PID
    #>
function Invoke-ProcessByPID {
    Clear-Host
    Write-Title "DETALLE DE PROCESO POR PID"
    $pidInput = Read-Host "`nPID"
    if ($pidInput -notmatch '^\d+$') { Write-Result "PID invalido" "WARN"; Pause-Message; return }
    try {
        $p = Get-Process -Id [int]$pidInput -ErrorAction Stop
        Write-Host "`nNombre           : $($p.ProcessName)" -ForegroundColor White
        Write-Host "PID              : $($p.Id)" -ForegroundColor White
        Write-Host "Memoria (MB)     : $([math]::Round($p.WorkingSet64/1MB, 2))" -ForegroundColor White
        Write-Host "CPU total (s)    : $([math]::Round($p.TotalProcessorTime.TotalSeconds, 2))" -ForegroundColor White
        Write-Host "Hilos            : $($p.Threads.Count)" -ForegroundColor White
        Write-Host "Handles          : $($p.HandleCount)" -ForegroundColor White
        Write-Host "Respondiendo     : $(if ($p.Responding) { 'Si' } else { 'No' })" -ForegroundColor White
        Write-Host "Ruta             : $(try { $p.MainModule.FileName } catch { '[No accesible]' })" -ForegroundColor Gray
        Write-Host "Inicio           : $(try { $p.StartTime } catch { '[No accesible]' })" -ForegroundColor Gray
    } catch { Write-Result "Error: PID $pidInput no encontrado" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra el detalle de procesos por su nombre
    #>
function Invoke-ProcessByName {
    Clear-Host
    Write-Title "DETALLE DE PROCESO POR NOMBRE"
    $name = Read-Host "`nNombre del proceso (ej: chrome)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Result "Nombre invalido" "WARN"; Pause-Message; return }
    try {
        $procs = Get-Process -Name $name -ErrorAction Stop
        Write-Host "`nProcesos encontrados: $($procs.Count)`n" -ForegroundColor Gray
        Show-ProcessTable -Processes $procs -Title $name
    } catch { Write-Result "Error: proceso '$name' no encontrado" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Finaliza un proceso por su PID
    #>
function Invoke-KillByPID {
    Clear-Host
    Write-Title "FINALIZAR PROCESO POR PID"
    $pidInput = Read-Host "`nPID a finalizar"
    if ($pidInput -notmatch '^\d+$') { Write-Result "PID invalido" "WARN"; Pause-Message; return }
    try {
        $p = Get-Process -Id [int]$pidInput -ErrorAction Stop
        $name = $p.ProcessName
        if (-not (Read-YesNo -Prompt "Finalizar $name (PID: $pidInput)?")) { return }
        $p.Kill()
        Invoke-Log -Message "Proceso finalizado: $name (PID: $pidInput)"
        Write-Result "Proceso $name (PID: $pidInput) finalizado" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Finaliza todos los procesos por su nombre
    #>
function Invoke-KillByName {
    Clear-Host
    Write-Title "FINALIZAR PROCESO POR NOMBRE"
    $name = Read-Host "`nNombre del proceso (ej: notepad)"
    if ([string]::IsNullOrWhiteSpace($name)) { Write-Result "Nombre invalido" "WARN"; Pause-Message; return }
    try {
        $procs = Get-Process -Name $name -ErrorAction Stop
        $count = $procs.Count
        if (-not (Read-YesNo -Prompt "Finalizar $count instancia(s) de '$name'?")) { return }
        $procs | ForEach-Object { $_.Kill() }
        Invoke-Log -Message "Procesos finalizados: $name ($count instancias)"
        Write-Result "Se finalizaron $count instancia(s) de $name" "OK"
    } catch { Write-Result "Error: proceso '$name' no encontrado" "ERROR" }
    Pause-Message
}

