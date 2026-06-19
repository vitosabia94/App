#!/bin/bash
# ============================================================
#  Avvio rapido — Gestione Istria (macOS / Linux)
#  Apre l'app (index.html) nel browser predefinito.
#  Tieni questo file nella STESSA cartella di index.html.
#
#  Su macOS, al primo avvio: tasto destro sul file -> "Apri".
# ============================================================
cd "$(dirname "$0")" || exit 1
if [ ! -f "index.html" ]; then
    echo "ERRORE: index.html non trovato in questa cartella."
    read -r -p "Premi Invio per chiudere..."
    exit 1
fi
if command -v open >/dev/null 2>&1; then
    open "index.html"          # macOS
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "index.html"      # Linux
else
    echo "Apri manualmente index.html nel browser."
    read -r -p "Premi Invio per chiudere..."
fi
