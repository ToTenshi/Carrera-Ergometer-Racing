#!/bin/bash

# Zum Django-Projektverzeichnis wechseln
cd /home/pi/autobahntobi/autobahn/autobahnDjango
#python manage.py run_counter &
echo "start realtime script"
nohup python manage.py run_counter > counter.log 2>&1 &

# Daphne (falls auch im gleichen Verzeichnis oder CD vorher ausführen)
echo "start Frontend"
nohup daphne -b 0.0.0.0 -p 8000 autobahnDjango.asgi:application > daphne.log 2>&1 & 

# Zum Backend-Pfad wechseln und Skript starten
cd /home/pi/autobahntobi
echo "start backend"

nohup python3 'backend.py' > backend.log 2>&1 &

