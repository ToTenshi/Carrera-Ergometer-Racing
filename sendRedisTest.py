import redis
from random import randint
from time import sleep

lane0 = 0
lane1 = 0
answer = ""

while True:
    try:
        r = redis.Redis(host='localhost', port=6379, db=0)
        print("Mit redis verbunden")
        break

    except:
        print("mit redis nicht verbunden")
        sleep(5)


while answer != "stop":
    answer = input("Geben Sie die Spur der Autobahn an: (0/1)")
    if answer == "1":
        try:
            lane1 = int(input("Höhe Geschwindigkeit:"))
        except:
            print("Geben Sie eine gültige Zahl an.")
        
    elif answer == "0":
        print("")
    elif answer == "stop":
        break
    else:
        continue
