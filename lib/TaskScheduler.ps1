   # lib/TaskScheduler.ps1
# Administracion de tareas programadas

    <#
    .SYNOPSIS
    Menu principal de tareas programadas
    #>
function Show-TaskSchedulerMenu {
    do {
        Clear-Host
        Write-Title "TAREAS PROGRAMADAS"
        Write-Menu -Options @(
            "  1. Listar tareas programadas",
            "  2. Ejecutar tarea ahora",
            "  3. Deshabilitar tarea",
            "  4. Habilitar tarea",
            "  5. Eliminar tarea",
            "  6. Crear tarea simple (diaria)",
            "  0. Volver al menu principal"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 { Invoke-ListTasks }
            2 { Invoke-RunTask }
            3 { Invoke-DisableTask }
            4 { Invoke-EnableTask }
            5 { Invoke-DeleteTask }
            6 { Invoke-CreateTask }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Lista tareas programadas del sistema
    #>
function Invoke-ListTasks {
    Clear-Host
    Write-Title "TAREAS PROGRAMADAS"
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue
        if (-not $tasks) { Write-Result "No hay tareas programadas" "INFO"; Pause-Message; return }
        Write-Host "Total: $($tasks.Count) tareas`n" -ForegroundColor Gray
        $tasks | Sort-Object TaskPath | Format-Table @(
            @{N='Nombre';E={$_.TaskName};Width=40},
            @{N='Estado';E={if ($_.State -eq 'Ready') {'Lista'} elseif ($_.State -eq 'Running') {'Ejecutando'} elseif ($_.State -eq 'Disabled') {'Deshabilitada'} else {$_.State}};Width=14},
            @{N='Ruta';E={$_.TaskPath};Width=30}
        ) -AutoSize -Wrap
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Ejecuta una tarea programada de forma manual
    #>
function Invoke-RunTask {
    Clear-Host
    Write-Title "EJECUTAR TAREA AHORA"
    $taskName = Read-Host "`nNombre de la tarea"
    if ([string]::IsNullOrWhiteSpace($taskName)) { return }
    try {
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Result "Tarea '$taskName' iniciada" "OK"
        Invoke-Log -Message "Tarea programada '$taskName' ejecutada manualmente"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Deshabilita una tarea programada
    #>
function Invoke-DisableTask {
    Clear-Host
    Write-Title "DESHABILITAR TAREA"
    $taskName = Read-Host "`nNombre de la tarea"
    if ([string]::IsNullOrWhiteSpace($taskName)) { return }
    if (-not (Read-YesNo -Prompt "Deshabilitar '$taskName'")) { return }
    try {
        Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Result "Tarea '$taskName' deshabilitada" "OK"
        Invoke-Log -Message "Tarea '$taskName' deshabilitada"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Habilita una tarea programada
    #>
function Invoke-EnableTask {
    Clear-Host
    Write-Title "HABILITAR TAREA"
    $taskName = Read-Host "`nNombre de la tarea"
    if ([string]::IsNullOrWhiteSpace($taskName)) { return }
    try {
        Enable-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Result "Tarea '$taskName' habilitada" "OK"
        Invoke-Log -Message "Tarea '$taskName' habilitada"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina permanentemente una tarea programada
    #>
function Invoke-DeleteTask {
    Clear-Host
    Write-Title "ELIMINAR TAREA"
    $taskName = Read-Host "`nNombre de la tarea"
    if ([string]::IsNullOrWhiteSpace($taskName)) { return }
    if (-not (Read-YesNo -Prompt "ELIMINAR permanentemente '$taskName'")) { return }
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
        Write-Result "Tarea '$taskName' eliminada" "OK"
        Invoke-Log -Message "Tarea '$taskName' eliminada"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Crea una nueva tarea programada
    #>
function Invoke-CreateTask {
    Clear-Host
    Write-Title "CREAR TAREA DIARIA"
    $name = Read-Host "`nNombre de la tarea"
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $exe = Read-Host "Ruta del ejecutable o script"
    if ([string]::IsNullOrWhiteSpace($exe)) { return }
    $time = Read-Host "Hora de ejecucion (HH:mm, Enter=09:00)"
    if ([string]::IsNullOrWhiteSpace($time)) { $time = "09:00" }
    $args = Read-Host "Argumentos (opcional)"
    if ([string]::IsNullOrWhiteSpace($args)) { $args = "" }
    try {
        $action = New-ScheduledTaskAction -Execute $exe -Argument $args
        $trigger = New-ScheduledTaskTrigger -Daily -At $time
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest
        Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Principal $principal -Force -ErrorAction Stop
        Write-Result "Tarea '$name' creada (diaria a las $time)" "OK"
        Invoke-Log -Message "Tarea programada '$name' creada: $exe a las $time"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

