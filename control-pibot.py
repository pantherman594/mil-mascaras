# control-pibot.py
# If your pi's hostname is something different than "mil-mascaras", see comments
# below the lines labeled *** IMPORTANT *** below.

# Updated to support multiple directions at the same time, while maintaining
# backwards compatibility with the original app.

# *** IMPORTANT ***
# The commands below assume your pi's hostname is mil-mascaras. If you have a
# different name, then use that name in place of mil-mascaras in the mosquitto_pub
# commands, below.
# once running, you can test with the shell commands:
# To play any of the numbered sounds (substitute a diffrent number for "1" for a different sound:
# mosquitto_pub -h mil-mascaras.local -t "pibot/move" -m "1"
# To start the robot:
# mosquitto_pub -h mil-mascaras.local -t "pibot/move" -m "forward"
# To stop the robot:
# mosquitto_pub -h mil-mascaras.local -t "pibot/move" -m "stop"

import pygame
import time
import paho.mqtt.client as mqtt
from inspect import signature
import os

# =============================================================================
# CONFIG START
# =============================================================================

from adafruit_motorkit import MotorKit
# if you're using an Adafruit Crickit hat, uncomment the line below and comment out the statement above:
# from adafruit_crickit import crickit
# NOTE: The line below is needed if you're using the Waveshare Motor Driver Hat
# comment out this line if you're using a Crickit
kit = MotorKit(0x40)
# Also, only if using the Waveshare Motor Driver Hat, be sure you've installed
# and modified CircuitPython files, in particular the file at:
# /usr/local/lib/python3.5/dist-packages/adafruit_motorkit.py
# as described in the tutorial at:
# https://gallaugher.com/mil-mascaras

# uncomment lines below if you're using a Crickit
# then replace any reference to kit.motor1 with motor_1 and kit.motor2 with motor_2
# motor_1 = crickit.dc_motor_1
# motor_2 = crickit.dc_motor_2

clientName = "PiBot"
# *** IMPORTANT ***
# This is your pi's host name. If your name is something different than
# mil-mascaras, then be sure to change it, here - make it the name of your Pi
serverAddress = "mil-mascaras"
# Flag to indicate subscribe confirmation hasn't been printed yet.
didPrintSubscribeMessage = False

# If the robot veers left or right, add a small amount to the left or right trim, below
# until the bot moves roughly straight. The #s below reflect the bot I'm working with.
# It's probably best to start both trim values at 0 and adjust from there.
# out of 1.0 full power.
leftTrim   = 0.0
rightTrim  = 0.0

# This will make turns at 50% of the speed of fwd or backward
slowTurnBy = 0.5

# setup startup sound. Make sure you have a sounds
# folder with a sound named startup.mp3
fileLocation = "/home/pi/sounds/"
startupSound = "startup.mp3"
speakerVolume = 0.5 # initially sets speaker at 50%

# =============================================================================
# CONFIG END
# =============================================================================

pygame.mixer.init()
pygame.mixer.music.load(fileLocation + startupSound)
pygame.mixer.music.set_volume(speakerVolume)
pygame.mixer.music.play()

mqttClient = mqtt.Client(clientName)

state = [False] * 4

def connectionStatus(client, userdata, flags, rc):
    global didPrintSubscribeMessage
    if not didPrintSubscribeMessage:
        didPrintSubscribeMessage = True
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

def vol(volume):
    global speakerVolume

    try:
        speakerVolume = float(volume)
        pygame.mixer.music.set_volume(speakerVolume)

        print("Updated volume to: {}".format(speakerVolume))
    except:
        print("Invalid volume")

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
    "vol": vol,
}

def messageDecoder(client, userdata, msg):
    message = msg.payload.decode(encoding='UTF-8')
    parts = message.split(" ")

    if len(parts) == 1 and parts[0].startsWith("Vol="):
        parts = message.split("=")
        parts[0] = "vol"

    command = parts[0]
    args = parts[1:]

    if command in commands:
        num_params = len(signature(commands[command]).parameters)

        if len(args) != num_params:
            print("Invalid parameters for {}: expected {}, got {}".format(command, num_params, len(args)))
        else:
            commands[command](*args)
    else:
        playPath = fileLocation + message + ".mp3"
        if os.path.isfile(playPath):
            print("Playing sound at: " + playPath)
            pygame.mixer.music.stop()
            pygame.mixer.music.load(playPath)
            pygame.mixer.music.play()
        else:
            print("Unknown message and no sound file exists:", message)

# Set up calling functions to mqttClient
mqttClient.on_connect = connectionStatus
mqttClient.on_message = messageDecoder

# Connect to the MQTT server & loop forever.
# CTRL-C will stop the program from running.
mqttClient.connect(serverAddress)
mqttClient.loop_forever()

