import asyncio
from django.core.management.base import BaseCommand
from channels.layers import get_channel_layer
import redis

r = redis.Redis(host='localhost', port=6379, db=0)

class Command(BaseCommand):
    help = "Startet den Counter und broadcastet via Channels"

    async def count(self):
        channel_layer = get_channel_layer()
        counter = 0
        speed1 = 0
        speed2 = 0
        while True:
            counter += 1
            #speed1 = 0 #r.get("speed1")
            #speed2 = 0 #r.get("speed2")

            speed1 = r.get("speed1")
            if speed1 is not None:
                speed1 = speed1.decode("utf-8")
                print("speed1", speed1)

            speed2 = r.get("speed2")
            if speed2 is not None:
                speed2 = speed2.decode("utf-8")
                print("speed2", speed2)


            await channel_layer.group_send(
                "dashboard",
                {
                    "type": "dashboard.update",
                    "counter": counter,
                    "speed1": speed1,
                    "speed2": speed2,
                }
            )
            await asyncio.sleep(0.1)

    def handle(self, *args, **options):
        asyncio.run(self.count())