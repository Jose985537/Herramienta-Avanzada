@echo off
chcp 65001 >nul
title Herramienta Avanzada v5.0 - NEXUS_CALDERON

:: Verificar permisos de administrador
>nul 2>&1 "%SYSTEMROOT%\system32\fltmc.exe"
if '%errorlevel%' NEQ '0' (
    color 0E
    echo No tiene permisos de administrador.
    echo Solicitando elevacion...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /b
)

:: Lanzar launcher.ps1
cls
echo ====================================================================
echo               HERRAMIENTA AVANZADA v5.0
echo               Iniciando modulo PowerShell...
echo ====================================================================
echo.
if not exist "%~dp0launcher.ps1" (
    color 0C
    echo [ERROR] No se encuentra el orquestador principal:
    echo         %~dp0launcher.ps1
    echo.
    echo Asegurese de que todos los archivos esten en su lugar.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher.ps1"

:: Si el usuario cierra launcher.ps1, volver aqui
color 0A
echo.
echo ====================================================================
echo         HERRAMIENTA AVANZADA v5.0 - SESION FINALIZADA
echo ====================================================================
echo.
timeout /t 3 >nul
exit /b 0
