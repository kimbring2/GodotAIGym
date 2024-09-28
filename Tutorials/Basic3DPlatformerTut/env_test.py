import gym
import numpy as np
import random
import matplotlib.pylab as plt
import cv2
import io 
import time

from Basic3DPlatformer import Basic3DPlatformer


ACTIONS = {
      'look_left': [-50, 0, 0, 0, 0],
      'look_right': [50, 0, 0, 0, 0],
      'strafe_left': [0, 0, -1, 0, 0],
      'strafe_right': [0, 0, 1, 0, 0],
      'forward': [0, 0, 0, 1, 0],
      'backward': [0, 0, 0, -1, 0]
}

'''
ACTIONS = []
for look_horizontal in [-100, 0, 100]:
    for look_vertical in [0]:
        for strafe_horizontal in [-1, 0, 1]:
            for strafe_vertical in [-1, 0, 1]:
              for jump in [0]:
                  ACTIONS.append([look_horizontal, look_vertical, strafe_horizontal, strafe_vertical, jump])
'''
#print("len(ACTIONS): ", len(ACTIONS))


if __name__ == '__main__':
	num_warmup = 1000
	num_train = 200000
	num_eval = 0
	buffer_length = 600000

	GODOT_BIN_PATH = "basic_3d_platformer/Basic3DPlatformer.x86_64"
	env_abs_path = "basic_3d_platformer/Basic3DPlatformer.pck"
	env_id = 0
	env = Basic3DPlatformer(exec_path=GODOT_BIN_PATH, env_path=env_abs_path, turbo_mode=False, env_id=env_id)

	num_states = env.observation_space.shape[0]
	num_actions = env.action_space.shape[0]

	#print("num_actions: ", num_actions)

	for episode in range(1000000):
		print("episode: ", episode)

		state = env.reset()
		step = 0
		reward_sum = 0
		start = time.time()
		while True:
			#print("step: ", step)

			#action = random.randint(0,6)

			# camera_horizontal, camera_vertical, forward_move, left_move, jump
			#action = [0, 0, 0, 0, 0]
			
			action_index = random.randint(0, len(ACTIONS) - 1)
			action_index = 0
			action_key = list(ACTIONS.keys())[action_index]
			action = ACTIONS[action_key]
			print("action: ", action)
			#action = [0, 0, 0, 0, 0]

			state_next, reward, done, _ = env.step(action)
			#print("reward: ", reward)
			#print("done: ", done)

			#state_next = state_next.detach().numpy()
			#state_next = np.reshape(state_next, (128,128,3))
			#print("state_next.shape: ", state_next.shape)
			#state_next = cv2.resize(state_next, (256, 256))
			#state_next = cv2.cvtColor(state_next, cv2.COLOR_BGR2RGB)
			#state_next = state_next.astype(np.uint8)
			#state_next = np.array(state_next).astype(np.float32) / 255.0
			#cv2.imshow("state_next: ", state_next)
			#if cv2.waitKey(25) & 0xFF == ord("q"):
			#	cv2.destroyAllWindows()

			#print("reward: ", reward)
			reward_sum += reward[0]
			#print("done: ", done)
			#print("")
			time.sleep(1.0)
			step += 1

			#print("done: ", done)
			#if done[0] == True or step == 200:
			if step == 500:
				print("step: ", step)
				print("reward_sum: ", reward_sum)
				end = time.time()
				print("elapsed time: ", end - start)
				print("")
				break
		
	env.close()
