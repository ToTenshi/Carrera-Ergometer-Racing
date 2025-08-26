import redis
import time
from django.http import JsonResponse
from django.http import StreamingHttpResponse
from django.shortcuts import render

r = redis.Redis(host='localhost', port=6379, db=0)
controlkey = "startStop"

from django.shortcuts import render

def dashboard_view(request):
    return render(request, "dashboard.html")

def controlbuttons(request):
    if request.method == "POST":
        action = request.POST.get("action")
        if action in ["start", "pause", "stop"]:
            r.set(controlkey, action)
        # else: Du kannst hier ggf. eine Fehlermeldung loggen, musst aber nichts im Template ausgeben.

    return render(request, "dashboard.html")
