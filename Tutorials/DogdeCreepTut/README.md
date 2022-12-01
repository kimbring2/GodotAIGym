# DogdeCreepTut
This repo is branch of original GodotAIGym to use the frame screen as the input of Neural Network.

## Python Dependencies
1. ZeroMQ
2. GodotAIGym
4. Tensorflow 2.4.1
5. Tensorflow Probability 0.11.0
6. OpenCV
7. Gym

## How to run
1. First, you need to install the GodotAIGym module by following [instruction](https://github.com/kimbring2/GodotAIGym).
2. Please test the [tutorial of original](repo https://github.com/kimbring2/GodotAIGym/tree/master/Tutorials/InvPendulumTut).

3. If tutorial works, try to run the example of this repo by using below command. It should start to run the environment and show game screen and gray scale image of that. 
```
$ python env_test.py
```

<img src="images/image_1.png" width="400" title="env_test.py image">

4. If you can see the above image, try to train the agent using below command. It should start to run the 8 Godot games.
```
$ ./run_reinforcement_learning.sh 8
```

5. You can stop the training by using below command.
```
$ ./stop.sh
```

6. You can see the training progress by using the Tensorboard under the tensorboard folder.
```
$ tensorboard --logdir=./tensorboard
```

<img src="images/reward_graph.png" width="400" title="tensorboard reward graph">