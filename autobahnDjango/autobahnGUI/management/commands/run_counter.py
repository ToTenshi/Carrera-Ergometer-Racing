import asyncio
from django.core.management.base import BaseCommand
from channels.layers import get_channel_layer
import redis

r = redis.Redis(host='localhost', port=6379, db=0)

class Command(BaseCommand):
    help = "Startet den Broadcast via Channels"

    async def count(self):
        channel_layer = get_channel_layer()

        while True:
            # Geschwindigkeiten aus Redis holen
            speed0 = r.get("speed0")
            if speed0 is not None:
                speed0 = speed0.decode("utf-8")

            speed1 = r.get("speed1")
            if speed1 is not None:
                speed1 = speed1.decode("utf-8")

            # Neue Rundenwerte aus Redis holen
            round0 = r.get("rounds0")
            if round0 is not None:
                round0 = round0.decode("utf-8")

            round1 = r.get("rounds1")
            if round1 is not None:
                round1 = round1.decode("utf-8")

            # An die Gruppe "dashboard" senden
            await channel_layer.group_send(
                "dashboard",
                {
                    "type": "dashboard.update",
                    "speed0": speed0,
                    "speed1": speed1,
                    "round0": round0,
                    "round1": round1,
                }
            )

            await asyncio.sleep(0.1)  # Alle 100ms werden neue Werte gesendet

    def handle(self, *args, **options):
        asyncio.run(self.count())
