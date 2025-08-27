import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
import json

class DashboardConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        await self.channel_layer.group_add("dashboard", self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard("dashboard", self.channel_name)

    async def dashboard_update(self, event):
        # speed0, speed1, round0 und round1 an den Client senden
        await self.send(text_data=json.dumps({
            'speed0': event['speed0'],
            'speed1': event['speed1'],
            'round0': event['round0'],
            'round1': event['round1'],
        }))