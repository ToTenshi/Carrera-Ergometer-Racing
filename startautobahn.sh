#!/bin/bash

function check_error {
    if [ $1 -ne 0 ]; then
        echo "Fehler: $2"
        if [ -n "$3" ] && [ -f "$3" ]; then
            echo "Letzte Zeilen von $3:"
            tail -n 10 "$3"
        fi
        exit 1
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_NAME="autobahnVenv"

# Pfad zu deiner virtuellen Umgebung
VENV_PATH="$SCRIPT_DIR/$VENV_NAME"

cd $VENV_PATH/autobahnDjango
check_error $? "Wechsel ins Django-Verzeichnis fehlgeschlagen."

echo "Aktiviere virtuelle Umgebung"
source "$VENV_PATH/bin/activate"
check_error $? "Aktivierung der virtuellen Umgebung fehlgeschlagen."

echo "start realtime script"
python manage.py run_counter > counter.log 2>&1 &
check_error $? "Starten des run_counter Skripts fehlgeschlagen." "counter.log"

echo "start Frontend"
daphne -b 0.0.0.0 -p 8000 autobahnDjango.asgi:application > daphne.log 2>&1 &
check_error $? "Starten von Daphne fehlgeschlagen." "daphne.log"

cd $VENV_PATH
check_error $? "Wechsel ins Backend-Verzeichnis fehlgeschlagen."

echo "start backend"
python3 backend.py > backend.log 2>&1 &
check_error $? "Starten von backend.py fehlgeschlagen." "backend.log"

echo "Alle Dienste wurden erfolgreich gestartet."

wait