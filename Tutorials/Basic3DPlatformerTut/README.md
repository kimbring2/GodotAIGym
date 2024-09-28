# Basic3DPlatformerTut

This repo is branch of original **[GodotAIGym](https://github.com/lupoglaz/GodotAIGym)** to use the frame screen of 3D game as the input of Neural Network.

## Python Dependencies

1. GodotAIGym
2. Tensorflow
3. Tensorflow Probability
4. OpenCV
5. Gym

## How to run

1. First, you need to install the GodotAIGym module by following [instruction of master branch](https://github.com/lupoglaz/GodotAIGym).

2. Please test the [original agent of master branch](https://github.com/lupoglaz/GodotAIGym/tree/master/Tutorials/InvPendulumTut).

3. If you can install and run the master branch, try to run the example of this repo by using below command. Different from [DogdeCreepTut](https://github.com/kimbring2/GodotAIGym/tree/uint_type_update/Tutorials/DogdeCreepTut "DogdeCreepTut"), it is 3D game which requirmets more complex neural network model than 2D game.. It should start to run the environment and show game screen and gray scale image of that. 
   
   ```
   $ python env_test.py
   ```
   
   ![](images/image_1.png "env_test.py image")

4. If you can see the above image, try to train the agent using [Basic3DPlatformer_A2C_CNN_LSTM.ipynb](https://github.com/kimbring2/GodotAIGym/blob/uint_type_update/Tutorials/Basic3DPlatformerTut/Basic3DPlatformer_A2C_CNN_LSTM.ipynb "Basic3DPlatformer_A2C_CNN_LSTM.ipynb") file.

5. You can see the training progress by using the Tensorboard under the tensorboard folder.
   
   ```
   $ tensorboard --logdir=./tensorboard
   ```

<img src="images/reward_graph.png" width="400" title="tensorboard reward graph">

7. You can see also the agent start to collect the coin after few hours later.
   
   <img src="images/training_result.gif" width="400" title="training result">
