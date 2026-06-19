@echo off
REM ============================================================
REM  Avvio rapido — Gestione Istria (Windows)
REM  Apre l'app (index.html) nel browser predefinito.
REM  Tieni questo file nella STESSA cartella di index.html.
REM ============================================================
cd /d "%~dp0"
if not exist "index.html" (
    echo ERRORE: "index.html" non trovato in questa cartella.
    echo Metti questo file nella stessa cartella di index.html.
    pause
    exit /b 1
)
start "" "%~dp0index.html"
exit /b 0
