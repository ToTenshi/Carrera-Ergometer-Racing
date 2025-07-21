#!/bin/bash

set -e

# Konfiguration (bitte mit deinem Setup abgleichen):

VENV_NAME="autobahnVenv"
SERVICENAME="start_autobahn.service"
SERVICEFILE="/etc/systemd/system/$SERVICENAME"
REDIS_CONTAINER_NAME="redis-server"

echo "=== Stoppe und deaktiviere systemd Service: $SERVICENAME ==="
sudo systemctl stop "$SERVICENAME" || echo "Service nicht gestartet oder nicht gefunden."
sudo systemctl disable "$SERVICENAME" || echo "Service nicht aktiviert oder nicht gefunden."

echo "=== Entferne systemd Service-Datei ==="
if [ -f "$SERVICEFILE" ]; then
  sudo rm "$SERVICEFILE"
  echo "Service-Datei $SERVICEFILE wurde gelöscht."
else
  echo "Service-Datei $SERVICEFILE nicht gefunden."
fi

echo "=== Systemd Daemon neu laden ==="
sudo systemctl daemon-reload

echo "=== Entferne virtuelle Umgebung \"$VENV_NAME\" ==="
if [ -d "$VENV_NAME" ]; then
  rm -rf "$VENV_NAME"
  echo "Ordner \"$VENV_NAME\" wurde gelöscht."
else
  echo "Ordner \"$VENV_NAME\" nicht gefunden."
fi

echo "=== Redis Docker Container stoppen und entfernen ==="
if sudo docker ps -a --format '{{.Names}}' | grep -w "$REDIS_CONTAINER_NAME" > /dev/null; then
  sudo docker stop "$REDIS_CONTAINER_NAME"
  sudo docker rm "$REDIS_CONTAINER_NAME"
  echo "Redis Container \"$REDIS_CONTAINER_NAME\" wurde gestoppt und entfernt."
else
  echo "Redis Container \"$REDIS_CONTAINER_NAME\" nicht gefunden."
fi

echo "=== Docker Dienst stoppen und deaktivieren (optional) ==="
read -p "Möchtest du den Docker-Dienst stoppen und deaktivieren? (j/N) " response
case "$response" in
  [jJ][aA]|[yY]|[yes])
    sudo systemctl stop docker
    sudo systemctl disable docker
    echo "Docker-Dienst wurde gestoppt und deaktiviert."
    ;;
  *)
    echo "Docker-Dienst bleibt aktiv."
    ;;
esac

echo "=== Deinstallation abgeschlossen ==="