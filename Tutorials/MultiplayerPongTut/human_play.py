import numpy as np
import cv2
import random
import time
import pygame, sys
from datetime import datetime
import os
from random import choice
from time import sleep
from pongMultiplayer import pongMultiplayerEnv

pygame.init()

width = 640
height = 640

gameDisplay = pygame.display.set_mode((width, height))
pygame.display.set_caption("Platyp us")
pygame.mouse.set_visible(False)

peer_port = "9000"
peer_type = "server"
ip_address = "127.0.0.1"
GODOT_BIN_PATH = "./multiplayer_pong/pong_multi.x86_64"
env_abs_path = "./multiplayer_pong/pong_multi.pck"
env = pongMultiplayerEnv(exec_path=GODOT_BIN_PATH, env_path=env_abs_path, peer_type=peer_type, ip_address=ip_address, 
						 turbo_mode=True)

clock = pygame.time.Clock()


if __name__ == '__main__':
	for episode in range(1000):
		print("episode: ", episode)

		state = env.reset()

		reward_sum = 0
		for step in range(0, 500):
			#print("server, step: ", step)
			start = time.time()

			pygame.event.set_grab(True)

			keyboard_move = [0, 0, 0]
			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					exit = True

				if event.type == pygame.KEYDOWN:
					if event.key == pygame.K_w:
						keyboard_move[1] = 1

					if event.key == pygame.K_s:
						keyboard_move[2] = 1

			left, middle, right = pygame.mouse.get_pressed()
			keys = pygame.key.get_pressed()
			if keys[pygame.K_w]:
				keyboard_move[1] = 1

			if keys[pygame.K_s]:
				keyboard_move[2] = 1

			action = 0
			if keyboard_move[1] == 1:
				action = 2

			if keyboard_move[2] == 1:
				action = 1

			#print("action: ", action)

			#action = random.randint(0,2)
			obs, reward, done, _ = env.big_step(action)
			obs = np.reshape(obs, (128,128,3))
			obs = cv2.resize(obs, dsize=(640,640), interpolation=cv2.INTER_CUBIC)

			obs_surf = cv2.rotate(obs, cv2.ROTATE_90_COUNTERCLOCKWISE)
			obs_surf = cv2.flip(obs_surf, 0)
			surf = pygame.surfarray.make_surface(obs_surf)
			gameDisplay.blit(surf, (0, 0))
			pygame.display.update()

			step += 1

			end = time.time()
			#print(end - start)

	env.close()