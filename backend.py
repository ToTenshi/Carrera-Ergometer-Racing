from time import sleep
import RPi.GPIO as GPIO
import redis
import time
from collections import deque  # For moving average

# Configuration Constants
LANE0_MULTIPLICATOR = 0.7  # Reduces the rapid increase of speed for bike 0
LANE1_MULTIPLICATOR = 0.4  # Reduces the rapid increase of speed for bike 1
SPEED_LIMIT = 50
DEBOUNCE_TIME = 0.1  # Minimum time between pulses in seconds

# Deceleration Constants
LANE0_DECELERATION_RATE = 5  # Value to reduce speed per iteration
LANE0_DECELERATION_INTERVAL = 0.5  # Interval in seconds for reducing speed

LANE1_DECELERATION_RATE = 5  # Value to reduce speed per iteration
LANE1_DECELERATION_INTERVAL = 0.5  # Interval in seconds for reducing speed

# GPIO Pins
PIN_LANE0 = 16
PIN_LANE1 = 25
PIN_BIKE0 = 26
PIN_BIKE1 = 23

# Redis Setup
REDIS_HOST = 'localhost'
REDIS_PORT = 6379

# Initialize Variables
lane0_last_pulse_time = time.time()
lane1_last_pulse_time = time.time()
lane0_bike_speed = 0
lane1_bike_speed = 0
rstart_stop = "start"
redis_connected = False

# GPIO Setup
GPIO.setmode(GPIO.BCM)
GPIO.setup(PIN_LANE0, GPIO.OUT)
GPIO.setup(PIN_LANE1, GPIO.OUT)
GPIO.setup(PIN_BIKE0, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(PIN_BIKE1, GPIO.IN, pull_up_down=GPIO.PUD_UP)
lane0 = GPIO.PWM(PIN_LANE0, 50)  # Frequency=50Hz
lane0.start(0)  # Initialize with no speed
lane1 = GPIO.PWM(PIN_LANE1, 50)  # Frequency=50Hz
lane1.start(0)  # Initialize with no speed

# Redis Connection
try:
    r = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, db=0)
    redis_connected = True
    print("Redis connected")
except:
    print("Redis not found")

def measure_time(previous_time):
    """Calculate the elapsed time since the previous pulse."""
    return round(time.time() - previous_time, 3)

def bike0_callback(channel):
    """Handle bike 0 pulse detection."""
    global lane0_last_pulse_time, lane0_bike_speed
    current_time = time.time()
    if current_time - lane0_last_pulse_time >= DEBOUNCE_TIME:
        pulse_distance = measure_time(lane0_last_pulse_time)
        lane0_last_pulse_time = current_time
        
        # New formula for smoother speed increase
        lane0_bike_speed = round((1 / pulse_distance) * LANE0_MULTIPLICATOR * 10, 2)
        if lane0_bike_speed > SPEED_LIMIT:
            lane0_bike_speed = SPEED_LIMIT
        set_redis("speed0", lane0_bike_speed)
        print("Bike 0 speed updated:", lane0_bike_speed)

def bike1_callback(channel):
    """Handle bike 1 pulse detection."""
    global lane1_last_pulse_time, lane1_bike_speed
    current_time = time.time()
    if current_time - lane1_last_pulse_time >= DEBOUNCE_TIME:
        pulse_distance = measure_time(lane1_last_pulse_time)
        lane1_last_pulse_time = current_time
        
        # New formula for smoother speed increase
        lane1_bike_speed = round((1 / pulse_distance) * LANE1_MULTIPLICATOR * 10, 2)
        if lane1_bike_speed > SPEED_LIMIT:
            lane1_bike_speed = SPEED_LIMIT
        set_redis("speed1", lane1_bike_speed)
        print("Bike 1 speed updated:", lane1_bike_speed)

def set_redis(key, value):
    """Set value in Redis."""
    global redis_connected
    if redis_connected:
        r.set(key, value)

def get_redis(key):
    """Get value from Redis."""
    global redis_connected
    if redis_connected:
        return r.get(key).decode("utf-8")

# Initialization in Redis
set_redis("speed0", 0)
set_redis("speed1", 0)
set_redis("startStop", "start")

# Event Detection
GPIO.add_event_detect(PIN_BIKE0, GPIO.FALLING, callback=bike0_callback, bouncetime=50)
GPIO.add_event_detect(PIN_BIKE1, GPIO.FALLING, callback=bike1_callback, bouncetime=50)

# Main Loop
try:
    while rstart_stop != "stop":
        rstart_stop = get_redis("startStop")
    
        if rstart_stop == "pause":
            lane0.ChangeDutyCycle(0) #Geschwindigkeit auf 0 setzen
            lane1.ChangeDutyCycle(0)
            continue

        # Handle deceleration for lane 0
        if time.time() - lane0_last_pulse_time >= LANE0_DECELERATION_INTERVAL:
            lane0_bike_speed = max(0, lane0_bike_speed - LANE0_DECELERATION_RATE)
            set_redis("speed0", lane0_bike_speed)
        
        # Handle deceleration for lane 1
        if time.time() - lane1_last_pulse_time >= LANE1_DECELERATION_INTERVAL:
            lane1_bike_speed = max(0, lane1_bike_speed - LANE1_DECELERATION_RATE)
            set_redis("speed1", lane1_bike_speed)
        
        # Update PWM signals
        lane0.ChangeDutyCycle(get_redis("speed0"))
        lane1.ChangeDutyCycle(get_redis("speed1"))
        
        print("Aktuelle Geschwindigkeit von Redis für Bike 0:", get_redis("speed0"))
        print("Aktuelle Geschwindigkeit von Redis für Bike 1:", get_redis("speed1"))
        
        sleep(0.1)  # Prevent high CPU load
finally:
    GPIO.cleanup()  # GPIO reset
    lane0.stop()  # Stop PWM for lane 0
    lane1.stop()  # Stop PWM for lane 1
    print("Programm erfolgreich beendet.")
