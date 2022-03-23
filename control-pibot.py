# control-pibot.py
# Updated to support multiple directions at the same time, while maintaining
# backwards compatibility with the original app.

# once running, you can test with the shell commands:
# To start the robot:
# mosquitto_pub -h pibot.local -t "pibot/move" -m "forward"
# To stop the robot:
# mosquitto_pub -h pibot.local -t "pibot/move" -m "stop"

import paho.mqtt.client as mqtt
from inspect import signature

###from adafruit_motorkit import MotorKit

# =============================================================================
# CONFIG START
# =============================================================================

###kit = MotorKit()
# NOTE: If using the Waveshare Motor Driver Hat, change the above line to:
# kit = MotorKit(0x40)
# Also, only if using the Waveshare Motor Driver Hat, be sure you've installed
# and modified CircuitPython files, in particular the file at:
# /usr/local/lib/python3.5/dist-packages/adafruit_motorkit.py
# as described in the tutorial at:
# https://gallaugher.com/makersnack-install-and-test-the-waveshare-raspberry-pi/

clientName = "PiBot"
serverAddress = "localhost"

# If the robot veers left or right, add a small amount to the left or right trim, below
# until the bot moves roughly straight. The #s below reflect the bot I'm working with.
# It's probably best to start both trim values at 0 and adjust from there.
# out of 1.0 full power.
leftTrim   = 0.0
rightTrim  = 0.0

# This will make turns at 50% of the speed of fwd or backward
slowTurnBy = 0.5

# =============================================================================
# CONFIG END
# =============================================================================

mqttClient = mqtt.Client(clientName)

state = [False] * 4

def connectionStatus(client, userdata, flags, rc):
    print("subscribing")
    mqttClient.subscribe("pibot/move")
    print("subscribed")

def forward():
    setDirection(0, True)
def backward():
    setDirection(1, True)
def left():
    setDirection(2, True)
def right():
    setDirection(3, True)
def forward_up():
    setDirection(0, False)
def backward_up():
    setDirection(1, False)
def left_up():
    setDirection(2, False)
def right_up():
    setDirection(3, False)

def update_trim(left, right):
    global leftTrim, rightTrim

    try:
        leftTrim = float(left)
        rightTrim = float(right)

        print("Updated trim values to l: {}, r: {}".format(leftTrim, rightTrim))
        updateMotors()
    except:
        print("Invalid trim values")

def setDirection(direction, val):
    global state
    state[direction] = val
    updateMotors()

def stop():
    global state
    state = [False] * 4
    updateMotors()

def updateMotors():
    global leftTrim, rightTrim

    leftSpeed = 1.0 + leftTrim
    rightSpeed = 1.0 + rightTrim

    lthrottle = 0
    rthrottle = 0

    f, b, l, r = state

    if f == b:
        f = b = False
    if l == r:
        l = r = False

    dirs = []
    if f:
        dirs.append("forward")
        lthrottle = leftSpeed
        rthrottle = rightSpeed
    if b:
        dirs.append("backward")
        lthrottle = leftSpeed
        rthrottle = rightSpeed

    if l:
        dirs.append("left")
        if not (f or b):
            lthrottle = -leftSpeed * slowTurnBy
        rthrottle += rightSpeed * slowTurnBy
    if r:
        dirs.append("right")
        if not (f or b):
            rthrottle = -rightSpeed * slowTurnBy
        lthrottle += leftSpeed * slowTurnBy

    ###kit.motor1.throttle = lthrottle
    ###kit.motor2.throttle = rthrottle

    if len(dirs) > 0:
        print(" and ".join(dirs))
    else:
        print("stopping")
    print(lthrottle, rthrottle)

commands = {
    "forward": forward,
    "backward": backward,
    "left": left,
    "right": right,

    "forward_up": forward_up,
    "backward_up": backward_up,
    "left_up": left_up,
    "right_up": right_up,

    "stop": stop,

    "update_trim": update_trim,
}

def messageDecoder(client, userdata, msg):
    message = msg.payload.decode(encoding='UTF-8')
    parts = message.split(" ")
    command = parts[0]
    args = parts[1:]

    if command in commands:
        num_params = len(signature(commands[command]).parameters)

        if len(args) != num_params:
            print("Invalid parameters for {}: expected {}, got {}".format(command, num_params, len(args)))
        else:
            commands[command](*args)
    else:
        print("?!? Unknown message?!?", message)

# Set up calling functions to mqttClient
mqttClient.on_connect = connectionStatus
mqttClient.on_message = messageDecoder

# Connect to the MQTT server & loop forever.
# CTRL-C will stop the program from running.
mqttClient.connect(serverAddress)
mqttClient.loop_forever()

