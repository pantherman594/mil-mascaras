# control-pibot.py
# If your pi's hostname is something different than "mil-mascaras", see comments
# below the lines labeled *** IMPORTANT *** below.

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
from adafruit_motorkit import MotorKit
# NOTE: The line below is needed if you're using the Waveshare Motor Driver Hat
kit = MotorKit(0x40)
# Also, only if using the Waveshare Motor Driver Hat, be sure you've installed
# and modified CircuitPython files, in particular the file at:
# /usr/local/lib/python3.5/dist-packages/adafruit_motorkit.py
# as described in the tutorial at:
# https://gallaugher.com/mil-mascaras

clientName = "PiBot"
# *** IMPORTANT ***
# This is your pi's host name. If your name is something different than
# mil-mascaras, then be sure to change it, here
serverAddress = "mil-mascaras"
mqttClient = mqtt.Client(clientName)
# Flag to indicate subscribe confirmation hasn't been printed yet.
didPrintSubscribeMessage = False

# If the robot veers left or right, add a small amount to the left or right trim, below
# until the bot moves roughly straight. The #s below reflect the bot I'm working with.
# It's probably best to start both trim values at 0 and adjust from there.
# out of 1.0 full power.
LEFT_TRIM   = -0.01
RIGHT_TRIM  = 0.0

leftSpeed = 1.0 + LEFT_TRIM
rightSpeed = 1.0 + RIGHT_TRIM

# This will make turns at 50% of the speed of fwd or backward
slowTurnBy = 0.5

# setup startup sound. Make sure you have a sounds
# folder with a sound named startup.mp3
fileLocation = "/home/pi/sounds/"
pygame.mixer.init()
pygame.mixer.music.load(fileLocation + "startup.mp3")
speakerVolume = ".50" # initially sets speaker at 50%
pygame.mixer.music.set_volume(float(speakerVolume))
pygame.mixer.music.play()

def connectionStatus(client, userdata, flags, rc):
    global didPrintSubscribeMessage
    if not didPrintSubscribeMessage:
        didPrintSubscribeMessage = True
        print("subscribing")
        mqttClient.subscribe("pibot/move")
        print("subscribed")

def messageDecoder(client, userdata, msg):
    message = msg.payload.decode(encoding='UTF-8')

    if message == "forward":
        kit.motor1.throttle = leftSpeed
        kit.motor2.throttle = rightSpeed
        print("^^^ moving forward! ^^^")
        print(leftSpeed,rightSpeed)
    elif message == "stop":
        kit.motor1.throttle = 0.0
        kit.motor2.throttle = 0.0
        print("!!! stopping!")
    elif message == "backward":
        kit.motor1.throttle = -leftSpeed
        kit.motor2.throttle = -rightSpeed
        print("\/ backward \/")
        print(-leftSpeed,-rightSpeed)
    elif message == "left":
        kit.motor1.throttle = -leftSpeed * slowTurnBy
        kit.motor2.throttle = rightSpeed * slowTurnBy
        print("<- left")
        print(-leftSpeed * slowTurnBy,rightSpeed * slowTurnBy)
    elif message == "right":
        kit.motor1.throttle = leftSpeed * slowTurnBy
        kit.motor2.throttle = -rightSpeed * slowTurnBy
        print("-> right")
        print(leftSpeed * slowTurnBy,-rightSpeed * slowTurnBy)
    elif message.startswith("Vol="):
        speakerVolume = message[4:]
        pygame.mixer.music.set_volume(float(speakerVolume))
    else:
        print("Playing sound at: " + fileLocation + message + ".mp3")
        pygame.mixer.music.stop()
        pygame.mixer.music.load(fileLocation + message + ".mp3") # assumes you have a file$
        pygame.mixer.music.play()

# Set up calling functions to mqttClient
mqttClient.on_connect = connectionStatus
mqttClient.on_message = messageDecoder

# Connect to the MQTT server & loop forever.
# CTRL-C will stop the program from running.
mqttClient.connect(serverAddress)
mqttClient.loop_forever()
