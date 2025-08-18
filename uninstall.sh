#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_NAME="autobahnVenv"
REDIS_CONTAINER_NAME="redis-server"

SERVICE_PATH="/etc/systemd/system"
SERVICES="autobahn_daphne.service autobahn_backend.service autobahn_counter.service"

echo "================= DEINSTALLATION ================="

# 1. Systemd Services stoppen & deaktivieren & löschen
for s in $SERVICES; do
  echo "Stoppe Service $s ..."
  sudo systemctl stop "$s" 2>/dev/null || echo "Warnung: Service $s konnte nicht gestoppt werden oder läuft nicht."
  echo "Deaktiviere Service $s ..."
  sudo systemctl disable "$s" 2>/dev/null || echo "Warnung: Service $s konnte nicht deaktiviert werden."
  echo "Entferne Service-Datei $s ..."
  sudo rm -f "$SERVICE_PATH/$s" || echo "Warnung: Service-Datei $s konnte nicht gelöscht werden."
done

# systemd neu laden
echo "Lade systemd daemon neu ..."
sudo systemctl daemon-reload || echo "Warnung: systemctl daemon-reload fehlgeschlagen."

# 2. Virtuelle Umgebung löschen
if [ -d "$SCRIPT_DIR/$VENV_NAME" ]; then
  echo "Entferne virtuelle Umgebung $VENV_NAME ..."
  rm -rf "$SCRIPT_DIR/$VENV_NAME" || echo "Warnung: Virtuelle Umgebung konnte nicht gelöscht werden."
else
  echo "Virtuelle Umgebung $VENV_NAME nicht gefunden."
fi

# 3. Redis Docker-Container entfernen (optional)
if docker ps -a --format '{{.Names}}' | grep -q "^$REDIS_CONTAINER_NAME$"; then
  echo "Stoppe und entferne Redis-Container '$REDIS_CONTAINER_NAME' ..."
  sudo docker stop "$REDIS_CONTAINER_NAME" || echo "Warnung: Redis-Container konnte nicht gestoppt werden."
  sudo docker rm "$REDIS_CONTAINER_NAME" || echo "Warnung: Redis-Container konnte nicht entfernt werden."
else
  echo "Redis-Container '$REDIS_CONTAINER_NAME' läuft nicht oder ist nicht vorhanden."
fi

# 4. Firewall zurücksetzen (Eintrag für Port 8000 entfernen)
if command -v ufw &>/dev/null; then
  echo "Entferne ufw-Regel für Port 8000 ..."
  sudo ufw delete allow 8000/tcp || echo "Warnung: ufw-Regel für 8000/tcp konnte nicht entfernt werden oder war nicht gesetzt."
else
  echo "ufw ist nicht installiert."
fi

echo "================= FERTIG ========================="
echo "Du kannst ggf. übrige Daten wie das Projektverzeichnis manuell entfernen."
