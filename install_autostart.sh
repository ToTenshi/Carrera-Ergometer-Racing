#!/bin/bash

echo "==== Systemd Service Installer ===="

# Nach dem Pfad zum Startskript fragen
read -p "Pfad zu deinem Startskript (z.B. /home/pi/start_services.sh): " STARTSCRIPT

# Arbeitsverzeichnis automatisch auslesen
WORKDIR=$(dirname "$STARTSCRIPT")

# Den aktuellen Nutzer automatisch nehmen (ersatzweise 'pi' eintragen)
USERNAME=$(whoami)

# Service-Dateiname wählen
SERVICENAME=start_autobahn.service
SERVICEFILE="/etc/systemd/system/$SERVICENAME"

echo "Erstelle systemd Service-Datei: $SERVICEFILE"
sudo bash -c "cat > $SERVICEFILE" <<EOF
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

sudo systemctl daemon-reload
sudo systemctl enable $SERVICENAME
sudo systemctl start $SERVICENAME

echo "Der Dienst wurde aktiviert und gestartet."
echo "Status-Prüfung: sudo systemctl status $SERVICENAME"