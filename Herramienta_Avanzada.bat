@echo off
chcp 1252 >nul

:: Verificar permisos de administrador
>nul 2>&1 icacls "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    color 0E
    echo No tiene permisos de administrador.
    echo Solicitando elevación...

    :: Crear un VBS temporal para solicitar elevación
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

:: Mensaje de inicio
cls
color 0A
echo ====================================================================
echo                        HERRAMIENTA AVANZADA
echo ====================================================================
echo.
echo      Bienvenido a la Herramienta Avanzada de Administración de Sistemas.
echo.
echo   Esta herramienta proporciona un conjunto de funciones avanzadas para la
echo   administración de sistemas, incluyendo mantenimiento del sistema, gestión
echo   de red, seguridad, información del sistema, administración de usuarios,
echo   y más. Cada opción del menú principal le guiará a un submenú específico
echo   donde podrá realizar tareas detalladas.
echo.
echo   Desarrollado por: Jose Gabriel
echo.
echo   Propósito: Facilitar tareas de administración de sistemas para usuarios
echo   avanzados y profesionales.
echo.
echo   Presione cualquier tecla para continuar...
echo.
pause >nul
cls

:: Si llega aquí, significa que ya tiene permisos de administrador
title Herramienta Avanzada v5.2 ANSI - By [Jose Gabriel]

:: Definir códigos de colores para diferentes secciones
set COLOR_TITLE=0A
set COLOR_MENU=0B
set COLOR_INFO=0F
set COLOR_SUCCESS=0A
set COLOR_WARNING=0E
set COLOR_ERROR=0C
set COLOR_PROCESSING=0D

:: Detectar versión de Windows
for /f "tokens=4-5 delims=[]. " %%i in ('ver') do set "version=%%i.%%j"
echo Versión de Windows detectada: %version%
timeout /t 2 >nul

:menu_principal
cls
color %COLOR_TITLE%
echo ====================================================================
echo      HERRAMIENTA TECNICA AVANZADA - By [Jose Gabriel]
echo ====================================================================
color %COLOR_MENU%
echo 1.  Mantenimiento del Sistema
echo 2.  Red y Conexiones
echo 3.  Seguridad y Firewall
echo 4.  Información del Sistema
echo 5.  Apagar/Reiniciar/Bloqueo Avanzado
echo 6.  Administrar dispositivos USB
echo 7.  Configuración del equipo - Cambiar nombre, grupo, descripción
echo 8.  Administración de cuentas de usuario
echo 9.  Administración de Carpetas Compartidas
echo 10. Gestionar Archivos Ocultos
echo 11. Administración de Servicios
echo 12. Administrar Aplicaciones de Inicio
echo 13. Copia de seguridad de controladores
echo 14. Ayuda
echo  0. salir
echo ====================================================================
set /p "opcion=Seleccione una opción [0-14]: "

if "%opcion%"== "0" goto salir
if "%opcion%"=="14" goto ayuda_principal 
if "%opcion%"=="13" goto menu_backup_drivers 
if "%opcion%"=="12" goto menu_aplicaciones_inicio
if "%opcion%"=="11" goto menu_servicios
if "%opcion%"=="10" goto menu_archivos_ocultos
if "%opcion%"=="9"  goto menu_compartidas
if "%opcion%"=="8"  goto menu_usuarios
if "%opcion%"=="7"  goto menu_configuracion
if "%opcion%"=="6"  goto menu_usb
if "%opcion%"=="5"  goto menu_apagado
if "%opcion%"=="4"  goto menu_info
if "%opcion%"=="3"  goto menu_seguridad
if "%opcion%"=="2"  goto menu_red
if "%opcion%"=="1"  goto menu_mantenimiento

echo Opción no válida.
pause
goto menu_principal

===================================================================================================================================
:ayuda_principal
cls
color %COLOR_INFO%
echo ==========================================================
echo           AYUDA - MENÚ PRINCIPAL
echo ==========================================================
echo 1. Mantenimiento del Sistema: Limpia archivos temporales, repara archivos del sistema, optimiza unidades, desactiva hibernación, gestiona puntos de restauración, comprueba disco y limpia caché de Windows Update.
echo 2. Red y Conexiones: Muestra la configuración de red, renueva la dirección IP, limpia la caché DNS, y restablece TCP/IP.
echo 3. Seguridad y Firewall: Activa, desactiva y muestra el estado del firewall del sistema.
echo 4. Información del Sistema: Muestra información del hardware y software del sistema, incluyendo programas instalados y servicios en ejecución.
echo 5. Apagar/Reiniciar/Bloqueo Avanzado: Ofrece opciones para apagar, reiniciar o bloquear el sistema.
echo 6. Administrar dispositivos USB: Permite desconectar o montar dispositivos USB.
echo 7. Configuración del equipo: Permite cambiar el nombre, grupo de trabajo y descripción del equipo.
echo 8. Administración de cuentas de usuario: Crear, modificar y eliminar cuentas, gestionar permisos y contraseñas.
echo 9. Administración de Carpetas Compartidas: Listar, crear y eliminar carpetas compartidas.
echo 10. Gestionar Archivos Ocultos: Permite mostrar u ocultar archivos ocultos y protegidos del sistema.
echo 11. Administración de Servicios: Permite gestionar servicios en ejecución, incluyendo iniciar, detener y reiniciar servicios.
echo 12. Administrar Aplicaciones de Inicio: Permite ver y gestionar aplicaciones que se inician automáticamente.
echo 13. Copia de seguridad de controladores: Permite crear y restaurar copias de seguridad de los controladores del sistema.
echo 14. Ayuda: Muestra esta información de ayuda.
echo 15. Permisos y Eliminación de Carpetas: Herramientas para tomar posesión, otorgar control y eliminar carpetas con problemas de permisos.
echo 0. Salir: Finaliza la ejecución de la herramienta.
echo ==========================================================
pause
===================================================================================================================================
:menu_mantenimiento
cls
color %COLOR_TITLE%
echo ================================================
echo              MANTENIMIENTO DEL SISTEMA
echo ================================================
color %COLOR_MENU%
echo 1. Limpiar archivos temporales
echo 2. Reparar archivos del sistema (sfc /scannow)
echo 3. Optimizar unidades (HDD/SSD)
echo 4. Desactivar hibernación (Liberar espacio)
echo 5. Comprobar Disco (CHKDSK)
echo 6. Gestión de Puntos de Restauración
echo 7. Limpiar Caché de Windows Update
echo 8. Volver al menu principal
echo ================================================
choice /C 12345678 /N /M "Seleccione una opción [1-8]: "

if errorlevel 8 goto menu_principal
if errorlevel 7 goto limpiar_windows_update
if errorlevel 6 goto restore_point_menu
if errorlevel 5 goto chkdsk
if errorlevel 4 goto desactivar_hibernacion
if errorlevel 3 goto optimizar_ps
if errorlevel 2 goto reparar_sfc
if errorlevel 1 goto limpiar


:limpiar
cls
color %COLOR_TITLE%
echo ==========================================================
echo    LIMPIEZA SEGURA DE ARCHIVOS TEMPORALES
echo ==========================================================
color %COLOR_PROCESSING%
echo Eliminando archivos temporales y vaciando papelera...

:: Eliminar contenido de carpetas temporales comunes
RD /S /Q "%temp%" 2>nul
MKDIR "%temp%" 2>nul
RD /S /Q "%WINDIR%\Temp" 2>nul
MKDIR "%WINDIR%\Temp" 2>nul
RD /S /Q "%LOCALAPPDATA%\Temp" 2>nul
MKDIR "%LOCALAPPDATA%\Temp" 2>nul

:: Vaciar Papelera de Reciclaje de todas las unidades
echo Vaciando Papelera de Reciclaje...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"

color %COLOR_SUCCESS%
echo ? Proceso de limpieza completado.
pause
goto menu_mantenimiento

:reparar_sfc
cls
color %COLOR_TITLE%
echo ==========================================================
echo         REPARACIÓN DE ARCHIVOS DEL SISTEMA (SFC)
echo ==========================================================
color %COLOR_WARNING%
echo Advertencia: Este proceso puede tardar bastante tiempo.
echo No apague ni reinicie el equipo durante el proceso.
echo Verá el progreso directamente en la ventana.
echo.
color %COLOR_PROCESSING%
echo Iniciando verificación y reparación de archivos del sistema...
echo.

sfc /scannow

echo.
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? SFC finalizó con errores (Código %errorlevel%).
    echo Protección de recursos de Windows encontró archivos dañados pero no pudo corregir algunos de ellos,
    echo o no pudo realizar la operación solicitada.
    echo Revise los detalles en el archivo CBS.log ubicado en %windir%\Logs\CBS\CBS.log
    echo Puede ser necesario ejecutar DISM /Online /Cleanup-Image /RestoreHealth primero.
) else (
    color %COLOR_SUCCESS%
    echo ? SFC completado exitosamente.
    echo Protección de recursos de Windows no encontró ninguna infracción de integridad,
    echo o encontró archivos dañados y los reparó correctamente.
)
pause
goto menu_mantenimiento

:optimizar_ps
cls
color %COLOR_TITLE%
echo ==========================================================
echo         OPTIMIZACIÓN DE UNIDADES (HDD/SSD con PowerShell)
echo ==========================================================
color %COLOR_INFO%
echo Listando unidades disponibles (Fijas y SSD/HDD)...
echo.
powershell -NoProfile -Command "Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Format-Table DriveLetter, FileSystemLabel, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB, 2)}}, @{Name='FreeSpace(GB)';Expression={[math]::Round($_.SizeRemaining/1GB, 2)}}, HealthStatus, DriveType"
echo.
set /p "driveLetter=Ingrese la letra de la unidad a optimizar (C, D, etc.): "
set "driveLetter=%driveLetter:~0,1%"

:: Validar que la letra no esté vacía
if not defined driveLetter (
    color %COLOR_ERROR%
    echo ? Error: No ingresó una letra de unidad.
    pause
    goto menu_mantenimiento
)

:: Validar la unidad con PowerShell
echo Verificando unidad %driveLetter%: ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Volume -DriveLetter '%driveLetter%' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    color %COLOR_ERROR%
    echo ? Error: La unidad %driveLetter%: no es válida o no se encontró.
    pause
    goto menu_mantenimiento
)

color %COLOR_PROCESSING%
echo Optimizando unidad %driveLetter%: ...
echo Este proceso puede tardar. Verá el progreso (-Verbose).
echo (Para SSDs, esto ejecuta Trim; para HDDs, desfragmenta)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Optimize-Volume -DriveLetter %driveLetter% -Verbose"
set optimizeExitCode=%errorlevel%

echo.
if %optimizeExitCode% EQU 0 (
    color %COLOR_SUCCESS%
    echo ? Optimización de la unidad %driveLetter%: completada exitosamente.
) else (
    color %COLOR_ERROR%
    echo ? Error: La optimización falló (Código %optimizeExitCode%).
    echo Revise los mensajes de PowerShell para más detalles.
)
pause
goto menu_mantenimiento

:chkdsk
cls
color %COLOR_TITLE%
echo ================================================
echo              COMPROBACIÓN DE DISCO (CHKDSK)
echo ================================================
color %COLOR_INFO%
echo Listando unidades de disco fijo disponibles...
echo.
powershell -NoProfile -Command "Get-Volume | Where-Object {$_.DriveType -eq 'Fixed'} | Format-Table DriveLetter, FileSystemLabel, @{Name='Size(GB)';Expression={[math]::Round($_.Size/1GB, 2)}}, @{Name='FreeSpace(GB)';Expression={[math]::Round($_.SizeRemaining/1GB, 2)}}, HealthStatus"
echo.
set /p "driveToCheck=Ingrese la letra de la unidad a comprobar (C, D, etc.): "
set "driveToCheck=%driveToCheck:~0,1%"

:: Validación robusta con PowerShell
if not defined driveToCheck (
    color %COLOR_ERROR%
    echo ? Error: No ingresó una letra de unidad.
    pause
    goto menu_mantenimiento
)
echo Verificando la unidad %driveToCheck%: ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Volume -DriveLetter '%driveToCheck%' -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if errorlevel 1 (
    color %COLOR_ERROR%
    echo ? Error: La unidad %driveToCheck%: no es válida o no se encontró.
    pause
    goto menu_mantenimiento
)
echo ? Unidad %driveToCheck%: encontrada.
echo.

color %COLOR_WARNING%
echo ADVERTENCIA MUY IMPORTANTE:
echo La opción /f intenta corregir errores en el disco.
echo La opción /r localiza sectores defectuosos e intenta recuperar datos (incluye /f).
echo Este proceso puede tardar MUCHO TIEMPO, especialmente con /r.
echo Si se ejecuta en la unidad del sistema (C:), probablemente requerirá un REINICIO para completarse.
echo Existe un riesgo (bajo) de pérdida de datos si el disco está gravemente dañado. Haga copias de seguridad si es posible.
echo.
set /p "confirmChk=¿Está seguro de que desea ejecutar CHKDSK /f /r en %driveToCheck%:? (S/N): "
if /I not "%confirmChk%"=="S" (
    color %COLOR_INFO%
    echo Operación cancelada.
    pause
    goto menu_mantenimiento
)

color %COLOR_PROCESSING%
echo Iniciando CHKDSK %driveToCheck%: /f /r ...
echo Por favor, sea paciente. Esto puede llevar horas en discos grandes o dañados.
echo Si se le solicita programar la comprobación en el próximo reinicio, escriba 'S' y presione Enter.
echo.
chkdsk %driveToCheck%: /f /r
set chkdskExitCode=%errorlevel%

echo.
if %chkdskExitCode% EQU 0 (
    color %COLOR_SUCCESS%
    echo ? CHKDSK completado. No se encontraron errores o no requirió acción.
) else if %chkdskExitCode% EQU 1 (
    color %COLOR_SUCCESS%
    echo ? CHKDSK completado. Se encontraron y corrigieron errores.
    echo Es posible que necesite reiniciar si la comprobación fue en la unidad C: y requirió desmontaje.
) else if %chkdskExitCode% EQU 2 (
    color %COLOR_WARNING%
    echo ! CHKDSK realizó limpieza (similar a /f) o encontró errores pero no los corrigió (porque no se especificó /f o no se pudo bloquear).
    echo Código de Salida: %chkdskExitCode%
) else if %chkdskExitCode% EQU 3 (
    color %COLOR_ERROR%
    echo ? Error: CHKDSK no pudo completarse o fue cancelado.
    echo Posibles causas: El volumen estaba bloqueado y no se pudo programar, o se canceló manualmente.
    echo Código de Salida: %chkdskExitCode%
) else (
    color %COLOR_ERROR%
    echo ? Error: CHKDSK finalizó con un código de error inesperado.
    echo Código de Salida: %chkdskExitCode%
)

pause
goto menu_mantenimiento


:menu_hibernacion
cls
color %COLOR_TITLE%
echo ================================================
echo            GESTIÓN DE HIBERNACIÓN
echo ================================================
color %COLOR_MENU%
echo 1. Desactivar hibernación (powercfg /h off)
echo 2. Activar hibernación   (powercfg /h on)
echo 3. Mostrar estado de hibernación
echo 4. Volver al menú mantenimiento
echo ================================================
set /p "hibOption=Seleccione una opción [1-4]: "

if "%hibOption%"=="4" goto menu_mantenimiento
if "%hibOption%"=="3" goto estado_hibernacion
if "%hibOption%"=="2" goto activar_hibernacion
if "%hibOption%"=="1" goto desactivar_hibernacion

echo Opción no válida.
pause
goto menu_hibernacion

:desactivar_hibernacion
cls
color %COLOR_PROCESSING%
echo Desactivando hibernación y liberando espacio en disco...
powercfg /h off
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo desactivar la hibernación.
) else (
    color %COLOR_SUCCESS%
    echo ? Hibernación desactivada correctamente.
)
pause
goto menu_hibernacion

:activar_hibernacion
cls
color %COLOR_PROCESSING%
echo Activando hibernación y reservando espacio en disco...
powercfg /h on
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo activar la hibernación.
) else (
    color %COLOR_SUCCESS%
    echo ? Hibernación activada correctamente.
)
pause
goto menu_hibernacion

:estado_hibernacion
cls
color %COLOR_PROCESSING%
echo Comprobando el estado de la hibernación vía PowerShell...
echo.

:: Llamada única a PowerShell para leer HibernateEnabled en el registro
powershell -NoProfile -Command "try { $h = (Get-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power' -Name HibernateEnabled -ErrorAction Stop).HibernateEnabled; if ($h -eq 1) { exit 0 } else { exit 1 } } catch { exit 2 }"
set psExit=%errorlevel%

if %psExit% EQU 0 (
    color %COLOR_SUCCESS%
    echo ? La hibernación ESTÁ ACTIVADA.
) else if %psExit% EQU 1 (
    color %COLOR_WARNING%
    echo ? La hibernación ESTÁ DESACTIVADA.
) else (
    color %COLOR_ERROR%
    echo ? No se pudo determinar el estado de la hibernación.
)

echo.
pause
goto menu_hibernacion


:restore_point_menu
cls
color %COLOR_TITLE%
echo ================================================
echo           GESTIÓN DE PUNTOS DE RESTAURACIÓN
echo ================================================
color %COLOR_MENU%
echo 1. Crear Punto de Restauración
echo 2. Listar Puntos de Restauración existentes
echo 3. Volver al Menú de Mantenimiento
echo ================================================
choice /C 123 /N /M "Seleccione una opción [1-3]: "

if errorlevel 3 goto menu_mantenimiento
if errorlevel 2 goto list_restore_points
if errorlevel 1 goto create_restore_point

:create_restore_point
cls
color %COLOR_TITLE%
echo ================================================
echo           CREAR PUNTO DE RESTAURACIÓN
echo ================================================
color %COLOR_WARNING%
echo Esta acción creará un punto de restauración del sistema manual.
echo Puede tardar unos minutos. Asegúrese de que la Protección del Sistema esté activa para C:.
echo.
set /p "confirmRP=¿Está seguro de que desea crear un punto de restauración? (S/N): "
if /I not "%confirmRP%"=="S" (
    color %COLOR_INFO%
    echo Operación cancelada.
    pause
    goto restore_point_menu
)

color %COLOR_PROCESSING%
echo Creando punto de restauración... Por favor espere...

powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Punto Creado por Herramienta Avanzada v4.8' -RestorePointType 'MODIFY_SETTINGS'"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo crear el punto de restauración (Código %errorlevel%).
    echo Asegúrese de que el servicio 'Instantáneas de volumen' (VSS) esté en ejecución y que la protección del sistema esté activada para la unidad C:.
) else (
    color %COLOR_SUCCESS%
    echo ? Punto de restauración creado exitosamente.
)
pause
goto restore_point_menu

:list_restore_points
cls
color %COLOR_TITLE%
echo ================================================
echo        LISTAR PUNTOS DE RESTAURACIÓN
echo ================================================
color %COLOR_PROCESSING%
echo Obteniendo lista de puntos de restauración...
echo.
powershell -ExecutionPolicy Bypass -Command "Get-ComputerRestorePoint | Format-Table SequenceNumber, CreationTime, Description, RestorePointType -AutoSize"
echo.
color %COLOR_INFO%
echo Lista mostrada arriba.
pause
goto restore_point_menu

:limpiar_windows_update
cls
color %COLOR_TITLE%
echo ==========================================================
echo         LIMPIEZA DE CACHÉ DE WINDOWS UPDATE
echo ==========================================================
color %COLOR_PROCESSING%
echo Intentando detener servicios relacionados con Windows Update...
echo (Pueden aparecer errores si algunos servicios no están en ejecución, es normal)
net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net stop dosvc /y >nul 2>&1
:: net stop UsoSvc /y >nul 2>&1 :: Este servicio puede ser más difícil de detener y no siempre es necesario

echo Eliminando contenido de la carpeta SoftwareDistribution...
:: Tomar posesión por si acaso hay problemas de permisos
takeown /f "%WINDIR%\SoftwareDistribution" /r /d Y >nul 2>&1
icacls "%WINDIR%\SoftwareDistribution" /grant administrators:F /t /c /l /q >nul 2>&1
RD /S /Q "%WINDIR%\SoftwareDistribution"
if errorlevel 1 (
  color %COLOR_WARNING%
  echo ! Advertencia: No se pudo eliminar completamente la carpeta SoftwareDistribution. Puede que algunos archivos estuvieran en uso.
)

echo Recreando carpeta SoftwareDistribution...
MKDIR "%WINDIR%\SoftwareDistribution"

echo Reiniciando servicios (o se iniciarán automáticamente más tarde)...
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
net start dosvc >nul 2>&1

color %COLOR_SUCCESS%
echo ? Limpieza de caché de Windows Update intentada.
echo La carpeta SoftwareDistribution ha sido recreada.
echo Se recomienda reiniciar el equipo para asegurar que todos los servicios relacionados funcionen correctamente.
pause
goto menu_mantenimiento
===================================================================================================================================
:menu_red
cls
color %COLOR_TITLE%
echo ==========================================================
echo               RED Y CONEXIONES
echo ==========================================================
color %COLOR_MENU%
echo 1. Ver configuración de red
echo 2. Renovar dirección IP
echo 3. Ver aplicaciones usando puerto 443
echo 4. Limpiar caché DNS
echo 5. Restablecer TCP/IP
echo 6. Adaptadores de redes
echo 7. Volver al menu principal
echo ==========================================================
choice /C 1234567 /N /M "Seleccione una opción [1-7]: "

if errorlevel 7 goto menu_principal
if errorlevel 6 goto adaptadores_red
if errorlevel 5 goto reset_tcpip
if errorlevel 4 goto flush_dns
if errorlevel 3 goto ver_puerto443
if errorlevel 2 goto renovar_ip
if errorlevel 1 goto ver_config

:reset_tcpip
cls
color %COLOR_TITLE%
echo ==========================================================
echo          RESTABLECER CONFIGURACIÓN DE TCP/IP
echo ==========================================================
color %COLOR_PROCESSING%
echo Restableciendo configuración de TCP/IP...
netsh int ip reset
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo restablecer la configuración de TCP/IP.
) else (
    color %COLOR_SUCCESS%
    echo ? Configuración de TCP/IP restablecida correctamente.
)
pause
goto menu_red

:ver_config
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CONFIGURACIÓN DE RED ACTUAL
echo ==========================================================
color %COLOR_INFO%
ipconfig /all
pause
goto menu_red

:renovar_ip
cls
color %COLOR_TITLE%
echo ==========================================================
echo          RENOVACIÓN DE DIRECCIÓN IP
echo ==========================================================
color %COLOR_PROCESSING%
echo Liberando y renovando dirección IP...
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo renovar la dirección IP
) else (
    color %COLOR_SUCCESS%
    echo ? Dirección IP renovada correctamente
)
pause
goto menu_red

:ver_puerto443
cls
color %COLOR_TITLE%
echo ==========================================================
echo      APLICACIONES USANDO EL PUERTO 443
echo ==========================================================
color %COLOR_PROCESSING%
netstat -ano | findstr :443
pause
goto menu_red

:flush_dns
cls
color %COLOR_TITLE%
echo ==========================================================
echo            LIMPIEZA DE CACHÉ DNS
echo ==========================================================
color %COLOR_PROCESSING%
echo Limpiando la caché de DNS...
ipconfig /flushdns
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo Error: No se pudo limpiar la caché DNS
) else (
    color %COLOR_SUCCESS%
    echo Caché DNS limpiada correctamente
)
pause
goto menu_red

:adaptadores_red
cls
color %COLOR_TITLE%
echo ================================================
echo     INFORMACIÓN DETALLADA DE ADAPTADORES DE RED
echo ================================================
color %COLOR_PROCESSING%
echo Obteniendo informacion detallada de los adaptadores de red...
echo Este proceso puede tardar unos segundos...

:: Crear archivo PowerShell temporal con la funcion
echo function Get-NetworkAdaptersDetailed { > "%temp%\netadapters.ps1"
echo     # Obtener informacion de los adaptadores de red >> "%temp%\netadapters.ps1"
echo     $adapters = Get-NetAdapter ^| Sort-Object -Property Name >> "%temp%\netadapters.ps1"
echo. >> "%temp%\netadapters.ps1"
echo     foreach ($adapter in $adapters) { >> "%temp%\netadapters.ps1"
echo         # Detalles basicos >> "%temp%\netadapters.ps1"
echo         $macAddress = $adapter.MacAddress -replace '(..(?!$))', '$1-' >> "%temp%\netadapters.ps1"
echo         $status = if ($adapter.Status -eq 'Up') { "Conectado" } else { "Desconectado" } >> "%temp%\netadapters.ps1"
echo         $interfaceType = if ($adapter.InterfaceDescription -like "*Hyper-V*") { "Virtual (Hyper-V)" } >> "%temp%\netadapters.ps1"
echo                          elseif ($adapter.InterfaceDescription -like "*Virtual*") { "Virtual" } >> "%temp%\netadapters.ps1"
echo                          else { "Físico" } >> "%temp%\netadapters.ps1"
echo. >> "%temp%\netadapters.ps1"
echo         # Información de IP (IPv4) >> "%temp%\netadapters.ps1"
echo         $ipInfo = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue >> "%temp%\netadapters.ps1"
echo         $ipAddress = if ($ipInfo) { $ipInfo.IPAddress } else { "No asignada" } >> "%temp%\netadapters.ps1"
echo. >> "%temp%\netadapters.ps1"
echo         # Mostrar informacion en formato claro >> "%temp%\netadapters.ps1"
echo         Write-Host "=== $($adapter.Name) ($($adapter.InterfaceDescription)) ===" -ForegroundColor Cyan >> "%temp%\netadapters.ps1"
echo         Write-Host "| Tipo          : $interfaceType" >> "%temp%\netadapters.ps1"
echo         Write-Host "| Estado        : $status" >> "%temp%\netadapters.ps1"
echo         Write-Host "| Dirección MAC : $macAddress" >> "%temp%\netadapters.ps1"
echo         Write-Host "| IPv4          : $ipAddress" >> "%temp%\netadapters.ps1"
echo         Write-Host "| Velocidad     : $($adapter.LinkSpeed)" >> "%temp%\netadapters.ps1"
echo         Write-Host "| Conectado a   : $(if ($adapter.Status -eq 'Up') { 'Red activa' } else { 'Sin conexion' })" >> "%temp%\netadapters.ps1"
echo         Write-Host "`n" >> "%temp%\netadapters.ps1"
echo     } >> "%temp%\netadapters.ps1"
echo. >> "%temp%\netadapters.ps1"
echo     # Información adicional (como Hyper-V si está presente) >> "%temp%\netadapters.ps1"
echo     $hypervAdapter = $adapters ^| Where-Object { $_.InterfaceDescription -like "*Hyper-V*" } >> "%temp%\netadapters.ps1"
echo     if ($hypervAdapter) { >> "%temp%\netadapters.ps1"
echo         Write-Host "*** Nota sobre Hyper-V ***" -ForegroundColor Yellow >> "%temp%\netadapters.ps1"
echo         Write-Host "El adaptador '$($hypervAdapter.Name)' es virtual y se usa para máquinas virtuales o contenedores." >> "%temp%\netadapters.ps1"
echo         Write-Host "Puedes ignorarlo si no usas virtualizacion.`n" >> "%temp%\netadapters.ps1"
echo     } >> "%temp%\netadapters.ps1"
echo } >> "%temp%\netadapters.ps1"
echo. >> "%temp%\netadapters.ps1"
echo # Ejecutar la función >> "%temp%\netadapters.ps1"
echo Get-NetworkAdaptersDetailed >> "%temp%\netadapters.ps1"

:: Ejecutar el script PowerShell
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%temp%\netadapters.ps1"

:: Limpiar
del "%temp%\netadapters.ps1" >nul 2>&1

color %COLOR_INFO%
echo.
echo Presione cualquier tecla para volver al menú...
pause >nul
goto menu_red

===================================================================================================================================
:menu_seguridad
cls
color %COLOR_TITLE%
echo ==========================================================
echo            SEGURIDAD Y FIREWALL
echo ==========================================================
color %COLOR_MENU%
echo 1. Activar Firewall
echo 2. Desactivar Firewall
echo 3. Mostrar estado del Firewall
echo 4. Volver al menu principal
echo ==========================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto firewall_status
if errorlevel 2 goto firewall_disable
if errorlevel 1 goto firewall_enable

:firewall_enable
cls
color %COLOR_TITLE%
echo ==========================================================
echo            ACTIVACIÓN DE FIREWALL
echo ==========================================================
color %COLOR_PROCESSING%
echo Activando todas las reglas del firewall...

netsh advfirewall set allprofiles state on
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo activar el firewall
) else (
    color %COLOR_SUCCESS%
    echo ? Firewall activado correctamente
    echo Su sistema ahora está protegido contra conexiones no autorizadas
)
pause
goto menu_seguridad

:firewall_disable
cls
color %COLOR_TITLE%
echo ==========================================================
echo           DESACTIVACIÓN DE FIREWALL
echo ==========================================================
color %COLOR_WARNING%
echo ADVERTENCIA: Desactivar el firewall puede reducir la seguridad del sistema.
echo Solo realice esta acción si es absolutamente necesario.
echo.
set /p "confirm=¿Está seguro que desea continuar? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_seguridad
)

color %COLOR_PROCESSING%
echo Desactivando reglas del firewall...

netsh advfirewall set allprofiles state off
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo desactivar el firewall
) else (
    color %COLOR_WARNING%
    echo ? Firewall desactivado correctamente
    echo IMPORTANTE: Recuerde volver a activarlo cuando termine sus tareas
)
pause
goto menu_seguridad

:firewall_status
cls
color %COLOR_TITLE%
echo ==========================================================
echo            ESTADO DEL FIREWALL
echo ==========================================================
color %COLOR_INFO%
echo Obteniendo información de perfiles de firewall...
echo.
netsh advfirewall show allprofiles
pause
goto menu_seguridad

===================================================================================================================================
:menu_info
cls
color %COLOR_TITLE%
echo ==========================================================
echo          INFORMACIÓN DEL SISTEMA
echo ==========================================================
color %COLOR_MENU%
echo 1. Información de hardware (incluye versión de Windows y disco duro)
echo 2. Programas instalados
echo 3. Servicios en ejecución
echo 4. Volver al menu principal
echo ==========================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "
if errorlevel 4 goto menu_principal
if errorlevel 3 goto servicios
if errorlevel 2 goto programas
if errorlevel 1 goto hardware

:hardware
cls
color %COLOR_TITLE%
echo ==========================================================
echo          INFORMACIÓN DE HARDWARE
echo ==========================================================
color %COLOR_INFO%
echo Recopilando información del sistema...
echo.
systeminfo | findstr /C:"Nombre de host" /C:"OS Name" /C:"Fabricante del sistema" /C:"Modelo del sistema" /C:"Tipo de sistema" /C:"Procesador" /C:"Versión de BIOS" /C:"Memoria física total"
echo.
echo Mostrando versión exacta de Windows...
winver
echo.
echo Información del disco duro:
wmic diskdrive get model,serialnumber,size
echo.
wmic cpu get Name, NumberOfCores, NumberOfLogicalProcessors
echo.
wmic memorychip get Capacity, Speed, DeviceLocator
pause
goto menu_info

::: REEMPLAZO DE WMIC EN "PROGRAMAS INSTALADOS" (MENÚ INFORMACIÓN)  
:programas  
cls  
color %COLOR_TITLE%  
echo ==========================================================
echo          PROGRAMAS INSTALADOS - OPTIMIZADO  
echo ==========================================================
color %COLOR_INFO%  
echo Listando programas instalados (via PowerShell)...  
echo.  
powershell -NoProfile -Command "Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' | Select-Object DisplayName, DisplayVersion | Sort-Object DisplayName | Format-Table -AutoSize"  
pause  
goto menu_info  

:servicios
cls
color %COLOR_TITLE%
echo ==========================================================
echo          SERVICIOS EN EJECUCIÓN
echo ==========================================================
color %COLOR_INFO%
echo Mostrando servicios activos...
echo.
net start
pause
goto menu_info

cls
color %COLOR_TITLE%
echo ==========================================================
echo       PROCESOS Y SERVICIOS DE CHROME
echo ==========================================================
color %COLOR_INFO%
echo Obteniendo procesos y servicios asociados a chrome.exe...
echo.
tasklist /svc | find "chrome.exe"
pause
goto menu_info
===================================================================================================================================
:menu_apagado
cls
color %COLOR_TITLE%
echo ==========================================================
echo          OPCIONES DE APAGADO/REINICIO
echo ==========================================================
color %COLOR_MENU%
echo 1. Apagar el sistema
echo 2. Reiniciar el sistema
echo 3. Cerrar sesión
echo 4. Bloquear pantalla
echo 5. Volver al menu principal
echo ==========================================================
choice /C 12345 /N /M "Seleccione una opción [1-5]: "

if errorlevel 5 goto menu_principal
if errorlevel 4 goto bloquear
if errorlevel 3 goto cerrar_sesion
if errorlevel 2 goto reiniciar
if errorlevel 1 goto apagar

:apagar
cls
color %COLOR_WARNING%
echo ¿Está seguro que desea apagar el sistema?
echo.
set /p "confirm=Confirmar (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_apagado
)
color %COLOR_PROCESSING%
echo Apagando el sistema...
shutdown /s /t 5 /c "Apagado iniciado desde Herramienta Avanzada"
exit

:reiniciar
cls
color %COLOR_WARNING%
echo ¿Está seguro que desea reiniciar el sistema?
echo.
set /p "confirm=Confirmar (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_apagado
)
color %COLOR_PROCESSING%
echo Reiniciando el sistema...
shutdown /r /t 5 /c "Reinicio iniciado desde Herramienta Avanzada"
exit

:cerrar_sesion
cls
color %COLOR_WARNING%
echo ¿Está seguro que desea cerrar la sesión?
echo.
set /p "confirm=Confirmar (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_apagado
)
color %COLOR_PROCESSING%
echo Cerrando sesión...
shutdown /l
exit

:bloquear
cls
color %COLOR_PROCESSING%
echo Bloqueando el sistema...
rundll32.exe user32.dll,LockWorkStation
goto menu_apagado

===================================================================================================================================
:menu_usb
cls
color %COLOR_TITLE%
echo ==========================================================
echo      ADMINISTRACIÓN DE DISPOSITIVOS USB
echo ==========================================================
color %COLOR_MENU%
echo 1. Desconectar dispositivo USB (quitar letra)
echo 2. Montar dispositivo USB (asignar letra)
echo 3. Volver al menu principal
echo ==========================================================
choice /C 123 /N /M "Seleccione una opción [1-3]: "

if errorlevel 3 goto menu_principal
if errorlevel 2 goto mount_usb
if errorlevel 1 goto unmount_usb

:: Desconexión de dispositivos USB
:unmount_usb
cls
color %COLOR_TITLE%
echo ==========================================================
echo     DESCONEXIÓN DE DISPOSITIVOS USB
echo ==========================================================
color %COLOR_INFO%
echo Listando dispositivos USB conectados...
echo.

:: Listar volúmenes removibles con PowerShell
powershell -NoProfile -Command "Get-Volume | Where-Object { $_.DriveType -eq 'Removable' } | Format-Table -AutoSize DriveLetter, FileSystemLabel, SizeRemaining, Size"

:: Verificar si hay dispositivos USB conectados con letra asignada
set "usbDetected=0"
for /f "skip=1 tokens=1" %%i in ('wmic logicaldisk where "drivetype=2" get DeviceID 2^>nul') do (
    set "usbDetected=1"
)
if "%usbDetected%"=="0" (
    color %COLOR_WARNING%
    echo No se detectaron dispositivos USB con letra asignada.
    echo Si ve un dispositivo sin letra, use la opción 2 del menú anterior.
    pause
    goto menu_usb
)

:: Solicitar al usuario la letra del dispositivo a desmontar
echo.
set /p "usbDrive=Ingrese la letra de la unidad a expulsar (ejemplo E): "
set "usbDrive=%usbDrive:~0,1%"

:: Validar que la unidad exista entre las removibles
powershell -NoProfile -Command "if (-not (Get-Volume -DriveLetter '%usbDrive%' -ErrorAction SilentlyContinue)) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    color %COLOR_ERROR%
    echo ? Error: La unidad %usbDrive%: no se encontró o no es un dispositivo extraíble.
    pause
    goto menu_usb
)

:: Confirmar la acción de desmontaje
echo.
color %COLOR_WARNING%
set /p "confirm=¿Está seguro de que desea desmontar la unidad %usbDrive%? (S/N): "
if /I not "%confirm%"=="S" (
    color %COLOR_INFO%
    echo Operación cancelada.
    pause
    goto menu_usb
)

:: Desmontar la unidad: quitar la letra de acceso con PowerShell
color %COLOR_PROCESSING%
echo Desmontando la unidad %usbDrive%:...
powershell -NoProfile -Command "& { Remove-PartitionAccessPath -DriveLetter '%usbDrive%' }"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo desmontar la unidad %usbDrive%.
    pause
    goto menu_usb
) else (
    color %COLOR_SUCCESS%
    echo ? La unidad %usbDrive%: fue desmontada correctamente.
    echo Puede retirar el dispositivo de forma segura.
)
pause
goto menu_usb

:: Montar dispositivo USB
:mount_usb
cls
color %COLOR_TITLE%
echo ==========================================================
echo     MONTAR/ASIGNAR LETRA A DISPOSITIVO USB
echo ==========================================================
color %COLOR_INFO%
echo Listando TODOS los dispositivos USB...
echo.

:: Mostrar todos los discos USB y sus particiones
powershell -NoProfile -Command "$disks = Get-Disk | Where-Object { $_.BusType -eq 'USB' }; foreach ($disk in $disks) { Write-Host ('Disco ' + $disk.Number + ': ' + $disk.FriendlyName + ' (' + [math]::Round($disk.Size/1GB,2) + ' GB)'); Get-Partition -DiskNumber $disk.Number | Format-Table -Property DiskNumber, PartitionNumber, DriveLetter, Size, Type }"

echo.
set /p "diskNum=Ingrese el número de disco (DiskNumber): "
set /p "partNum=Ingrese el número de partición (PartitionNumber): "
set /p "driveLetter=Ingrese la letra a asignar: "
set "driveLetter=%driveLetter:~0,1%"

:: Validar que la letra de unidad no esté en uso
powershell -NoProfile -Command "if (Get-Volume -DriveLetter '%driveLetter%' -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    color %COLOR_ERROR%
    echo Error: La letra de unidad %driveLetter% ya está en uso.
    pause
    goto menu_usb
)

color %COLOR_PROCESSING%
echo Asignando letra %driveLetter%: al dispositivo...
powershell -NoProfile -Command "$part = Get-Partition -DiskNumber %diskNum% -PartitionNumber %partNum%; if ($part) { Add-PartitionAccessPath -InputObject $part -AccessPath '%driveLetter%:' }"

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo asignar la letra al dispositivo.
    echo Posibles causas:
    echo - La letra ya está en uso
    echo - El dispositivo no está listo
    echo - Permisos insuficientes
) else (
    color %COLOR_SUCCESS%
    echo ? Letra %driveLetter%: asignada correctamente al dispositivo
)
pause
goto menu_usb
===================================================================================================================================
:menu_configuracion
cls
color %COLOR_TITLE%
echo ================================================
echo          CONFIGURACIÓN DEL EQUIPO
echo ================================================
color %COLOR_MENU%
echo 1. Ver información actual del equipo
echo 2. Cambiar nombre del equipo
echo 3. Cambiar grupo de trabajo
echo 4. Cambiar descripción del equipo
echo 5. Volver al menu principal
echo ================================================
choice /C 12345 /N /M "Seleccione una opción [1-5]: "

if errorlevel 5 goto menu_principal
if errorlevel 4 goto cambiar_descripcion
if errorlevel 3 goto cambiar_grupo
if errorlevel 2 goto cambiar_nombre
if errorlevel 1 goto ver_info_equipo

:ver_info_equipo
cls
color %COLOR_TITLE%
echo ================================================
echo          INFORMACIÓN ACTUAL DEL EQUIPO
echo ================================================
color %COLOR_INFO%
echo Recopilando información del equipo...
echo.
echo Nombre del equipo:
hostname
echo.
echo Grupo de trabajo:
wmic computersystem get workgroup
echo.
echo Descripción del equipo:
reg query "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v srvcomment 2>nul
if %errorlevel% NEQ 0 (
    echo [No se ha establecido una descripción]
)
pause
goto menu_configuracion

:cambiar_nombre
cls
color %COLOR_TITLE%
echo ================================================
echo          CAMBIAR NOMBRE DEL EQUIPO
echo ================================================
color %COLOR_INFO%
echo Nombre actual del equipo:
hostname
echo.
set /p "nuevo_nombre=Ingrese el nuevo nombre del equipo: "

color %COLOR_WARNING%
echo.
echo ADVERTENCIA: Cambiar el nombre del equipo requiere un reinicio.
echo.
set /p "confirm=¿Está seguro que desea continuar? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_configuracion
)

color %COLOR_PROCESSING%
echo Cambiando nombre del equipo...
wmic computersystem where name="%computername%" call rename name="%nuevo_nombre%" >nul

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar el nombre del equipo.
) else (
    color %COLOR_SUCCESS%
    echo ? Nombre del equipo cambiado correctamente a "%nuevo_nombre%"
    echo Es necesario reiniciar el equipo para aplicar los cambios.
    echo.
    set /p "reiniciar=¿Desea reiniciar ahora? (S/N): "
    if /I "%reiniciar%"=="S" (
        shutdown /r /t 10 /c "Reinicio necesario para aplicar el nuevo nombre de equipo"
        echo El equipo se reiniciará en 10 segundos...
        timeout /t 5
        exit
    )
)
pause
goto menu_configuracion

:cambiar_grupo
cls
color %COLOR_TITLE%
echo ================================================
echo          CAMBIAR GRUPO DE TRABAJO
echo ================================================
color %COLOR_INFO%
echo Grupo de trabajo actual:
wmic computersystem get workgroup
echo.
set /p "nuevo_grupo=Ingrese el nuevo grupo de trabajo: "

color %COLOR_WARNING%
echo.
echo ADVERTENCIA: Cambiar el grupo de trabajo requiere un reinicio.
echo.
set /p "confirm=¿Está seguro que desea continuar? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_configuracion
)

color %COLOR_PROCESSING%
echo Cambiando grupo de trabajo...
wmic computersystem where name="%computername%" call joindomainorworkgroup name="%nuevo_grupo%" >nul

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar el grupo de trabajo.
) else (
    color %COLOR_SUCCESS%
    echo ? Grupo de trabajo cambiado correctamente a "%nuevo_grupo%"
    echo Es necesario reiniciar el equipo para aplicar los cambios.
    echo.
    set /p "reiniciar=¿Desea reiniciar ahora? (S/N): "
    if /I "%reiniciar%"=="S" (
        shutdown /r /t 10 /c "Reinicio necesario para aplicar el nuevo grupo de trabajo"
        echo El equipo se reiniciará en 10 segundos...
        timeout /t 5
        exit
    )
)
pause
goto menu_configuracion

:cambiar_descripcion
cls
color %COLOR_TITLE%
echo ================================================
echo          CAMBIAR DESCRIPCIÓN DEL EQUIPO
echo ================================================
color %COLOR_INFO%
echo Descripción actual del equipo:
reg query "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v srvcomment 2>nul
if %errorlevel% NEQ 0 (
    echo [No se ha establecido una descripción]
)
echo.
set /p "nueva_descripcion=Ingrese la nueva descripción del equipo: "

color %COLOR_PROCESSING%
echo Cambiando descripción del equipo...
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v srvcomment /t REG_SZ /d "%nueva_descripcion%" /f >nul

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar la descripción del equipo.
) else (
    color %COLOR_SUCCESS%
    echo ? Descripción del equipo cambiada correctamente a "%nueva_descripcion%"
    echo No es necesario reiniciar para aplicar este cambio.
)
pause
goto menu_configuracion

:menu_usuarios
cls
color %COLOR_TITLE%
echo ==========================================================
echo      ADMINISTRACIÓN DE CUENTAS DE USUARIO
echo ==========================================================
color %COLOR_MENU%
echo 1. Listar usuarios del sistema
echo 2. Crear nueva cuenta de usuario
echo 3. Modificar cuenta de usuario existente
echo 4. Eliminar cuenta de usuario
echo 5. Administrar permisos de usuario
echo 6. Gestionar contraseñas
echo 7. Cambiar contraseña de usuario actual
echo 8. Volver al menú principal
echo ==========================================================
choice /C 12345678 /N /M "Seleccione una opción [1-8]: "

if errorlevel 8 goto menu_principal
if errorlevel 7 goto change_own_password
if errorlevel 6 goto menu_passwords
if errorlevel 5 goto menu_permisos
if errorlevel 4 goto eliminar_usuario
if errorlevel 3 goto modificar_usuario
if errorlevel 2 goto crear_usuario
if errorlevel 1 goto listar_usuarios

:change_own_password
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CAMBIAR CONTRASEÑA DE USUARIO ACTUAL
echo ==========================================================
color %COLOR_INFO%
echo Por favor, ingrese su contraseña actual y la nueva contraseña.
set /p "currentPass=Contraseña actual: "
set /p "newPass=Nueva contraseña: "
set /p "confirmPass=Confirmar nueva contraseña: "

if not "%newPass%"=="%confirmPass%" (
    color %COLOR_ERROR%
    echo ? Error: Las contraseñas no coinciden.
    pause
    goto menu_usuarios
)

:: Aquí usamos el comando 'net' para cambiar la contraseña
net user "%USERNAME%" "%newPass%" /logonpasswordchg:yes
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar la contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? Contraseña cambiada correctamente.
)
pause
goto menu_usuarios

:listar_usuarios
cls
color %COLOR_TITLE%
echo ==========================================================
echo            USUARIOS DEL SISTEMA
echo ==========================================================
color %COLOR_INFO%
echo Obteniendo lista de usuarios locales...
echo.
net user
echo.
echo Para ver detalles de un usuario específico:
echo.
set /p "username=Ingrese nombre de usuario (o presione ENTER para volver): "
if not "%username%"=="" (
    net user "%username%"
    echo.
    pause
    goto listar_usuarios
)
goto menu_usuarios

:crear_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CREAR NUEVA CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Por favor, complete la siguiente información:
echo.
set /p "newUser=Nombre de usuario: "
if "%newUser%"=="" (
    color %COLOR_ERROR%
    echo Nombre de usuario no puede estar vacío.
    pause
    goto menu_usuarios
)

set /p "newPass=Contraseña: "
echo.
set /p "isAdmin=¿Desea que este usuario sea administrador? (S/N): "

color %COLOR_PROCESSING%
echo Creando usuario %newUser%...
net user "%newUser%" "%newPass%" /add

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo crear el usuario.
    pause
    goto menu_usuarios
)

if /I "%isAdmin%"=="S" (
    echo Agregando usuario al grupo de Administradores...
    net localgroup Administradores "%newUser%" /add
    if %errorlevel% NEQ 0 (
        color %COLOR_ERROR%
        echo ? Error: No se pudo agregar el usuario al grupo de Administradores.
    ) else (
        color %COLOR_SUCCESS%
        echo Usuario %newUser% creado y agregado al grupo de Administradores.
    )
) else (
    color %COLOR_SUCCESS%
    echo Usuario %newUser% creado exitosamente.
)
pause
goto menu_usuarios

:modificar_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo         MODIFICAR CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "modUser=Nombre de usuario a modificar: "
if "%modUser%"=="" (
    goto menu_usuarios
)

echo.
echo Opciones de modificación:
echo 1. Cambiar nombre completo
echo 2. Activar/Desactivar cuenta
echo 3. Forzar cambio de contraseña en siguiente inicio
echo 4. Cambiar fecha de caducidad de contraseña
echo 5. Volver
echo.
choice /C 12345 /N /M "Seleccione opción: "

if errorlevel 5 goto menu_usuarios
if errorlevel 4 goto mod_expiry
if errorlevel 3 goto mod_force_change
if errorlevel 2 goto mod_activate
if errorlevel 1 goto mod_fullname

:mod_fullname
cls
set /p "fullname=Nuevo nombre completo: "
net user "%modUser%" /fullname:"%fullname%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al modificar el nombre completo.
) else (
    color %COLOR_SUCCESS%
    echo ? Nombre completo actualizado correctamente.
)
pause
goto modificar_usuario

:mod_activate
cls
echo Estado actual:
net user "%modUser%" | findstr /C:"Cuenta activa"
echo.
set /p "active=¿Activar cuenta? (S/N): "
if /I "%active%"=="S" (
    net user "%modUser%" /active:yes
    set "msg=activada"
) else (
    net user "%modUser%" /active:no
    set "msg=desactivada"
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al cambiar el estado de la cuenta.
) else (
    color %COLOR_SUCCESS%
    echo ? Cuenta %msg% correctamente.
)
pause
goto modificar_usuario

:mod_force_change
cls
set /p "force=¿Forzar cambio de contraseña al iniciar sesión? (S/N): "
if /I "%force%"=="S" (
    net user "%modUser%" /logonpasswordchg:yes
    set "msg=obligado a cambiar"
) else (
    net user "%modUser%" /logonpasswordchg:no
    set "msg=no necesitará cambiar"
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al configurar cambio de contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? El usuario %modUser% %msg% su contraseña en el próximo inicio de sesión.
)
pause
goto modificar_usuario

:mod_expiry
cls
echo Opciones:
echo 1. Nunca caduca
echo 2. Establecer fecha de caducidad
echo.
choice /C 12 /N /M "Seleccione opción: "

if errorlevel 2 (
    set /p "expiry=Ingrese fecha (DD/MM/AAAA): "
    net user "%modUser%" /expires:"%expiry%"
) else (
    net user "%modUser%" /expires:never
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al configurar la fecha de caducidad.
) else (
    color %COLOR_SUCCESS%
    echo ? Fecha de caducidad configurada correctamente.
)
pause
goto modificar_usuario

:eliminar_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo         ELIMINAR CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "delUser=Nombre de usuario a eliminar: "
if "%delUser%"=="" (
    goto menu_usuarios
)

echo.
color %COLOR_WARNING%
echo ¡ADVERTENCIA! Esta acción eliminará permanentemente la cuenta de usuario y
echo todos sus datos asociados. Esta acción no se puede deshacer.
echo.
set /p "confirm=¿Está seguro que desea eliminar '%delUser%'? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_usuarios
)

color %COLOR_PROCESSING%
echo Eliminando usuario %delUser%...
net user "%delUser%" /delete

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo eliminar el usuario.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %delUser% eliminado correctamente.
)
pause
goto menu_usuarios

:menu_permisos
cls
color %COLOR_TITLE%
echo ==========================================================
echo        ADMINISTRAR PERMISOS DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Grupos disponibles en el sistema:
net localgroup
echo.
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "permUser=Nombre de usuario para modificar permisos: "
if "%permUser%"=="" (
    goto menu_usuarios
)

cls
color %COLOR_TITLE%
echo ==========================================================
echo    PERMISOS DE USUARIO PARA: %permUser%
echo ==========================================================
color %COLOR_INFO%
echo Grupos a los que pertenece el usuario:
net user "%permUser%" | findstr /C:"Miembro de grupo local"
echo.
echo.
echo ===================== INFORMACIÓN DE PERMISOS =====================
echo Los permisos en Windows se manejan mediante grupos de seguridad:
echo.
echo Administradores: Acceso completo y control del sistema
echo Usuarios: Permisos limitados, pueden usar aplicaciones instaladas
echo Usuarios avanzados: Permisos elevados sin acceso completo
echo Operadores de copia: Pueden realizar copias de seguridad
echo Invitados: Acceso muy restringido al sistema
echo.
echo =================================================================
echo.
echo Opciones:
echo 1. Agregar usuario a un grupo
echo 2. Quitar usuario de un grupo
echo 3. Volver
echo.
choice /C 123 /N /M "Seleccione opción: "

if errorlevel 3 goto menu_usuarios
if errorlevel 2 goto quitar_grupo
if errorlevel 1 goto agregar_grupo

:agregar_grupo
cls
set /p "addGroup=Nombre del grupo al que agregar al usuario: "
if "%addGroup%"=="" (
    goto menu_permisos
)

net localgroup "%addGroup%" "%permUser%" /add
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo agregar el usuario al grupo.
    echo Verifique que el grupo exista y que el usuario no sea ya miembro.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %permUser% agregado al grupo %addGroup% correctamente.
)
pause
goto menu_permisos

:quitar_grupo
cls
set /p "remGroup=Nombre del grupo del que quitar al usuario: "
if "%remGroup%"=="" (
    goto menu_permisos
)

net localgroup "%remGroup%" "%permUser%" /delete
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo quitar el usuario del grupo.
    echo Verifique que el grupo exista y que el usuario sea miembro.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %permUser% quitado del grupo %remGroup% correctamente.
)
pause
goto menu_permisos

:menu_passwords
cls
color %COLOR_TITLE%
echo ==========================================================
echo           GESTIÓN DE CONTRASEÑAS
echo ==========================================================
color %COLOR_INFO%
echo 1. Resetear contraseña de usuario
echo 2. Ver contraseñas almacenadas (requiere privilegios)
echo 3. Volver
echo.
choice /C 123 /N /M "Seleccione opción: "

if errorlevel 3 goto menu_usuarios
if errorlevel 2 goto ver_passwords
if errorlevel 1 goto reset_password

:reset_password
cls
color %COLOR_TITLE%
echo ==========================================================
echo        RESETEAR CONTRASEÑA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "resetUser=Nombre de usuario para resetear contraseña: "
if "%resetUser%"=="" (
    goto menu_passwords
)

set /p "newPass=Nueva contraseña: "
echo.
color %COLOR_PROCESSING%
echo Cambiando contraseña para %resetUser%...

net user "%resetUser%" "%newPass%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar la contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? Contraseña cambiada correctamente para %resetUser%.
)
pause
goto menu_passwords

:ver_passwords
cls
color %COLOR_TITLE%
echo ==========================================================
echo        VER CONTRASEÑAS ALMACENADAS
echo ==========================================================
color %COLOR_WARNING%
echo AVISO IMPORTANTE: Esta función permite visualizar las contraseñas
echo almacenadas en el administrador de credenciales de Windows.
echo.
echo Este proceso requiere privilegios de administrador elevados
echo y solo mostrará contraseñas guardadas en texto claro,
echo no puede recuperar contraseñas cifradas de cuentas locales.
echo.
echo Mostrando credenciales almacenadas en el sistema...
echo.

color %COLOR_PROCESSING%
echo Recuperando información de credenciales...
powershell -Command "cmdkey /list | Out-Host"

echo.
echo Para contraseñas de usuarios locales:
echo Las contraseñas de cuentas locales no son recuperables directamente,
echo pero puede resetearlas usando la opción 1 de este menú.
echo.
pause
goto menu_passwords

:limpiar_windows_update
cls
color %COLOR_TITLE%
echo ==========================================================
echo         LIMPIEZA DE WINDOWS UPDATE
echo ==========================================================
color %COLOR_PROCESSING%
echo Deteniendo servicios relacionados con Windows Update...
net stop wuauserv >nul 2>&1
net stop UsoSvc >nul 2>&1
net stop bits >nul 2>&1
net stop dosvc >nul 2>&1

echo Eliminando carpeta SoftwareDistribution...
rd /s /q C:\Windows\SoftwareDistribution >nul 2>&1

echo Creando nueva carpeta SoftwareDistribution...
md C:\Windows\SoftwareDistribution >nul 2>&1

color %COLOR_SUCCESS%
echo ? PC Limpia con carpeta SoftwareDistribution renovada
echo Los servicios de Windows Update volverán a iniciarse en el próximo reinicio.
pause
goto menu_mantenimiento
===================================================================================================================================
:menu_usuarios
cls
color %COLOR_TITLE%
echo ==========================================================
echo      ADMINISTRACIÓN DE CUENTAS DE USUARIO
echo ==========================================================
color %COLOR_MENU%
echo 1. Listar usuarios del sistema
echo 2. Crear nueva cuenta de usuario
echo 3. Modificar cuenta de usuario existente
echo 4. Eliminar cuenta de usuario
echo 5. Administrar permisos de usuario
echo 6. Gestionar contraseñas
echo 7. Cambiar contraseña de usuario actual
echo 8. Volver al menú principal
echo ==========================================================
choice /C 12345678 /N /M "Seleccione una opción [1-8]: "

if errorlevel 8 goto menu_principal
if errorlevel 7 goto change_own_password
if errorlevel 6 goto menu_passwords
if errorlevel 5 goto menu_permisos
if errorlevel 4 goto eliminar_usuario
if errorlevel 3 goto modificar_usuario
if errorlevel 2 goto crear_usuario
if errorlevel 1 goto listar_usuarios

:change_own_password
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CAMBIAR CONTRASEÑA DE USUARIO ACTUAL
echo ==========================================================
color %COLOR_INFO%
echo Por favor, ingrese su contraseña actual y la nueva contraseña.
set /p "currentPass=Contraseña actual: "
set /p "newPass=Nueva contraseña: "
set /p "confirmPass=Confirmar nueva contraseña: "

if not "%newPass%"=="%confirmPass%" (
    color %COLOR_ERROR%
    echo ? Error: Las contraseñas no coinciden.
    pause
    goto menu_usuarios
)

:: Aquí usamos el comando 'net' para cambiar la contraseña
net user "%USERNAME%" "%newPass%" /logonpasswordchg:yes
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar la contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? Contraseña cambiada correctamente.
)
pause
goto menu_usuarios

/* INICIO MEJORA [LISTAR_USUARIOS_DETALLADO] */
:listar_usuarios
cls
color %COLOR_TITLE%
echo ==========================================================
echo            USUARIOS DEL SISTEMA
echo ==========================================================
color %COLOR_INFO%
echo Obteniendo lista de usuarios locales...
echo.
net user
echo.
echo Para ver detalles de un usuario específico:
echo.
set /p "username=Ingrese nombre de usuario (o presione ENTER para volver): "
if not "%username%"=="" (
    echo.
    echo Detalles del usuario %username%:
    echo ==========================================================
    net user "%username%"
    echo.
    echo Grupos a los que pertenece:
    echo ----------------------------------------------------------
    net user "%username%" | findstr /C:"Miembro de grupo local"
    echo.
    pause
    goto listar_usuarios
)
/* FIN MEJORA [LISTAR_USUARIOS_DETALLADO] */
goto menu_usuarios

:crear_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CREAR NUEVA CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Por favor, complete la siguiente información:
echo.
set /p "newUser=Nombre de usuario: "
if "%newUser%"=="" (
    color %COLOR_ERROR%
    echo Nombre de usuario no puede estar vacío.
    pause
    goto menu_usuarios
)

set /p "newPass=Contraseña: "
if "%newPass%"=="" (
    color %COLOR_ERROR%
    echo Error: La contraseña no puede estar vacía.
    pause
    goto crear_usuario
)

set /p "confirmPass=Confirme la contraseña: "
if not "%newPass%"=="%confirmPass%" (
    color %COLOR_ERROR%
    echo Error: Las contraseñas no coinciden.
    pause
    goto crear_usuario
)

echo.
set /p "isAdmin=¿Desea que este usuario sea administrador? (S/N): "

color %COLOR_PROCESSING%
echo Creando usuario %newUser%...
net user "%newUser%" "%newPass%" /add

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo crear el usuario.
    pause
    goto menu_usuarios
)

if /I "%isAdmin%"=="S" (
    echo Agregando usuario al grupo de Administradores...
    net localgroup Administradores "%newUser%" /add
    if %errorlevel% NEQ 0 (
        color %COLOR_ERROR%
        echo ? Error: No se pudo agregar el usuario al grupo de Administradores.
    ) else (
        color %COLOR_SUCCESS%
        echo Usuario %newUser% creado y agregado al grupo de Administradores.
    )
) else (
    color %COLOR_SUCCESS%
    echo Usuario %newUser% creado exitosamente.
)
pause
goto menu_usuarios

:modificar_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo         MODIFICAR CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "modUser=Nombre de usuario a modificar: "
if "%modUser%"=="" (
    goto menu_usuarios
)

echo.
echo Opciones de modificación:
echo 1. Cambiar nombre completo
echo 2. Activar/Desactivar cuenta
echo 3. Forzar cambio de contraseña en siguiente inicio
echo 4. Cambiar fecha de caducidad de contraseña
echo 5. Cambiar descripción del usuario
echo 6. Cambiar ruta del perfil
echo 7. Volver
echo.
choice /C 1234567 /N /M "Seleccione opción: "

if errorlevel 7 goto menu_usuarios
if errorlevel 6 goto mod_profile_path
if errorlevel 5 goto mod_description
if errorlevel 4 goto mod_expiry
if errorlevel 3 goto mod_force_change
if errorlevel 2 goto mod_activate
if errorlevel 1 goto mod_fullname

:mod_description
cls
set /p "description=Nueva descripción del usuario: "
net user "%modUser%" /comment:"%description%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al modificar la descripción.
) else (
    color %COLOR_SUCCESS%
    echo ? Descripción actualizada correctamente.
)
pause
goto modificar_usuario

:mod_profile_path
cls
set /p "profilePath=Nueva ruta del perfil (ej. C:\Users\NuevoPerfil): "
wmic useraccount where "Name='%modUser%'" set LocalAccount=True, ProfilePath="%profilePath%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al modificar la ruta del perfil.
    echo Nota: Este cambio solo afectará a nuevos inicios de sesión.
) else (
    color %COLOR_SUCCESS%
    echo ? Ruta del perfil actualizada correctamente.
    echo Nota: Este cambio solo afectará a nuevos inicios de sesión.
)
pause
goto modificar_usuario
/* FIN MEJORA [OPCIONES_MODIFICACION_USUARIO] */

:mod_fullname
cls
set /p "fullname=Nuevo nombre completo: "
net user "%modUser%" /fullname:"%fullname%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al modificar el nombre completo.
) else (
    color %COLOR_SUCCESS%
    echo ? Nombre completo actualizado correctamente.
)
pause
goto modificar_usuario

:mod_activate
cls
echo Estado actual:
net user "%modUser%" | findstr /C:"Cuenta activa"
echo.
set /p "active=¿Activar cuenta? (S/N): "
if /I "%active%"=="S" (
    net user "%modUser%" /active:yes
    set "msg=activada"
) else (
    net user "%modUser%" /active:no
    set "msg=desactivada"
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al cambiar el estado de la cuenta.
) else (
    color %COLOR_SUCCESS%
    echo ? Cuenta %msg% correctamente.
)
pause
goto modificar_usuario

:mod_force_change
cls
set /p "force=¿Forzar cambio de contraseña al iniciar sesión? (S/N): "
if /I "%force%"=="S" (
    net user "%modUser%" /logonpasswordchg:yes
    set "msg=obligado a cambiar"
) else (
    net user "%modUser%" /logonpasswordchg:no
    set "msg=no necesitará cambiar"
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al configurar cambio de contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? El usuario %modUser% %msg% su contraseña en el próximo inicio de sesión.
)
pause
goto modificar_usuario

:mod_expiry
cls
echo Opciones:
echo 1. Nunca caduca
echo 2. Establecer fecha de caducidad
echo.
choice /C 12 /N /M "Seleccione opción: "

if errorlevel 2 (
    set /p "expiry=Ingrese fecha (DD/MM/AAAA): "
    net user "%modUser%" /expires:"%expiry%"
) else (
    net user "%modUser%" /expires:never
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error al configurar la fecha de caducidad.
) else (
    color %COLOR_SUCCESS%
    echo ? Fecha de caducidad configurada correctamente.
)
pause
goto modificar_usuario

/* INICIO MEJORA [ELIMINAR_USUARIO_SEGURO] */
:eliminar_usuario
cls
color %COLOR_TITLE%
echo ==========================================================
echo         ELIMINAR CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "delUser=Nombre de usuario a eliminar: "
if "%delUser%"=="" (
    goto menu_usuarios
)

:: Verificar si es el usuario actual
echo Verificando si es el usuario actualmente conectado...
for /f "tokens=*" %%u in ('whoami') do set currentUser=%%u
for /f "tokens=2 delims=\\" %%u in ("%currentUser%") do set currentUser=%%u

if /I "%currentUser%"=="%delUser%" (
    color %COLOR_ERROR%
    echo ? Error: No puede eliminar el usuario con el que está conectado actualmente.
    echo Inicie sesión con otra cuenta de administrador para realizar esta acción.
    pause
    goto menu_usuarios
)

echo.
color %COLOR_WARNING%
echo ¡ADVERTENCIA! Esta acción eliminará permanentemente la cuenta de usuario y
echo todos sus datos asociados. Esta acción no se puede deshacer.
echo.
set /p "confirm=¿Está seguro que desea eliminar '%delUser%'? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_usuarios
)

set /p "keepFiles=¿Desea conservar los archivos del perfil? (S/N): "

color %COLOR_PROCESSING%
echo Eliminando usuario %delUser%...

if /I "%keepFiles%"=="S" (
    net user "%delUser%" /delete /keepfiles
) else (
    net user "%delUser%" /delete
)

if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo eliminar el usuario.
    echo Es posible que este usuario tenga sesiones activas. Cierre todas las sesiones e intente nuevamente.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %delUser% eliminado correctamente.
    if /I "%keepFiles%"=="S" (
        echo Los archivos del perfil se han conservado.
    ) else (
        echo Los archivos del perfil han sido eliminados.
    )
)
/* FIN MEJORA [ELIMINAR_USUARIO_SEGURO] */
pause
goto menu_usuarios

:menu_permisos
cls
color %COLOR_TITLE%
echo ==========================================================
echo        ADMINISTRAR PERMISOS DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Grupos disponibles en el sistema:
net localgroup
echo.
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "permUser=Nombre de usuario para modificar permisos: "
if "%permUser%"=="" (
    goto menu_usuarios
)

cls
color %COLOR_TITLE%
echo ==========================================================
echo    PERMISOS DE USUARIO PARA: %permUser%
echo ==========================================================
color %COLOR_INFO%
echo Grupos a los que pertenece el usuario:
net user "%permUser%" | findstr /C:"Miembro de grupo local"
echo.
echo.
echo ===================== INFORMACIÓN DE PERMISOS =====================
echo Los permisos en Windows se manejan mediante grupos de seguridad:
echo.
echo Administradores: Acceso completo y control del sistema
echo Usuarios: Permisos limitados, pueden usar aplicaciones instaladas
echo Usuarios avanzados: Permisos elevados sin acceso completo
echo Operadores de copia: Pueden realizar copias de seguridad
echo Invitados: Acceso muy restringido al sistema
echo.
echo =================================================================
echo.
echo Opciones:
echo 1. Agregar usuario a un grupo
echo 2. Quitar usuario de un grupo
echo 3. Volver
echo.
choice /C 123 /N /M "Seleccione opción: "

if errorlevel 3 goto menu_usuarios
if errorlevel 2 goto quitar_grupo
if errorlevel 1 goto agregar_grupo

:agregar_grupo
cls
echo Grupos disponibles:
net localgroup | findstr /V "Alias" | findstr /V "---" | findstr /V "completó"
echo.
set /p "addGroup=Nombre del grupo al que agregar al usuario: "
if "%addGroup%"=="" (
    goto menu_permisos
)

:: Verificar si el usuario ya es miembro del grupo
net localgroup "%addGroup%" | find /i "%permUser%" > nul
if %errorlevel% EQU 0 (
    color %COLOR_WARNING%
    echo El usuario %permUser% ya es miembro del grupo %addGroup%.
    pause
    goto menu_permisos
)

net localgroup "%addGroup%" "%permUser%" /add
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo agregar el usuario al grupo.
    echo Verifique que el grupo exista y que el usuario no sea ya miembro.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %permUser% agregado al grupo %addGroup% correctamente.
    echo.
    echo Lista actualizada de grupos a los que pertenece el usuario:
    net user "%permUser%" | findstr /C:"Miembro de grupo local"
)
pause
goto menu_permisos

:quitar_grupo
cls
echo Grupos a los que pertenece el usuario:
echo.
for /f "tokens=*" %%a in ('net user "%permUser%" ^| findstr /C:"Miembro de grupo local"') do (
    echo %%a
)
echo.
set /p "remGroup=Nombre del grupo del que quitar al usuario: "
if "%remGroup%"=="" (
    goto menu_permisos
)

:: Verificar si el usuario es miembro del grupo
net localgroup "%remGroup%" | find /i "%permUser%" > nul
if %errorlevel% NEQ 0 (
    color %COLOR_WARNING%
    echo El usuario %permUser% no es miembro del grupo %remGroup%.
    pause
    goto menu_permisos
)

:: Advertencia si se intenta quitar del grupo Usuarios
if /I "%remGroup%"=="Usuarios" (
    color %COLOR_WARNING%
    echo ADVERTENCIA: Quitar un usuario del grupo Usuarios puede causar problemas.
    echo El usuario podría perder acceso a funciones básicas del sistema.
    set /p "confirmRem=¿Está seguro que desea continuar? (S/N): "
    if /I not "%confirmRem%"=="S" (
        goto menu_permisos
    )
)

net localgroup "%remGroup%" "%permUser%" /delete
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo quitar el usuario del grupo.
    echo Verifique que el grupo exista y que el usuario sea miembro.
) else (
    color %COLOR_SUCCESS%
    echo ? Usuario %permUser% quitado del grupo %remGroup% correctamente.
    echo.
    echo Lista actualizada de grupos a los que pertenece el usuario:
    net user "%permUser%" | findstr /C:"Miembro de grupo local"
)
/* FIN MEJORA [GESTION_GRUPOS_MEJORADA] */
pause
goto menu_permisos

/* INICIO MEJORA [GESTION_PASSWORD_AVANZADA] */
:menu_passwords
cls
color %COLOR_TITLE%
echo ==========================================================
echo           GESTIÓN DE CONTRASEÑAS
echo ==========================================================
color %COLOR_INFO%
echo 1. Resetear contraseña de usuario
echo 2. Establecer política de contraseñas
echo 3. Ver contraseñas almacenadas (requiere privilegios)
echo 4. Desbloquear cuenta de usuario
echo 5. Volver
echo.
choice /C 12345 /N /M "Seleccione opción: "

if errorlevel 5 goto menu_usuarios
if errorlevel 4 goto desbloquear_cuenta
if errorlevel 3 goto ver_passwords
if errorlevel 2 goto politica_passwords
if errorlevel 1 goto reset_password

:desbloquear_cuenta
cls
color %COLOR_TITLE%
echo ==========================================================
echo        DESBLOQUEAR CUENTA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "unlockUser=Nombre de usuario a desbloquear: "
if "%unlockUser%"=="" (
    goto menu_passwords
)

echo Verificando estado de bloqueo...
net user "%unlockUser%" | find "Cuenta bloqueada" > nul
if %errorlevel% NEQ 0 (
    color %COLOR_INFO%
    echo La cuenta del usuario %unlockUser% no está bloqueada.
    pause
    goto menu_passwords
)

color %COLOR_PROCESSING%
echo Desbloqueando cuenta de %unlockUser%...
net user "%unlockUser%" /active:yes
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo desbloquear la cuenta.
) else (
    color %COLOR_SUCCESS%
    echo ? Cuenta desbloqueada correctamente para %unlockUser%.
)
pause
goto menu_passwords

:politica_passwords
cls
color %COLOR_TITLE%
echo ==========================================================
echo     CONFIGURAR POLÍTICA DE CONTRASEÑAS (LOCAL)
echo ==========================================================
color %COLOR_INFO%
echo Esta función ajusta las políticas de contraseña para TODOS los usuarios.
echo.
echo Opciones:
echo 1. Establecer longitud mínima de contraseña
echo 2. Establecer edad máxima de contraseña (días)
echo 3. Establecer historial de contraseñas
echo 4. Volver
echo.
choice /C 1234 /N /M "Seleccione opción: "

if errorlevel 4 goto menu_passwords
if errorlevel 3 goto password_history
if errorlevel 2 goto password_age
if errorlevel 1 goto password_length

:password_length
cls
set /p "minLength=Longitud mínima de contraseña (0-14): "
net accounts /minpwlen:%minLength%
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo establecer la longitud mínima.
) else (
    color %COLOR_SUCCESS%
    echo ? Longitud mínima de contraseña establecida a %minLength% caracteres.
)
pause
goto politica_passwords

:password_age
cls
set /p "maxAge=Edad máxima de contraseña en días (0=nunca caduca): "
net accounts /maxpwage:%maxAge%
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo establecer la edad máxima.
) else (
    color %COLOR_SUCCESS%
    echo ? Edad máxima de contraseña establecida a %maxAge% días.
)
pause
goto politica_passwords

:password_history
cls
set /p "history=Número de contraseñas para recordar (0-24): "
net accounts /uniquepw:%history%
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo establecer el historial.
) else (
    color %COLOR_SUCCESS%
    echo ? Historial de contraseñas establecido a %history%.
)
pause
goto politica_passwords

:reset_password
cls
color %COLOR_TITLE%
echo ==========================================================
echo        RESETEAR CONTRASEÑA DE USUARIO
echo ==========================================================
color %COLOR_INFO%
echo Usuarios disponibles:
net user | findstr /V "Comando correcto" | findstr /V "---" | findstr /V "Cuentas"
echo.
set /p "resetUser=Nombre de usuario para resetear contraseña: "
if "%resetUser%"=="" (
    goto menu_passwords
)

set /p "newPass=Nueva contraseña: "
echo.
color %COLOR_PROCESSING%
echo Cambiando contraseña para %resetUser%...

net user "%resetUser%" "%newPass%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo cambiar la contraseña.
) else (
    color %COLOR_SUCCESS%
    echo ? Contraseña cambiada correctamente para %resetUser%.
)
pause
goto menu_passwords

:ver_passwords
cls
color %COLOR_TITLE%
echo ==========================================================
echo        VER CONTRASEÑAS ALMACENADAS
echo ==========================================================
color %COLOR_WARNING%
echo AVISO IMPORTANTE: Esta función permite visualizar las contraseñas
echo almacenadas en el administrador de credenciales de Windows.
echo.
echo Este proceso requiere privilegios de administrador elevados
echo y solo mostrará contraseñas guardadas en texto claro,
echo no puede recuperar contraseñas cifradas de cuentas locales.
echo.
echo Mostrando credenciales almacenadas en el sistema...
echo.

color %COLOR_PROCESSING%
echo Recuperando información de credenciales...
powershell -Command "cmdkey /list | Out-Host"

echo.
echo Para contraseñas de usuarios locales:
echo Las contraseñas de cuentas locales no son recuperables directamente,
echo pero puede resetearlas usando la opción 1 de este menú.
echo.
pause
goto menu_passwords

===================================================================================================================================
:menu_archivos_ocultos
cls
color %COLOR_TITLE%
echo ================================================
echo           GESTIÓN DE ARCHIVOS OCULTOS
echo ================================================
color %COLOR_MENU%
echo 1. Mostrar/Ocultar elementos ocultos
echo 2. Ocultar archivos protegidos del sistema
echo 3. Mostrar archivos protegidos del sistema
echo 4. Volver al menu principal
echo ================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto mostrar_protegidos
if errorlevel 2 goto ocultar_protegidos
if errorlevel 1 goto toggle_ocultos

:toggle_ocultos
cls
color %COLOR_PROCESSING%
echo Alternando la visibilidad de archivos ocultos...
:: Obtener el estado actual
for /f "tokens=3" %%h in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden ^| findstr "Hidden"') do set current=%%h

if "%current%"=="0x0" (
    :: Si está en 0, cambiarlo a 1 (mostrar)
    echo Activando la visualización de archivos ocultos...
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
) else (
    :: Si está en 1, cambiarlo a 0 (ocultar)
    echo Desactivando la visualización de archivos ocultos...
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 0 /f
)

:: Reiniciar el Explorador para aplicar los cambios
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

color %COLOR_SUCCESS%
echo Cambios aplicados correctamente.
pause
goto menu_archivos_ocultos

:ocultar_protegidos
cls
color %COLOR_PROCESSING%
echo Ocultando archivos protegidos del sistema...
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowSuperHidden /T REG_DWORD /D 0 /F
:: Reiniciar el Explorador para aplicar los cambios
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

color %COLOR_SUCCESS%
echo Archivos protegidos del sistema ocultos.
pause
goto menu_archivos_ocultos

:mostrar_protegidos
cls
color %COLOR_PROCESSING%
echo Mostrando archivos protegidos del sistema...
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V Hidden /T REG_DWORD /D 1 /F
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowSuperHidden /T REG_DWORD /D 1 /F
:: Reiniciar el Explorador para aplicar los cambios
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

color %COLOR_SUCCESS%
echo Archivos protegidos del sistema visibles.
pause
goto menu_archivos_ocultos

===================================================================================================================================

:menu_servicios
cls
color %COLOR_TITLE%
echo ==========================================================
echo          ADMINISTRACIÓN DE SERVICIOS
echo ==========================================================
color %COLOR_MENU%
echo 1. Listar servicios en ejecución
echo 2. Iniciar servicio
echo 3. Detener servicio
echo 4. Reiniciar servicio
echo 5. Volver al menú principal
echo ==========================================================
choice /C 12345 /N /M "Seleccione una opción [1-5]: "

if errorlevel 5 goto menu_principal
if errorlevel 4 goto restart_service
if errorlevel 3 goto stop_service
if errorlevel 2 goto start_service
if errorlevel 1 goto list_services

:list_services
cls
color %COLOR_TITLE%
echo ==========================================================
echo          SERVICIOS EN EJECUCIÓN
echo ==========================================================
color %COLOR_INFO%
net start
pause
goto menu_servicios

:start_service
cls
color %COLOR_TITLE%
echo ==========================================================
echo          INICIAR SERVICIO
echo ==========================================================
color %COLOR_INFO%
set /p "serviceName=Ingrese el nombre del servicio a iniciar: "
net start "%serviceName%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo iniciar el servicio.
) else (
    color %COLOR_SUCCESS%
    echo ? Servicio iniciado correctamente.
)
pause
goto menu_servicios

:stop_service
cls
color %COLOR_TITLE%
echo ==========================================================
echo          DETENER SERVICIO
echo ==========================================================
color %COLOR_INFO%
set /p "serviceName=Ingrese el nombre del servicio a detener: "
net stop "%serviceName%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo detener el servicio.
) else (
    color %COLOR_SUCCESS%
    echo ? Servicio detenido correctamente.
)
pause
goto menu_servicios

===================================================================================================================================
:menu_backup_drivers
cls
color %COLOR_TITLE%
echo ==========================================================
echo          COPIA DE SEGURIDAD DE CONTROLADORES
echo ==========================================================
color %COLOR_MENU%
echo 1. Crear copia de seguridad de controladores
echo 2. Restaurar copia de seguridad de controladores
echo 3. Volver al menú principal
echo ==========================================================
choice /C 123 /N /M "Seleccione una opción [1-3]: "

if errorlevel 3 goto menu_principal
if errorlevel 2 goto menu_restore_drivers
if errorlevel 1 goto menu_create_backup

:: Submenú para Crear Copia de Seguridad
:menu_create_backup
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CREAR COPIA DE SEGURIDAD DE CONTROLADORES
echo ==========================================================
color %COLOR_MENU%
echo 1. Crear copia de seguridad de controladores en ruta predeterminada
echo 2. Crear copia de seguridad de controladores en ruta personalizada
echo 3. Crear copia de seguridad de controladores en disco USB
echo 4. Volver al menú anterior
echo ==========================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_backup_drivers
if errorlevel 3 goto backup_drivers_usb
if errorlevel 2 goto backup_drivers_custom
if errorlevel 1 goto backup_drivers_default

:: Función para crear copia de seguridad en ruta predeterminada
:backup_drivers_default
cls
color %COLOR_PROCESSING%
echo Iniciando copia de seguridad de controladores en ruta predeterminada...
echo.

:: Definir la carpeta de destino para la copia de seguridad
set "backupFolder=C:\BackupDrivers\%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
mkdir "%backupFolder%"

:: Copiar archivos de controladores de C:\Windows\System32\Drivers
echo Copiando archivos de controladores de C:\Windows\System32\Drivers...
xcopy "C:\Windows\System32\Drivers" "%backupFolder%\Drivers" /E /H /C /I /Y

:: Copiar archivos de DriverStore
echo Copiando archivos de DriverStore...
xcopy "C:\Windows\System32\DriverStore\FileRepository" "%backupFolder%\DriverStore" /E /H /C /I /Y

:: Copiar archivos .inf de C:\Windows\inf
echo Copiando archivos .inf de C:\Windows\inf...
xcopy "C:\Windows\inf" "%backupFolder%\inf" /E /H /C /I /Y

:: Exportar el registro de Windows
echo Exportando el registro de Windows...
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class" "%backupFolder%\DriversRegistry.reg"

:: Registrar la actividad
call :log_activity "Copia de seguridad de controladores completada en %backupFolder%"

color %COLOR_SUCCESS%
echo.
echo ? Copia de seguridad de controladores completada correctamente.
echo Archivos de controladores y registro guardados en: %backupFolder%
pause
goto menu_create_backup

:: Función para crear copia de seguridad en ruta personalizada
:backup_drivers_custom
cls
color %COLOR_PROCESSING%
echo Iniciando copia de seguridad de controladores en ruta personalizada...
echo.

:: Sugerir rutas personalizadas
echo Rutas sugeridas:
echo 1. Escritorio: %USERPROFILE%\Desktop
echo 2. Descargas: %USERPROFILE%\Downloads
echo 3. Videos: %USERPROFILE%\Videos
echo 4. Música: %USERPROFILE%\Music
echo 5. Imágenes: %USERPROFILE%\Pictures
echo 6. Objetos 3D: %USERPROFILE%\3D Objects
echo.

:: Solicitar la ruta personalizada al usuario
set /p "backupFolder=Ingrese la ruta de destino para la copia de seguridad (ej. %USERPROFILE%\Desktop\BackupDrivers): "
if not exist "%backupFolder%" (
    mkdir "%backupFolder%"
)

:: Verificar que la carpeta de destino exista
if not exist "%backupFolder%" (
    color %COLOR_ERROR%
    echo ? Error: La carpeta de destino no existe y no se pudo crear.
    pause
    goto menu_create_backup
)

:: Copiar archivos de controladores de C:\Windows\System32\Drivers
echo Copiando archivos de controladores de C:\Windows\System32\Drivers...
xcopy "C:\Windows\System32\Drivers" "%backupFolder%\Drivers" /E /H /C /I /Y

:: Copiar archivos de DriverStore
echo Copiando archivos de DriverStore...
xcopy "C:\Windows\System32\DriverStore\FileRepository" "%backupFolder%\DriverStore" /E /H /C /I /Y

:: Copiar archivos .inf de C:\Windows\inf
echo Copiando archivos .inf de C:\Windows\inf...
xcopy "C:\Windows\inf" "%backupFolder%\inf" /E /H /C /I /Y

:: Exportar el registro de Windows
echo Exportando el registro de Windows...
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class" "%backupFolder%\DriversRegistry.reg"

:: Registrar la actividad
call :log_activity "Copia de seguridad de controladores completada en %backupFolder%"

color %COLOR_SUCCESS%
echo.
echo ? Copia de seguridad de controladores completada correctamente.
echo Archivos de controladores y registro guardados en: %backupFolder%
pause
goto menu_create_backup

:: Función para crear copia de seguridad en disco USB
:backup_drivers_usb
cls
color %COLOR_PROCESSING%
echo Iniciando copia de seguridad de controladores en disco USB...
echo.

:: Listar dispositivos USB conectados
echo Listando dispositivos USB conectados...
powershell -NoProfile -Command "Get-Volume | Where-Object { $_.DriveType -eq 'Removable' } | Format-Table -AutoSize DriveLetter, FileSystemLabel, SizeRemaining, Size"

:: Solicitar la letra del dispositivo USB al usuario
set /p "usbDrive=Ingrese la letra de la unidad USB (ej. E): "
set "usbDrive=%usbDrive:~0,1%"

:: Verificar que la unidad USB exista
if not exist "%usbDrive%:\" (
    color %COLOR_ERROR%
    echo ? Error: La unidad %usbDrive%: no se encontró.
    pause
    goto menu_create_backup
)

:: Definir la carpeta de destino en el disco USB
set "backupFolder=%usbDrive%:\BackupDrivers\%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
mkdir "%backupFolder%"

:: Copiar archivos de controladores de C:\Windows\System32\Drivers
echo Copiando archivos de controladores de C:\Windows\System32\Drivers...
xcopy "C:\Windows\System32\Drivers" "%backupFolder%\Drivers" /E /H /C /I /Y

:: Copiar archivos de DriverStore
echo Copiando archivos de DriverStore...
xcopy "C:\Windows\System32\DriverStore\FileRepository" "%backupFolder%\DriverStore" /E /H /C /I /Y

:: Copiar archivos .inf de C:\Windows\inf
echo Copiando archivos .inf de C:\Windows\inf...
xcopy "C:\Windows\inf" "%backupFolder%\inf" /E /H /C /I /Y

:: Exportar el registro de Windows
echo Exportando el registro de Windows...
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class" "%backupFolder%\DriversRegistry.reg"

:: Registrar la actividad
call :log_activity "Copia de seguridad de controladores completada en %backupFolder%"

color %COLOR_SUCCESS%
echo.
echo ? Copia de seguridad de controladores completada correctamente.
echo Archivos de controladores y registro guardados en: %backupFolder%
pause
goto menu_create_backup

:: Submenú para Restaurar Copia de Seguridad
:menu_restore_drivers
cls
color %COLOR_TITLE%
echo ==========================================================
echo          RESTAURACIÓN DE COPIAS DE SEGURIDAD
echo ==========================================================
color %COLOR_MENU%
echo 1. Restaurar controladores en el mismo equipo
echo 2. Restaurar controladores en un equipo diferente
echo 3. Volver al menú anterior
echo ==========================================================
choice /C 123 /N /M "Seleccione una opción [1-3]: "

if errorlevel 3 goto menu_backup_drivers
if errorlevel 2 goto restore_drivers_different
if errorlevel 1 goto restore_drivers_same

:: Función para restaurar controladores en el mismo equipo
:restore_drivers_same
cls
color %COLOR_PROCESSING%
echo Iniciando restauración de controladores en el mismo equipo...
echo.

:: Solicitar la ruta de la carpeta de copia de seguridad
set /p "backupFolder=Ingrese la ruta de la carpeta de copia de seguridad: "
if not exist "%backupFolder%" (
    color %COLOR_ERROR%
    echo ? Error: La carpeta de copia de seguridad no existe.
    pause
    goto menu_restore_drivers
)

:: Restaurar archivos de controladores de C:\Windows\System32\Drivers
echo Restaurando archivos de controladores de C:\Windows\System32\Drivers...
xcopy "%backupFolder%\Drivers" "C:\Windows\System32\Drivers" /E /H /C /I /Y

:: Restaurar archivos de DriverStore
echo Restaurando archivos de DriverStore...
xcopy "%backupFolder%\DriverStore" "C:\Windows\System32\DriverStore\FileRepository" /E /H /C /I /Y

:: Restaurar archivos .inf de C:\Windows\inf
echo Restaurando archivos .inf de C:\Windows\inf...
xcopy "%backupFolder%\inf" "C:\Windows\inf" /E /H /C /I /Y

:: Importar el registro de Windows
echo Importando el registro de Windows...
reg import "%backupFolder%\DriversRegistry.reg"

:: Registrar la actividad
call :log_activity "Restauración de controladores completada en el mismo equipo desde %backupFolder%"

color %COLOR_SUCCESS%
echo.
echo ? Restauración de controladores completada correctamente.
pause
goto menu_restore_drivers

:: Función para restaurar controladores en un equipo diferente
:restore_drivers_different
cls
color %COLOR_PROCESSING%
echo Iniciando restauración de controladores en un equipo diferente...
echo.

:: Solicitar la ruta de la carpeta de copia de seguridad
set /p "backupFolder=Ingrese la ruta de la carpeta de copia de seguridad: "
if not exist "%backupFolder%" (
    color %COLOR_ERROR%
    echo ? Error: La carpeta de copia de seguridad no existe.
    pause
    goto menu_restore_drivers
)

:: Submenú para verificar la compatibilidad
echo ==========================================================
echo          VERIFICACIÓN DE COMPATIBILIDAD
echo ==========================================================
echo 1. Verificar compatibilidad de controladores
echo 2. Restaurar sin verificar compatibilidad
echo 3. Volver al menú anterior
echo ==========================================================
choice /C 123 /N /M "Seleccione una opción [1-3]: "

if errorlevel 3 goto menu_restore_drivers
if errorlevel 2 goto restore_drivers_different_nocheck
if errorlevel 1 goto check_compatibility

:check_compatibility
cls
color %COLOR_PROCESSING%
echo Verificando compatibilidad de controladores...
echo.

:: Verificar la versión del sistema operativo
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "osVersion=%%i.%%j"
echo Versión del sistema operativo actual: %osVersion%

:: Verificar el hardware compatible
echo Verificando hardware compatible...
:: Aquí puedes agregar comandos adicionales para verificar el hardware

:: Verificar la versión de los controladores
echo Verificando versión de los controladores...
:: Aquí puedes agregar comandos adicionales para verificar las versiones de los controladores

echo.
set /p "confirm=¿Desea continuar con la restauración? (S/N): "
if /I not "%confirm%"=="S" (
    goto menu_restore_drivers
)

goto restore_drivers_different_nocheck

:restore_drivers_different_nocheck
cls
color %COLOR_PROCESSING%
echo Restaurando controladores sin verificar compatibilidad...
echo.

:: Restaurar archivos de controladores de C:\Windows\System32\Drivers
echo Restaurando archivos de controladores de C:\Windows\System32\Drivers...
xcopy "%backupFolder%\Drivers" "C:\Windows\System32\Drivers" /E /H /C /I /Y

:: Restaurar archivos de DriverStore
echo Restaurando archivos de DriverStore...
xcopy "%backupFolder%\DriverStore" "C:\Windows\System32\DriverStore\FileRepository" /E /H /C /I /Y

:: Restaurar archivos .inf de C:\Windows\inf
echo Restaurando archivos .inf de C:\Windows\inf...
xcopy "%backupFolder%\inf" "C:\Windows\inf" /E /H /C /I /Y

:: Registrar la actividad
call :log_activity "Restauración de controladores completada en un equipo diferente desde %backupFolder% sin verificar compatibilidad"

color %COLOR_SUCCESS%
echo.
echo ? Restauración de controladores completada correctamente.
pause
goto menu_restore_drivers

:: Función de Registro de Actividades
:log_activity
echo %date% %time% - %1 >> "%~dp0activity_log.txt"

===================================================================================================================================
:menu_permisos_eliminar
cls
color %COLOR_TITLE%
echo ==========================================================
echo    ADMINISTRADOR DE PERMISOS Y ELIMINACIÓN DE CARPETAS
echo ==========================================================
color %COLOR_MENU%
echo 1. Tomar posesión de una carpeta (takeown)
echo 2. Otorgar control total a tu usuario (icacls)
echo 3. Eliminar una carpeta y su contenido (rmdir /s /q)
echo 4. Ejecutar todo el proceso (Tomar posesión, Otorgar control, Eliminar)
echo 5. Volver al menú principal
echo ==========================================================
set /p "opcion=Seleccione una opción [1-5]: "

if "%opcion%"=="5" goto menu_principal
if "%opcion%"=="4" goto full_process
if "%opcion%"=="3" goto delete_folder
if "%opcion%"=="2" goto grant_full_control
if "%opcion%"=="1" goto take_ownership

echo Opción no válida. Inténtalo de nuevo.
pause
goto menu_permisos_eliminar

:: Función para Tomar Posesión de una Carpeta
:take_ownership
cls
color %COLOR_PROCESSING%
echo.
set /p "ruta_takeown=Introduce la ruta completa de la carpeta para tomar posesión: "
takeown /f "%ruta_takeown%" /r
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo tomar posesión de la carpeta.
) else (
    color %COLOR_SUCCESS%
    echo ? Proceso de toma de posesión completado.
)
pause
goto menu_permisos_eliminar

:: Función para Otorgar Control Total
:grant_full_control
cls
color %COLOR_PROCESSING%
echo.
set /p "ruta_icacls=Introduce la ruta completa de la carpeta para otorgar control total: "
icacls "%ruta_icacls%" /grant %username%:F /t /c
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo otorgar control total.
) else (
    color %COLOR_SUCCESS%
    echo ? Proceso de otorgamiento de control total completado.
)
pause
goto menu_permisos_eliminar

:: Función para Eliminar una Carpeta
:delete_folder
cls
color %COLOR_PROCESSING%
echo.
set /p "ruta_rmdir=Introduce la ruta completa de la carpeta para eliminar: "
echo ¿Estás seguro de que quieres eliminar "%ruta_rmdir%" y todo su contenido? (Esto no se puede deshacer)
choice /c yn /m "Confirma (y/n): "
if errorlevel 2 (
    color %COLOR_WARNING%
    echo Operación cancelada.
    pause
    goto menu_permisos_eliminar
)
rmdir /s /q "%ruta_rmdir%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo eliminar la carpeta.
) else (
    color %COLOR_SUCCESS%
    echo ? Proceso de eliminación completado.
)
pause
goto menu_permisos_eliminar

:: Función para Ejecutar Todo el Proceso
:full_process
cls
color %COLOR_PROCESSING%
echo.
set /p "ruta_full=Introduce la ruta completa de la carpeta para el proceso completo: "
echo Ejecutando el proceso completo para "%ruta_full%":
echo - Tomando posesión...
takeown /f "%ruta_full%" /r
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo tomar posesión de la carpeta.
    pause
    goto menu_permisos_eliminar
)
echo - Otorgando control total...
icacls "%ruta_full%" /grant %username%:F /t /c
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo otorgar control total.
    pause
    goto menu_permisos_eliminar
)
echo - Eliminando la carpeta...
echo ¿Estás seguro de que quieres eliminar "%ruta_full%" y todo su contenido? (Esto no se puede deshacer)
choice /c yn /m "Confirma (y/n): "
if errorlevel 2 (
    color %COLOR_WARNING%
    echo Operación cancelada.
    pause
    goto menu_permisos_eliminar
)
rmdir /s /q "%ruta_full%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo eliminar la carpeta.
) else (
    color %COLOR_SUCCESS%
    echo ? Proceso completo completado.
)
pause
goto menu_permisos_eliminar

===================================================================================================================================
:menu_compartidas
cls
color %COLOR_TITLE%
echo ==========================================================
echo          ADMINISTRACIÓN DE CARPETAS COMPARTIDAS
echo ==========================================================
color %COLOR_MENU%
echo 1. Listar carpetas compartidas
echo 2. Compartir una carpeta
echo 3. Eliminar una carpeta compartida
echo 4. Volver al menú principal
echo ==========================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto delete_share
if errorlevel 2 goto create_share
if errorlevel 1 goto list_shares

:list_shares
cls
color %COLOR_TITLE%
echo ==========================================================
echo          CARPETAS COMPARTIDAS
echo ==========================================================
color %COLOR_INFO%
net share
pause
goto menu_compartidas

:create_share
cls
color %COLOR_TITLE%
echo ==========================================================
echo          COMPARTIR UNA CARPETA
echo ==========================================================
color %COLOR_INFO%
set /p "sharePath=Ingrese la ruta de la carpeta a compartir: "
set /p "shareName=Ingrese el nombre de la carpeta compartida: "
net share "%shareName%"="%sharePath%"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo compartir la carpeta.
) else (
    color %COLOR_SUCCESS%
    echo ? Carpeta compartida correctamente.
)
pause
goto menu_compartidas

:delete_share
cls
color %COLOR_TITLE%
echo ==========================================================
echo          ELIMINAR UNA CARPETA COMPARTIDA
echo ==========================================================
color %COLOR_INFO%
set /p "shareName=Ingrese el nombre de la carpeta compartida a eliminar: "
net share "%shareName%" /delete
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo eliminar la carpeta compartida.
) else (
    color %COLOR_SUCCESS%
    echo ? Carpeta compartida eliminada correctamente.
)
pause
goto menu_compartidas

===================================================================================================================================

:menu_aplicaciones_inicio
cls
color %COLOR_TITLE%
echo ==========================================================
echo          ADMINISTRAR APLICACIONES DE INICIO
echo ==========================================================
color %COLOR_MENU%
echo 1. Ver aplicaciones de inicio
echo 2. Habilitar aplicación de inicio
echo 3. Inhabilitar aplicación de inicio
echo 4. Volver al menú principal
echo ==========================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto inhabilitar_aplicacion
if errorlevel 2 goto habilitar_aplicacion
if errorlevel 1 goto ver_aplicaciones_inicio

:ver_aplicaciones_inicio
cls
color %COLOR_TITLE%
echo ==========================================================
echo          APLICACIONES DE INICIO
echo ==========================================================
color %COLOR_INFO%
echo Mostrando aplicaciones que se inician automáticamente...
powershell -Command "Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object *"
pause
goto menu_aplicaciones_inicio

:habilitar_aplicacion
cls
color %COLOR_TITLE%
echo ==========================================================
echo          HABILITAR APLICACIÓN DE INICIO
echo ==========================================================
color %COLOR_INFO%
echo Aplicaciones disponibles:
powershell -Command "Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object *"
echo.
set /p "appName=Ingrese el nombre de la aplicación a habilitar: "
powershell -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name '%appName%' -Value 'C:\Path\To\Application.exe'"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo habilitar la aplicación.
) else (
    color %COLOR_SUCCESS%
    echo ? Aplicación habilitada correctamente.
)
pause
goto menu_aplicaciones_inicio

:inhabilitar_aplicacion
cls
color %COLOR_TITLE%
echo ==========================================================
echo          INHABILITAR APLICACIÓN DE INICIO
echo ==========================================================
color %COLOR_INFO%
echo Aplicaciones disponibles:
powershell -Command "Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object *"
echo.
set /p "appName=Ingrese el nombre de la aplicación a inhabilitar: "
powershell -Command "Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name '%appName%'"
if %errorlevel% NEQ 0 (
    color %COLOR_ERROR%
    echo ? Error: No se pudo inhabilitar la aplicación.
) else (
    color %COLOR_SUCCESS%
    echo ? Aplicación inhabilitada correctamente.
)
pause
goto menu_aplicaciones_inicio

===================================================================================================================================
FINAL
===================================================================================================================================
cls
color %COLOR_INFO%
echo Saliendo de la herramienta...
echo Gracias por utilizar Herramienta Avanzada v4.8
timeout /t 2 >nul
exit