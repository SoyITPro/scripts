@echo off
title Modo Oscuro Windows 11
color 0A

:: Verificar administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Ejecuta como administrador
    echo Haz clic derecho y selecciona "Ejecutar como administrador"
    pause
    exit /b 1
)

cls
echo ========================================
echo   HABILITAR MODO OSCURO
echo ========================================
echo.

echo Aplicando cambios en el registro...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v AppMode /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v SearchBoxTaskbarMode /t REG_DWORD /d 1 /f >nul

echo Cambios aplicados correctamente
echo.

echo Reiniciando Explorador de Archivos...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe

echo.
echo ========================================
echo   MODO OSCURO HABILITADO
echo ========================================
echo.
pause