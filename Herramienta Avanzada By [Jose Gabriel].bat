@echo off
chcp 65001 >nul
:: Verificar permisos de administrador
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo No tiene permisos de administrador.
    echo Solicitando elevación...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

color 0a
title Herramienta Avanzada v4.7 - By [Jose Gabriel]

:: Detectar versión de Windows
for /f "tokens=4-5 delims=[]. " %%i in ('ver') do set version=%%i.%%j
echo Versión de Windows detectada: %version%
timeout /t 2 >nul

:menu_principal
cls
echo ================================================
echo      HERRAMIENTA TECNICA AVANZADA - By [Jose Gabriel]
echo ================================================
echo 1. Mantenimiento del Sistema
echo 2. Red y Conexiones
echo 3. Seguridad y Firewall
echo 4. Información del Sistema
echo 5. Apagar/Reiniciar/Bloqueo Avanzado
echo 6. Desconectar dispositivos USB
echo 7. Salir
echo ================================================
choice /C 1234567 /N /M "Seleccione una opción [1-7]: "

if errorlevel 7 goto salir
if errorlevel 6 goto usb_disconnect
if errorlevel 5 goto menu_apagado
if errorlevel 4 goto menu_info
if errorlevel 3 goto menu_seguridad
if errorlevel 2 goto menu_red
if errorlevel 1 goto menu_mantenimiento

:: Mantenimiento del Sistema
:menu_mantenimiento
cls
echo ================================================
echo           MANTENIMIENTO DEL SISTEMA
echo ================================================
echo 1. Limpiar archivos temporales
echo 2. Reparar archivos del sistema (sfc)
echo 3. Optimizar unidades (Desfragmentar)
echo 4. Volver al menu principal
echo ================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto optimizar
if errorlevel 2 goto reparar
if errorlevel 1 goto limpiar

:limpiar
cls
echo Iniciando limpieza de archivos temporales...
cleanmgr /sagerun:1 >nul
if %errorlevel% NEQ 0 (
    echo Error: No se pudo completar la limpieza
) else (
    echo Limpieza completada exitosamente
)
pause
goto menu_mantenimiento

:reparar
cls
echo Reparando archivos del sistema...
sfc /scannow > "%temp%\sfc_log.txt"
if %errorlevel% NEQ 0 (
    echo Error: Reparación fallida (Código %errorlevel%)
    echo Revise el registro: %temp%\sfc_log.txt
) else (
    echo Reparación completada exitosamente
)
pause
goto menu_mantenimiento

:optimizar
cls
echo Optimizando unidad C:...
defrag C: /U /V > "%temp%\defrag_log.txt"
if %errorlevel% NEQ 0 (
    echo Error: Desfragmentación fallida (Código %errorlevel%)
    echo Revise el registro: %temp%\defrag_log.txt
) else (
    echo Optimización completada exitosamente
)
pause
goto menu_mantenimiento

:: Seguridad y Firewall
:menu_seguridad
cls
echo ================================================
echo            SEGURIDAD Y FIREWALL
echo ================================================
echo 1. Activar Firewall
echo 2. Desactivar Firewall
echo 3. Mostrar estado del Firewall
echo 4. Volver al menu principal
echo ================================================
choice /C 1234 /N /M "Seleccione una opción [1-4]: "

if errorlevel 4 goto menu_principal
if errorlevel 3 goto firewall_status
if errorlevel 2 goto firewall_disable
if errorlevel 1 goto firewall_enable

:firewall_enable
cls
netsh advfirewall set allprofiles state on
if %errorlevel% NEQ 0 (
    echo Error: No se pudo activar el firewall
) else (
    echo Firewall activado correctamente
)
pause
goto menu_seguridad

:firewall_disable
cls
netsh advfirewall set allprofiles state off
if %errorlevel% NEQ 0 (
    echo Error: No se pudo desactivar el firewall
) else (
    echo Firewall desactivado correctamente
)
pause
goto menu_seguridad

:firewall_status
cls
netsh advfirewall show allprofiles
pause
goto menu_seguridad

:: Expulsión USB Mejorada
:usb_disconnect
cls
echo ================================================
echo   DESCONEXIÓN DE DISPOSITIVOS USB
echo ================================================
echo Listando dispositivos USB...
wmic logicaldisk where "drivetype=2" get DeviceID, VolumeName 2>nul

echo.
set /p "usbDrive=Ingrese letra de unidad (ejemplo E): "
set "usbDrive=%usbDrive:~0,1%"

wmic logicaldisk where "DeviceID='%usbDrive%:'" get DeviceID >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Error: Unidad %usbDrive% no encontrada
    pause
    goto menu_principal
)

echo.
set /p "confirm=¿Expulsar unidad %usbDrive%? (S/N): "
if /I not "%confirm%"=="S" (
    echo Operación cancelada
    pause
    goto menu_principal
)

echo select volume %usbDrive% > %temp%\diskusb.txt
echo remove all dismount >> %temp%\diskusb.txt
diskpart /s %temp%\diskusb.txt >nul
del %temp%\diskusb.txt >nul

wmic logicaldisk where "DeviceID='%usbDrive%:'" get DeviceID >nul 2>&1
if %errorlevel% EQ 0 (
    echo Error: No se pudo expulsar la unidad
) else (
    echo Unidad %usbDrive% expulsada correctamente
)
pause
goto menu_principal

:: Resto del código (menús de info, apagado, etc.)...
:: ... (mantener igual que la versión original pero con corrección de caracteres)

:salir
cls
echo Saliendo de la herramienta...
timeout /t 2 >nul
exit