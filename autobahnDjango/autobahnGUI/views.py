import redis
import time
from django.http import JsonResponse
from django.http import StreamingHttpResponse
from django.shortcuts import render

r = redis.Redis(host='localhost', port=6379, db=0)
controlkey = "startStop"
round0key = "round0"
round1key = "round1"

from django.shortcuts import render

def dashboard_view(request):
    return render(request, "dashboard.html")

def controlbuttons(request):
    if request.method == "POST":
        action = request.POST.get("action")
        rounds = request.POST.get("rounds")
        if action in ["start", "pause", "stop"]:
            r.set(controlkey, action)

        if action == "pause" and rounds:
            r.set(round0key, rounds)
            r.set(round1key, rounds)

    return render(request, "dashboard.html", {"rounds": rounds})
