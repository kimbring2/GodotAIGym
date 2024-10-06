import os
import random
import gym
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Model, load_model
from tensorflow.keras.layers import Input, Dense, Lambda, Add, Conv2D, Flatten
from tensorflow.keras.optimizers import Adam, RMSprop
from tensorflow.keras import backend as K
import cv2
import threading
from threading import Thread, Lock
import time
import tensorflow_probability as tfp
from typing import Any, List, Sequence, Tuple

from pongMultiplayer import pongMultiplayerEnv

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'


tfd = tfp.distributions


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


mse_loss = tf.keras.losses.MeanSquaredError()


class A3CAgent:
    def __init__(self, env_name):
        self.env_name = env_name
        peer_port = "9000"
        peer_type = "client"
        ip_address = "127.0.0.1"
        GODOT_BIN_PATH = "./multiplayer_pong/pong_multi.x86_64"
        env_abs_path = "./multiplayer_pong/pong_multi.pck"
        self.env = pongMultiplayerEnv(exec_path=GODOT_BIN_PATH, env_path=env_abs_path, peer_type=peer_type, ip_address=ip_address, 
                                      turbo_mode=True)
        self.action_size = 3
        self.EPISODES, self.episode, self.max_average = 2000000, 0, -21.0 # specific for pong
        self.lock = Lock()
        self.lr = 0.0001

        self.ROWS = 64
        self.COLS = 64
        self.REM_STEP = 4

        # Instantiate plot memory
        self.scores, self.episodes, self.average = [], [], []
        self.state_size = (self.ROWS, self.COLS, self.REM_STEP)

        # Create Actor-Critic network model
        self.model = ActorCritic(action_space=self.action_size)
        self.optimizer = tf.keras.optimizers.Adam(self.lr)
        self.writer = tf.summary.create_file_writer("tensorboard")

    def act(self, state):
        # Use the network to predict the next action to take, using the model
        prediction = self.model(state, training=False)
        action = tf.random.categorical(prediction[0], 1).numpy()

        return action[0][0]

    def discount_rewards(self, rewards, next_state):
        # Compute the gamma-discounted rewards over an episode
        gamma = 0.95    # discount rate
        running_add = 0
        discounted_r = np.zeros_like(rewards)
        for i in reversed(range(0, len(rewards))):
            if rewards[i] != 0: # reset the sum, since this was a game boundary (pong specific!)
                running_add = 0

            running_add = running_add * gamma + rewards[i]
            discounted_r[i] = running_add

        if np.std(discounted_r) != 0.0:
            discounted_r -= np.mean(discounted_r) # normalizing the result
            discounted_r /= np.std(discounted_r) # divide by standard deviation

        return discounted_r

    def replay(self, states, actions, rewards, next_state):
        # reshape memory to appropriate shape for training
        states = np.vstack(states)

        # Compute discounted rewards
        discounted_r = self.discount_rewards(rewards, next_state)
        with tf.GradientTape() as tape:
            prediction = self.model(states, training=True)
            action_logits = prediction[0]
            values = prediction[1]

            advantages = discounted_r - np.stack(values)[:, 0]

            action_probs = tf.nn.softmax(action_logits)
            dist = tfd.Categorical(probs=action_probs)
            action_log_prob = dist.prob(actions)
            action_log_prob = tf.math.log(action_log_prob)

            actor_loss = -tf.math.reduce_mean(action_log_prob * advantages)

            critic_loss = mse_loss(values, np.vstack(discounted_r))
            critic_loss = tf.cast(critic_loss, 'float32')
            
            entropy_loss = dist.entropy()
            entropy_loss = tf.reduce_mean(entropy_loss)
            entropy_loss = -entropy_loss

            total_loss = actor_loss + 0.5 * critic_loss + 0.01 * entropy_loss

        grads = tape.gradient(total_loss, self.model.trainable_variables)
        self.optimizer.apply_gradients(zip(grads, self.model.trainable_variables))

    def PlotModel(self, score, episode):
        self.scores.append(score)
        self.episodes.append(episode)
        self.average.append(sum(self.scores[-50:]) / len(self.scores[-50:]))
        return self.average[-1]

    def GetImage(self, frame, image_memory):
        if image_memory.shape == (1,*self.state_size):
            image_memory = np.squeeze(image_memory)
    
        # croping frame to 80x80 size
        frame_cropped = frame[35:195:2, ::2,:]
        if frame_cropped.shape[0] != self.COLS or frame_cropped.shape[1] != self.ROWS:
            # OpenCV resize function
            frame_cropped = cv2.resize(frame, (self.COLS, self.ROWS), interpolation=cv2.INTER_CUBIC)
    
        # converting to RGB (numpy way)
        frame_rgb = 0.299*frame_cropped[:,:,0] + 0.587*frame_cropped[:,:,1] + 0.114*frame_cropped[:,:,2]
    
        # convert everything to black and white (agent will train faster)
        frame_rgb[frame_rgb < 50] = 0
        frame_rgb[frame_rgb >= 150] = 255
        
        # dividing by 255 we expresses value to 0-1 representation
        new_frame = np.array(frame_rgb).astype(np.float32) / 255.0
    
        # push our data by 1 frame, similar as deq() function work
        image_memory = np.roll(image_memory, 1, axis=2)
    
        # inserting new frame to free space
        image_memory[:,:,0] = new_frame
    
        return np.expand_dims(image_memory, axis=0)

    def reset(self):
        image_memory = np.zeros(self.state_size)
        obs = self.env.reset()
        obs = np.reshape(obs, (128,128,3))
        obs = np.array(obs).astype(np.uint8)
        obs = cv2.resize(obs, dsize=(64, 64), interpolation=cv2.INTER_CUBIC)
        
        for i in range(self.REM_STEP):
            state = self.GetImage(obs, image_memory)

        return state

    def step(self, action, image_memory):
        #next_obs, reward, done, info = self.env.step(action)
        next_obs, reward, done, _ = self.env.big_step(action)

        next_obs = np.reshape(next_obs, (128,128,3))
        next_obs = np.array(next_obs).astype(np.uint8)
        next_obs = cv2.resize(next_obs, dsize=(64, 64), interpolation=cv2.INTER_CUBIC)
        next_state = self.GetImage(next_obs, image_memory)

        return next_state, reward, done, _

    def train(self):
        state = self.reset()
        while self.episode < self.EPISODES:
            score, done, SAVING = 0, False, ''

            states, actions, rewards = [], [], []
            step = 0
            while not done:
                action = agent.act(state)
                next_state, reward, done, _ = self.step(action, state)
                
                states.append(state)
                actions.append(action)
                rewards.append(reward)

                score += reward
                state = next_state

                step += 1

            state = self.reset()
            #print("len(states): ", len(states))
            if len(states) >= 100:
                self.replay(states, actions, rewards, next_state)
            else:
                time.sleep(0.88)

            states, actions, rewards = [], [], []

            average = self.PlotModel(score, self.episode)
            
            if self.episode % 100 == 0:
                self.model.save_weights("model/multi_pong_client_{}.h5".format(self.episode))

            # saving best models
            if average >= self.max_average:
                self.max_average = average
                #self.save()
                SAVING = "SAVING"
            else:
                SAVING = ""

            #print("episode: {}/{}, score: {}, average: {} {}".format(self.episode, self.EPISODES, score, average, SAVING))
            with self.writer.as_default():
                tf.summary.scalar("client, average_reward", average, step=self.episode)
                self.writer.flush()
            
            if self.episode < self.EPISODES:
                self.episode += 1

        env.close()

    def test(self, Actor_name, Critic_name):
        self.load(Actor_name, Critic_name)
        for e in range(100):
            state = self.reset(self.env)
            done = False
            score = 0
            while not done:
                self.env.render()
                action = np.argmax(self.Actor.predict(state))
                state, reward, done, _ = self.step(action, self.env, state)
                score += reward
                if done:
                    print("episode: {}/{}, score: {}".format(e, self.EPISODES, score))
                    break

        self.env.close()


if __name__ == "__main__":
    env_name = 'PongDeterministic-v4'
    #env_name = 'Pong-v0'
    agent = A3CAgent(env_name)
    agent.train() # use as A3C