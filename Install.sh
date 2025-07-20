#!/bin/bash

# Verzeichnis des Skripts bestimmen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VENV_NAME="venv"
DIR_TO_MOVE="$SCRIPT_DIR/dein_django_ordner"   # Ordner liegt im selben Verzeichnis wie das Skript

# Prüfen, ob Quellordner existiert
if [ ! -d "$DIR_TO_MOVE" ]; then
  echo "FEHLER: Der Ordner zum Verschieben existiert nicht: $DIR_TO_MOVE"
  exit 1
fi

echo "1. Virtuelle Umgebung \"$VENV_NAME\" wird erstellt..."
python3 -m venv "$VENV_NAME"

echo "2. Virtuelle Umgebung wird aktiviert..."
source "$VENV_NAME/bin/activate"

echo "3. Pip aktualisieren und Django, Redis und rpi-lgpio installieren..."
pip install --upgrade pip
pip install django redis rpi-lgpio

echo "4. Ordner wird in die virtuelle Umgebung verschoben..."

TARGET_DIR="$VENV_NAME/$(basename "$DIR_TO_MOVE")"

if [ -e "$TARGET_DIR" ]; then
  echo "Warnung: Zielordner $TARGET_DIR existiert bereits und wird überschrieben."
  rm -rf "$TARGET_DIR"
fi

mv "$DIR_TO_MOVE" "$TARGET_DIR"

echo "Fertig."
echo "Virtuelle Umgebung ist im Ordner \"$VENV_NAME\"."
echo "Der Ordner \"$(basename "$DIR_TO_MOVE")\" wurde in \"$TARGET_DIR\" verschoben."
echo "Um die Umgebung zu aktivieren, benutze:"
echo "  source $VENV_NAME/bin/activate"