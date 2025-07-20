import os
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application
import autobahnGUI.routing

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'autobahnDjango.settings')

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": URLRouter(
        autobahnGUI.routing.websocket_urlpatterns
    ),
})