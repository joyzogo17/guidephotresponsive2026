@echo off
REM =======================================================
REM Script : Remonter tous les fichiers depuis les sous-dossiers
REM Auteur : Joy & GPT-5
REM Objectif : Déplacer tous les fichiers de tous les sous-dossiers
REM             vers le dossier où se trouve ce script, puis
REM             supprimer les sous-dossiers vides.
REM =======================================================

setlocal enabledelayedexpansion
set "BASE=%~dp0"

echo =======================================================
echo Déplacement de tous les fichiers depuis :
echo %BASE%
echo =======================================================
echo.

REM Boucle pour déplacer tous les fichiers depuis les sous-dossiers
for /r "%BASE%" %%F in (*) do (
    if not "%%~dpF"=="%BASE%" (
        echo Déplacement de "%%~nxF"
        move /Y "%%F" "%BASE%" >nul
    )
)

echo.
echo =======================================================
echo Suppression des dossiers vides...
echo =======================================================
echo.

REM Supprime les dossiers vides du plus profond au plus proche
for /f "delims=" %%D in ('dir "%BASE%" /ad /b /s ^| sort /R') do (
    rd "%%D" 2>nul
)

echo.
echo =======================================================
echo ✅ Tous les fichiers ont été déplacés dans :
echo %BASE%
echo Les sous-dossiers vides ont été supprimés.
echo =======================================================
pause