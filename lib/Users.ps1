   # lib/Users.ps1
# Administracion de cuentas de usuario, grupos y contrasenas

    <#
    .SYNOPSIS
    Menu principal de administracion de usuarios
    #>
function Show-UsersMenu {
    do {
        Clear-Host
        Write-Title "ADMINISTRACION DE CUENTAS DE USUARIO"
    Write-Menu -Options @(
            "  1. Listar usuarios del sistema",
            "  2. Crear nueva cuenta de usuario",
            "  3. Modificar cuenta de usuario existente",
            "  4. Eliminar cuenta de usuario",
            "  5. Administrar permisos de usuario (grupos)",
            "  6. Gestion de contrasenas",
            "  7. Cambiar contrasena de usuario actual",
            "  8. Gestion de perfiles de usuario",
            "  0. Volver al menu principal"
        )
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 8
    switch ($opt) {
        1 { Show-UserList }
        2 { New-UserAccount }
        3 { Edit-UserAccount }
        4 { Remove-UserAccount }
        5 { Show-PermissionsMenu }
        6 { Show-PasswordMenu }
        7 { Set-CurrentUserPassword }
        8 { Show-ProfileMenu }
    }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Muestra lista de usuarios del sistema
    #>
function Show-UserList {
    Clear-Host
    Write-Title "USUARIOS DEL SISTEMA"
    try {
        $users = Get-LocalUser | Sort-Object Name
        Write-Host "`nUsuarios locales:" -ForegroundColor Cyan
        $users | Format-Table Name, FullName, Enabled, LastLogon, PasswordLastSet, Description -AutoSize -Wrap
        $detailUser = Read-Host "`nVer detalles de un usuario (ENTER para volver)"
        if (-not [string]::IsNullOrWhiteSpace($detailUser)) {
            $user = Get-LocalUser -Name $detailUser -ErrorAction SilentlyContinue
            if ($user) {
                $user | Format-List Name, FullName, Description, Enabled, PasswordLastSet, LastLogon, SID
                $groups = Get-LocalGroup | Where-Object { $_.Description -notlike "*@microsoft*" }
                Write-Host "`nGrupos a los que pertenece:" -ForegroundColor Cyan
                foreach ($g in $groups) {
                    $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
                    if ($members.Name -contains "$env:COMPUTERNAME\$detailUser") {
                        Write-Host "  - $($g.Name)" -ForegroundColor Green
                    }
                }
            } else {
                Write-Result "Usuario no encontrado" "WARN"
            }
            Pause-Message
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
        Pause-Message
    }
}

    <#
    .SYNOPSIS
    Crea una nueva cuenta de usuario local
    #>
function New-UserAccount {
    Clear-Host
    Write-Title "CREAR NUEVA CUENTA DE USUARIO"
    $userName = Read-Host "Nombre de usuario"
    if ([string]::IsNullOrWhiteSpace($userName)) { return }
    if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
        Write-Result "El usuario ya existe" "ERROR"
        Pause-Message; return
    }
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $pass1 = Read-SecurePassword "Contrasena"
    if ([string]::IsNullOrWhiteSpace($pass1)) {
        Write-Result "La contrasena no puede estar vacia" "ERROR"
        Pause-Message; return
    }
    $pass2 = Read-SecurePassword "Confirmar contrasena"
    if ($pass1 -ne $pass2) {
        Write-Result "Las contrasenas no coinciden" "ERROR"
        Pause-Message; return
    }
    $isAdmin = Read-YesNo -Prompt "Agregar al grupo Administradores" -Default "N"
    try {
        $secPass = ConvertTo-SecureString $pass1 -AsPlainText -Force
        New-LocalUser -Name $userName -Password $secPass -PasswordNeverExpires -ErrorAction Stop
        if ($isAdmin) {
            $adminGroup = Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-544' }
            if ($adminGroup) { Add-LocalGroupMember -Group $adminGroup.Name -Member $userName -ErrorAction Stop }
        }
        Invoke-Log -Message "Usuario $userName creado (admin: $isAdmin)"
        Write-Result "Usuario $userName creado exitosamente" "OK"
        if ($isAdmin) { Write-Result "  Miembro de Administradores" "OK" }
    } catch {
        Write-Result "Error al crear usuario: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Creacion de usuario $userName fallo: $_"
    }
    $pass1 = $null; $pass2 = $null
    Pause-Message
}

    <#
    .SYNOPSIS
    Modifica propiedades de una cuenta de usuario
    #>
function Edit-UserAccount {
    Clear-Host
    Write-Title "MODIFICAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $modUser = Read-Host "`nNombre de usuario a modificar"
    if ([string]::IsNullOrWhiteSpace($modUser)) { return }
    $user = Get-LocalUser -Name $modUser -ErrorAction SilentlyContinue
    if (-not $user) { Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return }
    do {
        Clear-Host
        Write-Subtitle "MODIFICAR: $modUser"
        Write-Menu -Options @(
            "  1. Cambiar nombre completo",
            "  2. Activar/Desactivar cuenta",
            "  3. Forzar cambio de contrasena en proximo inicio",
            "  4. Cambiar fecha de caducidad de contrasena",
            "  5. Cambiar descripcion",
            "  6. Cambiar ruta del perfil",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 6
        switch ($opt) {
            1 {
                $fullname = Read-Host "Nuevo nombre completo"
                Set-LocalUser -Name $modUser -FullName $fullname -ErrorAction Stop
                Write-Result "Nombre completo actualizado" "OK"
                Pause-Message
            }
            2 {
                $users | Format-Table Name, Enabled -AutoSize
                $enable = Read-YesNo -Prompt "Habilitar cuenta"
                try {
                    Set-LocalUser -Name $modUser -Enabled $enable -ErrorAction Stop
                    Write-Result "Cuenta actualizada (habilitada: $enable)" "OK"
                } catch { Write-Result "Error al actualizar cuenta: $_" "ERROR" }
                Pause-Message
            }
            3 {
                $forceChange = Read-YesNo -Prompt "Forzar cambio de contrasena al iniciar sesion"
                try {
                    Set-LocalUser -Name $modUser -PasswordExpires $forceChange -ErrorAction Stop
                    Write-Result "Configuracion actualizada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            4 {
                Write-Host "  1. Nunca caduca"
                Write-Host "  2. Establecer fecha"
                $expOpt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
                try {
                    if ($expOpt -eq 1) {
                        Set-LocalUser -Name $modUser -AccountExpires $null -ErrorAction Stop
                    } else {
                        $expDate = Read-Host "Fecha (YYYY-MM-DD)"
                        Set-LocalUser -Name $modUser -AccountExpires (Get-Date $expDate) -ErrorAction Stop
                    }
                    Write-Result "Fecha de caducidad configurada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            5 {
                $desc = Read-Host "Nueva descripcion"
                try {
                    Set-LocalUser -Name $modUser -Description $desc -ErrorAction Stop
                    Write-Result "Descripcion actualizada" "OK"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            6 {
                $profilePath = Read-Host "Nueva ruta del perfil (ej. C:\Users\NuevoPerfil)"
                try {
                    $u = Get-CimInstance Win32_UserAccount -Filter "Name='$modUser'"
                    if ($u) {
                        Set-CimInstance -InputObject $u -Property @{ ProfilePath = $profilePath } -ErrorAction Stop
                        Write-Result "Ruta de perfil actualizada" "OK"
                    }
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Elimina una cuenta de usuario local
    #>
function Remove-UserAccount {
    Clear-Host
    Write-Title "ELIMINAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $delUser = Read-Host "`nNombre de usuario a eliminar"
    if ([string]::IsNullOrWhiteSpace($delUser)) { return }
    $currentUser = $env:USERNAME
    if ($currentUser -eq $delUser) {
        Write-Result "No puede eliminar el usuario con sesion activa" "ERROR"
        Pause-Message; return
    }
    Write-Host "ADVERTENCIA: Esta accion eliminara permanentemente la cuenta." -ForegroundColor Yellow
    if (-not (Read-YesNo -Prompt "Confirmar eliminacion de '$delUser'")) { return }
    $keepFiles = Read-YesNo -Prompt "Conservar archivos del perfil (C:\Users\$delUser)" -Default "S"
    try {
        Remove-LocalUser -Name $delUser -ErrorAction Stop
        if (-not $keepFiles) {
            $profilePath = "C:\Users\$delUser"
            if (Test-Path $profilePath) {
                Write-Result "Eliminando carpeta de perfil..." "INFO"
                cmd /c "rmdir /s /q `"$profilePath`"" *>$null
            }
            $profile = Get-CimInstance Win32_UserProfile -Filter "LocalPath='$profilePath'" -ErrorAction SilentlyContinue
            if ($profile) {
                Remove-CimInstance -InputObject $profile -ErrorAction SilentlyContinue
            }
        }
        Invoke-Log -Message "Usuario $delUser eliminado (keepFiles: $keepFiles)"
        Write-Result "Usuario $delUser eliminado correctamente" "OK"
        if ($keepFiles) { Write-Host "  Archivos del perfil conservados en C:\Users\$delUser" -ForegroundColor Gray }
    } catch {
        Write-Result "Error al eliminar: $_" "ERROR"
        Write-Host "Cierre sesiones activas e intente nuevamente" -ForegroundColor Gray
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Menu de administracion de grupos y permisos
    #>
function Show-PermissionsMenu {
    Clear-Host
    Write-Title "ADMINISTRAR PERMISOS DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name -AutoSize
    $permUser = Read-Host "`nNombre de usuario para modificar permisos"
    if ([string]::IsNullOrWhiteSpace($permUser)) { return }
    $user = Get-LocalUser -Name $permUser -ErrorAction SilentlyContinue
    if (-not $user) { Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return }
    do {
        Clear-Host
        Write-Subtitle "PERMISOS DE: $permUser"
        Write-Host "Grupos actuales:" -ForegroundColor Cyan
        $groups = Get-LocalGroup | Where-Object { $_.Description -notlike "*@microsoft*" }
        foreach ($g in $groups) {
            $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
            if ($members.Name -contains "$env:COMPUTERNAME\$permUser") {
                Write-Host "  - $($g.Name)" -ForegroundColor Green
            }
        }
        Write-Menu -Options @(
            "  1. Agregar a grupo",
            "  2. Quitar de grupo",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 2
        switch ($opt) {
            1 {
                $groupsAvail = Get-LocalGroup | Sort-Object Name
                $groupsAvail | Format-Table Name, Description -AutoSize
                $addGroup = Read-Host "Nombre del grupo"
                try {
                    $members = Get-LocalGroupMember -Group $addGroup -ErrorAction Stop
                    if ($members.Name -contains "$env:COMPUTERNAME\$permUser") {
                        Write-Result "El usuario ya es miembro de '$addGroup'" "WARN"
                    } else {
                        Add-LocalGroupMember -Group $addGroup -Member $permUser -ErrorAction Stop
                        Write-Result "Usuario agregado a '$addGroup'" "OK"
                        Invoke-Log -Message "$permUser agregado al grupo $addGroup"
                    }
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
            2 {
                $groupsOf = @()
                $allGroups = Get-LocalGroup | Sort-Object Name
                foreach ($g in $allGroups) {
                    $members = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
                    if ($members.Name -contains "$env:COMPUTERNAME\$permUser") { $groupsOf += $g.Name }
                }
                if ($groupsOf.Count -eq 0) { Write-Result "Usuario no pertenece a ningun grupo" "INFO"; Pause-Message; break }
                Write-Host "Grupos: $($groupsOf -join ', ')" -ForegroundColor Cyan
                $remGroup = Read-Host "Nombre del grupo del que quitar"
                $usersGroup = Get-LocalGroup | Where-Object { $_.SID -eq 'S-1-5-32-545' }
                if ($remGroup -eq $usersGroup.Name) {
                    if (-not (Read-YesNo -Prompt "Quitar del grupo $($usersGroup.Name) puede causar problemas. Continuar")) { break }
                }
                try {
                    Remove-LocalGroupMember -Group $remGroup -Member $permUser -ErrorAction Stop
                    Write-Result "Usuario quitado de '$remGroup'" "OK"
                    Invoke-Log -Message "$permUser quitado del grupo $remGroup"
                } catch { Write-Result "Error: $_" "ERROR" }
                Pause-Message
            }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Menu de gestion de contrasenas
    #>
function Show-PasswordMenu {
    do {
        Clear-Host
        Write-Title "GESTION DE CONTRASENAS"
        Write-Menu -Options @(
            "  1. Resetear contrasena de usuario",
            "  2. Establecer politica de contrasenas",
            "  3. Ver contrasenas almacenadas",
            "  4. Desbloquear cuenta de usuario",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Reset-UserPassword }
            2 { Set-PasswordPolicy }
            3 { Show-StoredCredentials }
            4 { Unlock-UserAccount }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Resetea la contrasena de un usuario
    #>
function Reset-UserPassword {
    Clear-Host
    Write-Title "RESETEAR CONTRASENA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name -AutoSize
    $resetUser = Read-Host "`nNombre de usuario"
    if ([string]::IsNullOrWhiteSpace($resetUser)) { return }
    if (-not (Get-LocalUser -Name $resetUser -ErrorAction SilentlyContinue)) {
        Write-Result "Usuario no encontrado" "ERROR"; Pause-Message; return
    }
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $newPass = Read-SecurePassword "Nueva contrasena"
    try {
        $secPass = ConvertTo-SecureString $newPass -AsPlainText -Force
        Set-LocalUser -Name $resetUser -Password $secPass -ErrorAction Stop
        Invoke-Log -Message "Contrasena reseteada para $resetUser"
        Write-Result "Contrasena cambiada correctamente para $resetUser" "OK"
    } catch {
        Write-Result "Error: $_" "ERROR"
        Invoke-Log -Level "ERROR" -Message "Reset password para $resetUser fallo: $_"
    }
    $newPass = $null
    Pause-Message
}

    <#
    .SYNOPSIS
    Configura la politica de contrasenas local
    #>
function Set-PasswordPolicy {
    Clear-Host
    Write-Title "POLITICA DE CONTRASENAS (LOCAL)"
    try {
        $policy = net accounts 2>$null
        $policy | Select-String -Pattern "Longitud|Edad|Historial|vigencia|caracteres" | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    } catch {}
    Write-Menu -Options @(
        "  1. Longitud minima de contrasena (0-14)",
        "  2. Edad maxima de contrasena (dias)",
        "  3. Historial de contrasenas (0-24)",
        "  0. Volver"
    )
    $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 3
    switch ($opt) {
        1 {
            do { $len = Read-Host "Longitud minima (0-14)" } while ($len -notmatch '^\d+$' -or [int]$len -lt 0 -or [int]$len -gt 14)
            cmd /c "net accounts /minpwlen:$len >nul"
            Write-Result "Longitud minima establecida a $len" "OK"
            Invoke-Log -Message "Password min length set to $len"
            Pause-Message
        }
        2 {
            do { $age = Read-Host "Edad maxima en dias (0=nunca)" } while ($age -notmatch '^\d+$')
            cmd /c "net accounts /maxpwage:$age >nul"
            Write-Result "Edad maxima establecida a $age dias" "OK"
            Invoke-Log -Message "Password max age set to $age"
            Pause-Message
        }
        3 {
            do { $hist = Read-Host "Historial (0-24)" } while ($hist -notmatch '^\d+$' -or [int]$hist -lt 0 -or [int]$hist -gt 24)
            cmd /c "net accounts /uniquepw:$hist >nul"
            Write-Result "Historial establecido a $hist" "OK"
            Invoke-Log -Message "Password history set to $hist"
            Pause-Message
        }
    }
}

    <#
    .SYNOPSIS
    Muestra credenciales almacenadas en el sistema
    #>
function Show-StoredCredentials {
    Clear-Host
    Write-Title "CONTRASENAS ALMACENADAS"
    Write-Host "Mostrando credenciales almacenadas en el sistema..." -ForegroundColor Cyan
    cmdkey /list
    Write-Host "`nNota: Las contrasenas de cuentas locales no son recuperables directamente." -ForegroundColor Yellow
    Pause-Message
}

    <#
    .SYNOPSIS
    Desbloquea una cuenta de usuario
    #>
function Unlock-UserAccount {
    Clear-Host
    Write-Title "DESBLOQUEAR CUENTA DE USUARIO"
    $users = Get-LocalUser | Sort-Object Name
    $users | Format-Table Name, Enabled -AutoSize
    $unlockUser = Read-Host "`nNombre de usuario a desbloquear"
    if ([string]::IsNullOrWhiteSpace($unlockUser)) { return }
    try {
        $user = Get-LocalUser -Name $unlockUser -ErrorAction Stop
        net user $unlockUser /active:yes *>$null
        if ($LASTEXITCODE -eq 0) {
            Invoke-Log -Message "Cuenta $unlockUser desbloqueada"
            Write-Result "Cuenta desbloqueada correctamente" "OK"
        } else {
            Write-Result "Error al desbloquear cuenta" "ERROR"
        }
    } catch {
        Write-Result "Error: $_" "ERROR"
    }
    Pause-Message
}

    <#
    .SYNOPSIS
    Cambia la contrasena del usuario actual
    #>
function Set-CurrentUserPassword {
    Clear-Host
    Write-Title "CAMBIAR CONTRASENA DE USUARIO ACTUAL"
    Write-Host "`nLa contrasena no se mostrara mientras escribe." -ForegroundColor Yellow
    $currentUser = $env:USERNAME
    $newPass1 = Read-SecurePassword "Nueva contrasena"
    $newPass2 = Read-SecurePassword "Confirmar nueva contrasena"
    if ($newPass1 -ne $newPass2) {
        Write-Result "Las contrasenas no coinciden" "ERROR"
        Pause-Message; return
    }
    try {
        $secPass = ConvertTo-SecureString $newPass1 -AsPlainText -Force
        Set-LocalUser -Name $currentUser -Password $secPass -ErrorAction Stop
        net user "$currentUser" "$newPass1" /logonpasswordchg:yes *>$null
        Invoke-Log -Message "Contrasena cambiada para $currentUser"
        Write-Result "Contrasena cambiada correctamente" "OK"
    } catch {
        Write-Result "Error al cambiar contrasena: $_" "ERROR"
    }
    $newPass1 = $null; $newPass2 = $null
    Pause-Message
}

# ============================================================
# GESTION DE PERFILES DE USUARIO (Win32_UserProfile)
# ============================================================

    <#
    .SYNOPSIS
    Menu de gestion de perfiles de usuario
    #>
function Show-ProfileMenu {
    do {
        Clear-Host
        Write-Title "PERFILES DE USUARIO"
        Write-Menu -Options @(
            "  1. Listar perfiles de usuario",
            "  2. Ver detalle de un perfil",
            "  3. Eliminar perfil de usuario",
            "  4. Eliminar perfiles huerfanos",
            "  0. Volver"
        )
        $opt = Read-MenuChoice -Prompt "Seleccione opcion" -Max 4
        switch ($opt) {
            1 { Show-ProfileList }
            2 { Show-ProfileDetail }
            3 { Remove-UserProfile }
            4 { Remove-OrphanProfiles }
        }
    } while ($opt -ne 0)
}

    <#
    .SYNOPSIS
    Calcula el tamano de un perfil de usuario
    #>
function Get-ProfileSize {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "N/A" }
    try {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        if (-not $size) { return "0 B" }
        if ($size -gt 1GB) { return "{0:N2} GB" -f ($size / 1GB) }
        if ($size -gt 1MB) { return "{0:N2} MB" -f ($size / 1MB) }
        return "{0:N2} KB" -f ($size / 1KB)
    } catch { return "Error" }
}

    <#
    .SYNOPSIS
    Lista todos los perfiles de usuario
    #>
function Show-ProfileList {
    Clear-Host
    Write-Title "PERFILES DE USUARIO"
    try {
        $profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop
        if (-not $profiles) { Write-Result "No se encontraron perfiles" "WARN"; Pause-Message; return }
        $users = Get-LocalUser
        Write-Host "Total: $($profiles.Count) perfiles`n" -ForegroundColor Gray
        $profiles | Sort-Object LastUseTime -Descending | ForEach-Object {
            $sid = $_.SID
            $userName = "N/A"
            $localPath = $_.LocalPath
            $loaded = if ($_.Loaded) { "SI" } else { "NO" }
            $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
            $size = Get-ProfileSize -Path $localPath
            try {
                $account = $users | Where-Object { $_.SID.Value -eq $sid } | Select-Object -First 1
                if ($account) { $userName = $account.Name }
                else { $userName = "HUERFANO" }
            } catch {}
            Write-Host ("{0,-20} {1,-12} {2,-5} {3,-12} {4}" -f $userName, $size, $loaded, $lastUse, $localPath)
        }
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Muestra detalle de un perfil de usuario
    #>
function Show-ProfileDetail {
    Clear-Host
    Write-Title "DETALLE DE PERFIL"
    $target = Read-Host "`nNombre de usuario o ruta del perfil"
    if ([string]::IsNullOrWhiteSpace($target)) { return }
    try {
        $filter = "LocalPath LIKE '%$target%' OR SID='$target'"
        $profile = Get-CimInstance Win32_UserProfile -Filter $filter -ErrorAction SilentlyContinue
        if (-not $profile) {
            $profile = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { $_.SID -eq $target -or $_.LocalPath -like "*$target*" } | Select-Object -First 1
        }
        if (-not $profile) { Write-Result "Perfil no encontrado" "WARN"; Pause-Message; return }
        Write-Host "`nRuta:       $($profile.LocalPath)" -ForegroundColor White
        Write-Host "SID:        $($profile.SID)" -ForegroundColor White
        Write-Host "Cargado:    $(if ($profile.Loaded) { 'SI' } else { 'NO' })" -ForegroundColor $(if ($profile.Loaded) { 'Green' } else { 'Gray' })
        if ($profile.LastUseTime) {
            Write-Host "Ultimo uso: $($profile.LastUseTime.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor White
        }
        Write-Host "Tamanio:    $(Get-ProfileSize $profile.LocalPath)" -ForegroundColor White
        if ($profile.RoamingPreference) {
            Write-Host "Itinerante: $($profile.RoamingPreference)" -ForegroundColor White
        }
        try {
            $owner = Get-WmiObject Win32_UserAccount -Filter "SID='$($profile.SID)'" -ErrorAction SilentlyContinue
            if ($owner) { Write-Host "Cuenta:     $($owner.Name)" -ForegroundColor Green }
            else { Write-Host "Cuenta:     HUERFANA (sin usuario asociado)" -ForegroundColor Red }
        } catch {}
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina un perfil de usuario
    #>
function Remove-UserProfile {
    Clear-Host
    Write-Title "ELIMINAR PERFIL DE USUARIO"
    $profiles = Get-CimInstance Win32_UserProfile -ErrorAction SilentlyContinue
    if (-not $profiles) { Write-Result "No se encontraron perfiles" "WARN"; Pause-Message; return }
    $profiles | Sort-Object LastUseTime -Descending | ForEach-Object {
        $localPath = $_.LocalPath
        $sid = $_.SID
        $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
        try {
            $account = Get-LocalUser | Where-Object { $_.SID.Value -eq $sid } | Select-Object -First 1
            $userName = if ($account) { $account.Name } else { "HUERFANO" }
        } catch { $userName = $sid }
        Write-Host ("  {0,-20} Ultimo uso: {1}" -f $userName, $lastUse)
    }
    $delProfile = Read-Host "`nNombre de usuario o ruta del perfil a eliminar"
    if ([string]::IsNullOrWhiteSpace($delProfile)) { return }
    $sidMatch = whoami /user 2>$null | Select-String "S-1-5-21-[0-9-]+"
    $currentSID = if ($sidMatch) { $sidMatch.Matches.Value } else { $null }
    try {
        $target = $profiles | Where-Object { $_.LocalPath -like "*$delProfile*" -or $_.SID -eq $delProfile } | Select-Object -First 1
        if (-not $target) { Write-Result "Perfil no encontrado" "ERROR"; Pause-Message; return }
        if ($target.SID -eq $currentSID) {
            Write-Result "No puede eliminar el perfil de la sesion activa" "ERROR"
            Pause-Message; return
        }
        if ($target.Loaded) {
            Write-Result "El perfil esta cargado. Cierre sesion del usuario e intente nuevamente." "WARN"
            Pause-Message; return
        }
        $folderName = Split-Path $target.LocalPath -Leaf
        Write-Host "`nSe eliminara: $folderName ($($target.LocalPath))" -ForegroundColor Yellow
        if (-not (Read-YesNo -Prompt "Confirmar eliminacion")) { return }
        if (Test-Path $target.LocalPath) {
            cmd /c "rmdir /s /q `"$($target.LocalPath)`"" *>$null
        }
        Remove-CimInstance -InputObject $target -ErrorAction Stop
        Invoke-Log -Message "Perfil de usuario $folderName eliminado"
        Write-Result "Perfil eliminado correctamente" "OK"
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

    <#
    .SYNOPSIS
    Elimina perfiles huerfanos (sin usuario asociado)
    #>
function Remove-OrphanProfiles {
    Clear-Host
    Write-Title "PERFILES HUERFANOS"
    try {
        $profiles = Get-CimInstance Win32_UserProfile -ErrorAction Stop
        $users = Get-LocalUser
        $orphans = @()
        foreach ($p in $profiles) {
            $hasUser = $users | Where-Object { $_.SID.Value -eq $p.SID } | Select-Object -First 1
            if (-not $hasUser) { $orphans += $p }
        }
        if ($orphans.Count -eq 0) {
            Write-Result "No se encontraron perfiles huerfanos" "OK"
            Pause-Message; return
        }
        Write-Host "Perfiles huerfanos encontrados: $($orphans.Count)`n" -ForegroundColor Yellow
        $orphans | ForEach-Object {
            $size = Get-ProfileSize $_.LocalPath
            $lastUse = if ($_.LastUseTime) { $_.LastUseTime.ToString("yyyy-MM-dd") } else { "Nunca" }
            Write-Host "  $($_.LocalPath) | $size | Ultimo uso: $lastUse"
        }
        if (-not (Read-YesNo -Prompt "Eliminar TODOS los perfiles huerfanos")) { return }
        $deleted = 0; $errors = 0
        foreach ($p in $orphans) {
            if ($p.Loaded) {
                Write-Result "Perfil cargado: $($p.LocalPath) -- se omite" "WARN"
                $errors++; continue
            }
            try {
                if (Test-Path $p.LocalPath) {
                    cmd /c "rmdir /s /q `"$($p.LocalPath)`"" *>$null
                }
                Remove-CimInstance -InputObject $p -ErrorAction Stop
                $deleted++
                Invoke-Log -Message "Perfil huerfano eliminado: $($p.LocalPath)"
            } catch { $errors++ }
        }
        $resultStatus = "WARN"
        if ($errors -eq 0) { $resultStatus = "OK" }
        Write-Result "$deleted perfiles eliminados, $errors errores" $resultStatus
    } catch { Write-Result "Error: $_" "ERROR" }
    Pause-Message
}

