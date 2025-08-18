#!/bin/bash
# set -e  # Nicht mehr stoppen bei Fehler

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Konfiguration ---
VENV_NAME="autobahnVenv"
DIR_TO_MOVE="$SCRIPT_DIR/autobahnDjango"
BACKEND_FILE="$SCRIPT_DIR/backend.py"
USERNAME=$(whoami)
REDIS_CONTAINER_NAME="redis-server"
REDIS_PORT=6379

echo "==== Docker Installation prüfen und ggf. installieren ===="
if ! command -v docker &> /dev/null
then
    echo "Docker nicht gefunden. Installation wird gestartet..."
    sudo apt-get update || echo "Warnung: apt-get update fehlgeschlagen"
    sudo apt-get install -y \
         apt-transport-https \
         ca-certificates \
         curl \
         gnupg \
         lsb-release \
         || echo "Warnung: Docker-abhängige Pakete konnten nicht installiert werden"
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
      || echo "Warnung: Docker GPG-Key konnte nicht geladen werden"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
      || echo "Warnung: Docker-Repo konnte nicht hinzugefügt werden"
    sudo apt-get update || echo "Warnung: apt-get update fehlgeschlagen"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
      || echo "Warnung: Docker konnte nicht installiert werden"
    echo "Docker wurde installiert."
else
    echo "Docker ist bereits installiert."
fi

echo "Docker-Dienst aktivieren und starten..."
sudo systemctl enable docker || echo "Warnung: Docker konnte nicht für Autostart aktiviert werden"
sudo systemctl start docker || echo "Warnung: Docker konnte nicht gestartet werden"

echo "==== Prüfe, ob Redis Container schon läuft ===="
if sudo docker ps --filter "name=^/${REDIS_CONTAINER_NAME}$" --format '{{.Names}}' | grep -w "$REDIS_CONTAINER_NAME" > /dev/null; then
    echo "Redis Container \"$REDIS_CONTAINER_NAME\" läuft bereits."
else
    echo "Starte Redis Container \"$REDIS_CONTAINER_NAME\" im Hintergrund (Port $REDIS_PORT)..."
    sudo docker run -d --name "$REDIS_CONTAINER_NAME" -p "$REDIS_PORT":6379 --restart unless-stopped redis:latest \
      || echo "Warnung: Redis Container Start fehlgeschlagen"
    echo "Redis Container wurde gestartet (oder war schon vorhanden)."
fi

echo "==== Installiere UFW (Uncomplicated Firewall) und konfiguriere Port 8000, 22 für den Webserver und SSH ===="
if ! command -v ufw &>/dev/null; then
    echo "Installiere ufw..."
    sudo apt-get update || echo "Warnung: apt-get update fehlgeschlagen"
    sudo apt-get install -y ufw || echo "Warnung: ufw konnte nicht installiert werden"
else
    echo "ufw ist bereits installiert."
fi

echo "Aktiviere Port 8000 (TCP) in ufw für Zugriff auf die Webseite und SSH..."
sudo ufw allow 8000/tcp || echo "Warnung: ufw allow 8000 fehlgeschlagen"
sudo ufw allow 22/tcp   || echo "Warnung: ufw allow 22 fehlgeschlagen"
if sudo ufw status | grep -q inactive; then
    echo "Aktiviere ufw Firewall (erstmalig, Standards erlauben ALLES eingehend bis auf explizite Regeln)."
    sudo ufw --force enable || echo "Warnung: ufw enable fehlgeschlagen"
fi
sudo ufw status verbose || echo "Warnung: ufw Status konnte nicht angezeigt werden"

# Prüfen, ob Quellordner existiert
if [ ! -d "$DIR_TO_MOVE" ]; then
  echo "FEHLER: Der Ordner zum Verschieben existiert nicht: $DIR_TO_MOVE"
  # Skript läuft weiter!
else

echo "1. Virtuelle Umgebung \"$VENV_NAME\" wird erstellt..."
python3 -m venv "$VENV_NAME" || echo "Warnung: venv konnte nicht erstellt werden"

echo "2. Virtuelle Umgebung wird aktiviert..."
source "$VENV_NAME/bin/activate" || echo "Warnung: Konnte venv nicht aktivieren"

echo "3. Pip aktualisieren und Django, Redis und rpi-lgpio installieren..."
pip install --upgrade pip      || echo "Warnung: pip upgrade fehlgeschlagen"
pip install django redis rpi-lgpio daphne channels \
    || echo "Warnung: Pakete konnten nicht installiert werden"

echo "4. Ordner wird in die virtuelle Umgebung verschoben..."
TARGET_DIR="$VENV_NAME/$(basename "$DIR_TO_MOVE")"
if [ -e "$TARGET_DIR" ]; then
  echo "Warnung: Zielordner $TARGET_DIR existiert bereits und wird überschrieben."
  rm -rf "$TARGET_DIR" || echo "Warnung: Konnte existierenden Zielordner nicht löschen"
fi
mv "$DIR_TO_MOVE" "$TARGET_DIR" || echo "Warnung: Quellordner konnte nicht verschoben werden"

if [ -f "$BACKEND_FILE" ]; then
  echo "Verschiebe backend.py in die virtuelle Umgebung..."
  TARGET_FILE="$VENV_NAME/backend.py"
  if [ -e "$TARGET_FILE" ]; then
    echo "Warnung: backend.py existiert bereits im Zielordner und wird überschrieben."
    rm -f "$TARGET_FILE" || echo "Warnung: Konnte backend.py nicht entfernen im Zielordner"
  fi
  mv "$BACKEND_FILE" "$TARGET_FILE" || echo "Warnung: Konnte backend.py nicht verschieben"
else
  echo "backend.py wurde nicht gefunden, überspringe Verschiebung."
fi

echo "5. Systemd-Service-Dateien werden angelegt..."
SERVICE_PATH="/etc/systemd/system"

# Daphne Dienst (Web-Frontend)
sudo bash -c "cat > '$SERVICE_PATH/autobahn_daphne.service'" <<EOF
[Unit]
Description=Autobahn Django Daphne ASGI Server
After=network.target
[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$SCRIPT_DIR/$VENV_NAME/$(basename "$DIR_TO_MOVE")
ExecStart=$SCRIPT_DIR/$VENV_NAME/bin/daphne -b 0.0.0.0 -p 8000 autobahnDjango.asgi:application
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

# Backend-Dienst
sudo bash -c "cat > '$SERVICE_PATH/autobahn_backend.service'" <<EOF
[Unit]
Description=Autobahn Backend
After=network.target
[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$SCRIPT_DIR/$VENV_NAME
ExecStart=$SCRIPT_DIR/$VENV_NAME/bin/python3 $SCRIPT_DIR/$VENV_NAME/backend.py
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

# Counter-Dienst (run_counter)
sudo bash -c "cat > '$SERVICE_PATH/autobahn_counter.service'" <<EOF
[Unit]
Description=Autobahn Django Counter Command
After=network.target
[Service]
Type=simple
User=$USERNAME
WorkingDirectory=$SCRIPT_DIR/$VENV_NAME/$(basename "$DIR_TO_MOVE")
ExecStart=$SCRIPT_DIR/$VENV_NAME/bin/python3 manage.py run_counter
Environment=PYTHONUNBUFFERED=1
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo "Systemd Daemon wird neu geladen, Services aktiviert und gestartet..."
sudo systemctl daemon-reload || echo "Warnung: systemctl daemon-reload fehlgeschlagen"
sudo systemctl enable autobahn_daphne.service   || echo "Warnung: autobahn_daphne.service konnte nicht aktiviert werden"
sudo systemctl enable autobahn_backend.service  || echo "Warnung: autobahn_backend.service konnte nicht aktiviert werden"
sudo systemctl enable autobahn_counter.service  || echo "Warnung: autobahn_counter.service konnte nicht aktiviert werden"
sudo systemctl restart autobahn_daphne.service  || echo "Warnung: autobahn_daphne.service konnte nicht neugestartet werden"
sudo systemctl restart autobahn_backend.service || echo "Warnung: autobahn_backend.service konnte nicht neugestartet werden"
sudo systemctl restart autobahn_counter.service || echo "Warnung: autobahn_counter.service konnte nicht neugestartet werden"

echo "Die Dienste wurden aktiviert und gestartet."
echo "Status prüfen z.B. mit:"
echo "  sudo systemctl status autobahn_daphne"
echo "  sudo systemctl status autobahn_backend"
echo "  sudo systemctl status autobahn_counter"

fi

echo "Setze Ausführungsrechte für uninstall.sh ..."
chmod +x "$SCRIPT_DIR/uninstall.sh" || echo "Warnung: uninstall.sh konnte nicht auf ausführbar gesetzt werden"

echo "Fertig!"
