#!/bin/bash

set -e  # Skript stoppen bei Fehler

# Verzeichnis des Skripts bestimmen
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Konfiguration ---

VENV_NAME="autobahnVenv"
DIR_TO_MOVE="$SCRIPT_DIR/autobahnDjango"   # Zu verschiebender Ordner, relativ zum Skript
STARTSCRIPT="$SCRIPT_DIR/startautobahn.sh"   # Pfad zum Startskript für systemd (absolute oder relative Angabe)

SERVICENAME="start_autobahn.service"
SERVICEFILE="/etc/systemd/system/$SERVICENAME"

REDIS_CONTAINER_NAME="redis-server"
REDIS_PORT=6379

# -------------------------------------------------------------------

echo "==== Docker Installation prüfen und ggf. installieren ===="

if ! command -v docker &> /dev/null
then
    echo "Docker nicht gefunden. Installation wird gestartet..."

    sudo apt-get update

    sudo apt-get install -y \
         apt-transport-https \
         ca-certificates \
         curl \
         gnupg \
         lsb-release

    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    echo "Docker wurde installiert."
else
    echo "Docker ist bereits installiert."
fi

echo "Docker-Dienst aktivieren und starten..."
sudo systemctl enable docker
sudo systemctl start docker

echo "==== Prüfe, ob Redis Container schon läuft ===="
if sudo docker ps --filter "name=^/${REDIS_CONTAINER_NAME}$" --format '{{.Names}}' | grep -w "$REDIS_CONTAINER_NAME" > /dev/null; then
    echo "Redis Container \"$REDIS_CONTAINER_NAME\" läuft bereits."
else
    echo "Starte Redis Container \"$REDIS_CONTAINER_NAME\" im Hintergrund (Port $REDIS_PORT)..."
    sudo docker run -d --name "$REDIS_CONTAINER_NAME" -p "$REDIS_PORT":6379 redis:latest
    echo "Redis Container wurde gestartet."
fi

# ---- Ende Docker & Redis Setup ----

# Prüfen, ob Quellordner existiert
if [ ! -d "$DIR_TO_MOVE" ]; then
  echo "FEHLER: Der Ordner zum Verschieben existiert nicht: $DIR_TO_MOVE"
  exit 1
fi

# Prüfen, ob Startskript existiert
if [ ! -f "$STARTSCRIPT" ]; then
  echo "FEHLER: Das Startskript existiert nicht: $STARTSCRIPT"
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

# Neu: backend.py verschieben
BACKEND_FILE="$SCRIPT_DIR/backend.py"

if [ -f "$BACKEND_FILE" ]; then
  echo "Verschiebe backend.py in die virtuelle Umgebung..."

  TARGET_FILE="$VENV_NAME/backend.py"

  if [ -e "$TARGET_FILE" ]; then
    echo "Warnung: backend.py existiert bereits im Zielordner und wird überschrieben."
    rm -f "$TARGET_FILE"
  fi

  mv "$BACKEND_FILE" "$TARGET_FILE"
else
  echo "backend.py wurde nicht gefunden, überspringe Verschiebung."
fi

echo "5. Systemd-Service wird angelegt..."

WORKDIR=$(dirname "$STARTSCRIPT")
USERNAME=$(whoami)

echo "Erstelle systemd Service-Datei: $SERVICEFILE"

sudo bash -c "cat > '$SERVICEFILE'" <<EOF
[Unit]
Description=Starte Python-/Django-Skripte automatisch
After=network.target

[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$WORKDIR
ExecStart=$STARTSCRIPT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Systemd Service-Datei wurde geschrieben."

echo "Systemd Daemon wird neu geladen, Service aktiviert und gestartet..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICENAME"
sudo systemctl start "$SERVICENAME"

echo "Der Dienst wurde aktiviert und gestartet."
echo "Status kannst du prüfen mit:"
echo "  sudo systemctl status $SERVICENAME"

echo "Fertig!"