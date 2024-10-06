import numpy as np
import cv2
import random
import time
from datetime import datetime
import os
from random import choice
from time import sleep
import tensorflow as tf
from tensorflow.keras.models import Model, load_model
from tensorflow.keras.layers import Input, Dense, Lambda, Add, Conv2D, Flatten
from pongMultiplayer import pongMultiplayerEnv

peer_port = "9000"
peer_type = "client"
ip_address = "127.0.0.1"
GODOT_BIN_PATH = "./multiplayer_pong/pong_multi.x86_64"
env_abs_path = "./multiplayer_pong/pong_multi.pck"
env = pongMultiplayerEnv(exec_path=GODOT_BIN_PATH, env_path=env_abs_path, peer_type=peer_type, ip_address=ip_address, 
						 turbo_mode=True)


class ActorCritic(tf.keras.Model):
    def __init__(self, action_space):
        super(ActorCritic, self).__init__()

        self.dense_0 = Dense(1024, activation='relu')
        self.dense_1 = Dense(1024, activation='relu')
        self.dense_2 = Dense(1024, activation='relu')
        self.dense_3 = Dense(1024, activation='relu')
        self.dense_4 = Dense(1024, activation='relu')
        self.policy = Dense(action_space)
        self.value = Dense(1)

    def call(self, state):
        state = Flatten()(state)

        dense_0 = self.dense_0(state)
        dense_1 = self.dense_1(dense_0)
        dense_2 = self.dense_2(dense_1)
        dense_3 = self.dense_3(dense_2)
        dense_4 = self.dense_4(dense_3)
        
        action_logit = self.policy(dense_4)
        value = self.value(dense_4)

        return action_logit, value


ROWS = 64
COLS = 64
REM_STEP = 4
state_size = (ROWS, COLS, REM_STEP)


def GetImage(frame, image_memory):
    if image_memory.shape == (1, *state_size):
        image_memory = np.squeeze(image_memory)

    frame_cropped = frame[35:195:2, ::2,:]
    if frame_cropped.shape[0] != COLS or frame_cropped.shape[1] != ROWS:
        frame_cropped = cv2.resize(frame, (COLS, ROWS), interpolation=cv2.INTER_CUBIC)

    frame_rgb = 0.299*frame_cropped[:,:,0] + 0.587*frame_cropped[:,:,1] + 0.114*frame_cropped[:,:,2]
    frame_rgb[frame_rgb < 50] = 0
    frame_rgb[frame_rgb >= 150] = 255
    
    new_frame = np.array(frame_rgb).astype(np.float32) / 255.0

    image_memory = np.roll(image_memory, 1, axis=2)
    image_memory[:,:,0] = new_frame

    return np.expand_dims(image_memory, axis=0)


action_size = 3
model = ActorCritic(action_space=action_size)
model.build(input_shape=(1,64,64,4))
model.load_weights("model/multi_pong_client_4000.h5")


if __name__ == '__main__':
	for episode in range(1000):
		print("episode: ", episode)

		obs = env.reset()
		obs = np.reshape(obs, (128,128,3))
		obs = np.array(obs).astype(np.uint8)
		obs = cv2.resize(obs, dsize=(64, 64), interpolation=cv2.INTER_CUBIC)
        
		image_memory = np.zeros(state_size)
		for i in range(REM_STEP):
			state = GetImage(obs, image_memory)

		reward_sum = 0
		for step in range(0, 500):
			start = time.time()
			#print("client, step: ", step)

			prediction = model(state, training=False)
			action = tf.random.categorical(prediction[0], 1).numpy()
			action = action[0][0]

			next_obs, reward, done, _ = env.big_step(action)
			next_obs = np.reshape(next_obs, (128,128,3))
			next_obs = np.array(next_obs).astype(np.uint8)
			next_obs = cv2.resize(next_obs, dsize=(64, 64), interpolation=cv2.INTER_CUBIC)
			next_state = GetImage(next_obs, state)

			state = next_state

			#time.sleep(0.02)

			end = time.time()
			#print(end - start)


	env.close()