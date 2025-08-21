import redis
import time
from django.http import JsonResponse
from django.http import StreamingHttpResponse
from django.shortcuts import render

r = redis.Redis(host='localhost', port=6379, db=0)


from django.shortcuts import render

def dashboard_view(request):
    return render(request, "dashboard.html")

def controlbuttons(request):
    if request.method == "POST":
        action = request.POST.get("action")
        if action == "start":
            message = "Das System wurde gestartet."
        elif action == "pause":
            message = "Das System wurde pausiert."
        elif action == "stop":
            message = "Das System wurde gestoppt."
        else:
            message = "Unbekannte Aktion."
        
        return render(request, "GUI.html", {"message": message})
    
    return render(request, "GUI.html")
