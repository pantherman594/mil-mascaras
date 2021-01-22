import pygame
import time
# location of our sounds directory/folder
fileLocation = "/home/pi/sounds/"
# sets up to play sound and loads the "startup.wav" sound
pygame.mixer.init()
pygame.mixer.music.load(fileLocation + "startup.wav")
speakerVolume = "0.2" # initially sets speaker at 50%, "1.0" is full volume
pygame.mixer.music.set_volume(float(speakerVolume))
pygame.mixer.music.play()
while pygame.mixer.music.get_busy() == True:
    continue

