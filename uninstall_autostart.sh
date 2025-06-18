#!/bin/bash

echo "==== Systemd Service Deinstaller ===="

# Name des service files
SERVICENAME="start_autobahn.service"
SERVICEFILE="/etc/systemd/system/$SERVICENAME"

# Prüfe ob der Dienst existiert
if [ ! -f "$SERVICEFILE" ]; then
    echo "Systemd Service-Datei $SERVICEFILE nicht gefunden!"
    exit 1
fi

# Dienst stoppen und deaktivieren
echo "Stoppe und deaktiviere $SERVICENAME..."
sudo systemctl stop $SERVICENAME
sudo systemctl disable $SERVICENAME

# Service-Datei löschen
echo "Lösche $SERVICEFILE..."
sudo rm "$SERVICEFILE"

# systemd neu laden
echo "Lade systemd neu..."
sudo systemctl daemon-reload

echo "Der Dienst $SERVICENAME wurde entfernt!"