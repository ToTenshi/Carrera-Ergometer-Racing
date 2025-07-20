import redis
import time
from django.http import JsonResponse
from django.http import StreamingHttpResponse
from django.shortcuts import render

r = redis.Redis(host='localhost', port=6379, db=0)


from django.shortcuts import render

def dashboard_view(request):
    return render(request, "dashboard.html")

"""
def get_speeds(request):
    speed1 = r.get("speed1")
    speed2 = r.get("speed2")
    speed1 = int(speed1) if speed1 is not None else 0
    speed2 = int(speed2) if speed2 is not None else 0
    return JsonResponse({"speed1": speed1, "speed2": speed2})



def speed_updates(request):
    def event_stream():
        while True:
            speed1 = r.get("speed0").decode("utf-8")
            speed2 = r.get("speed1").decode("utf-8")
            if speed1 is not None:
                speed1 = float(speed1)  # Ensure speed is an integer
            if speed2 is not None:
                speed2 = float(speed2)  # Ensure speed is an integer
            yield f"data: {speed1}, {speed2}\n\n"
            print("update speed")
            print(speed1, speed2)
            time.sleep(1)  # Verzögerung für die nächste Aktualisierung
            

    return StreamingHttpResponse(event_stream(), content_type='text/event-stream')


def autobahnGUI(request):
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

"""