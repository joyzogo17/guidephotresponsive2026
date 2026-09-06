```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM 01_REMONTER_FICHIERS.bat
REM
REM Remonte UNIQUEMENT les fichiers de police vers le dossier
REM contenant ce fichier BAT.
REM
REM Les images, TXT, PDF, ZIP, etc. restent à leur emplacement.
REM ============================================================

set "BASE=%~dp0"

echo.
echo ============================================================
echo       REMONTEE DES POLICES
echo ============================================================
echo.
echo Dossier principal :
echo %BASE%
echo.

REM ------------------------------------------------------------
REM Recherche recursive de toutes les polices
REM ------------------------------------------------------------

for /r "%BASE%" %%F in (*.ttf *.otf *.ttc *.fon) do (

    REM Ne rien faire si le fichier est deja dans BASE
    if /I not "%%~dpF"=="%BASE%" (

        echo Police trouvee :
        echo    %%~nxF

        REM Si un fichier du meme nom existe deja dans BASE,
        REM on ne l'ecrase PAS.
        if exist "%BASE%%%~nxF" (

            echo    ATTENTION : fichier deja present.
            echo    Conservation du fichier original.
            echo.

        ) else (

            move "%%F" "%BASE%" >nul

            if errorlevel 1 (
                echo    ERREUR lors du déplacement.
            ) else (
                echo    OK - police remontee.
            )

            echo.
        )
    )
)

REM ------------------------------------------------------------
REM Suppression des dossiers devenus totalement vides
REM ------------------------------------------------------------

echo.
echo ============================================================
echo       NETTOYAGE DES DOSSIERS VIDES
echo ============================================================
echo.

for /f "delims=" %%D in ('dir "%BASE%" /ad /b /s ^| sort /R') do (

    rd "%%D" 2>nul

)

echo.
echo ============================================================
echo Operation terminee.
echo ============================================================
echo.
echo Les fichiers non-polices ont ete laisses en place.
echo Les polices ont ete remontees dans :
echo %BASE%
echo.
pause
```
