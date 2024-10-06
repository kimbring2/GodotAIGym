import gym
import numpy as np
import random
import matplotlib.pylab as plt
import cv2
import io
import time

from pongMultiplayer import pongMultiplayerEnv

if __name__ == '__main__':
	num_warmup = 1000
	num_train = 200000
	num_eval = 0
	buffer_length = 600000

	peer_port = "9000"
	peer_type = "client"
	ip_address = "127.0.0.1"
	GODOT_BIN_PATH = "./multiplayer_pong/pong_multi.x86_64"
	env_abs_path = "./multiplayer_pong/pong_multi.pck"
	env = pongMultiplayerEnv(exec_path=GODOT_BIN_PATH, env_path=env_abs_path,
							 peer_type=peer_type, ip_address=ip_address)

	num_states = env.observation_space.shape[0]
	num_actions = env.action_space.shape[0]

	#print("num_actions: ", num_actions)

	for episode in range(1000):
		print("episode: ", episode)

		state = env.reset()
		step = 0
		reward_sum = 0
		start = time.time()
		while True:
			action = random.randint(0,2)
			#action = 0
			#print("action: ", action)

			#state_next, reward, done, _ = env.step(action)
			state_next, reward, done, _ = env.big_step(action)

			if reward != 0:
				print("reward: ", reward)

			reward_sum += reward
			#state_next = state_next.detach().numpy()
			#print("state_next: ", state_next)
			#print("reward: ", reward)
			#print("done: ", done)

			state_next = np.reshape(state_next, (128,128,3))
			#state_next = state_next.astype(np.uint8)
			#state_next = cv2.resize(state_next, dsize=(84,84), interpolation=cv2.INTER_CUBIC)
			#state_next = 0.299*state_next[:,:,0] + 0.587*state_next[:,:,1] + 0.114*state_next[:,:,2]
			#state_next[state_next < 100] = 0
			#state_next[state_next >= 150] = 255
			#state_next = np.array(state_next).astype(np.float32) / 255.0

			#state_next = np.array(state_next).astype(np.float32)
			#state_next = cv2.cvtColor(state_next, cv2.COLOR_BGR2RGB)
			#state_next = state_next.astype(np.uint8)
			#state_next = cv2.resize(state_next, (80, 80), interpolation=cv2.INTER_CUBIC)
			#state_next = 0.299*state_next[:,:,0] + 0.587*state_next[:,:,1] + 0.114*state_next[:,:,2]

			# convert everything to black and white (agent will train faster)
			#state_next[state_next < 70] = 0
			#state_next[state_next >= 100] = 255

			#state_next = np.array(state_next).astype(np.float32) / 255.0
			#state_next = state_next / 255.0

			cv2.imshow("state_next client: ", state_next)
			if cv2.waitKey(25) & 0xFF == ord("q"):
				cv2.destroyAllWindows()

			#print("sleep b")
			#time.sleep(1.0)
			#print("sleep a")
			step += 1

			#print("done: ", done)
			#if done[0] == True:
			if step == 500:
				print("step: ", step)
				print("reward_sum: ", reward_sum)
				end = time.time()
				print("elapsed time: ", end - start)
				print("")

				break
		
	env.close()
