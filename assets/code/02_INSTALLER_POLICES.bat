@echo off
setlocal

REM ============================================================
REM Lanceur d'installation des polices
REM Windows 10 / Windows 11
REM ============================================================

set "SCRIPT=%~dp002_INSTALLER_POLICES.ps1"

echo.
echo ============================================================
echo          INSTALLATION INTELLIGENTE DES POLICES
echo ============================================================
echo.
echo Dossier :
echo %~dp0
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
echo ============================================================
echo                 OPERATION TERMINEE
echo ============================================================
echo.
pause