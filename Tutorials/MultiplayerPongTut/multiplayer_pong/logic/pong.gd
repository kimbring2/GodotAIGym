extends Node2D

signal game_finished()

const SCORE_TO_WIN = 10

var score_left = 0
var score_right = 0

@onready var player2 = $Player2
@onready var score_left_node = $ScoreLeft
@onready var score_right_node = $ScoreRight
@onready var winner_left = $WinnerLeft
@onready var winner_right = $WinnerRight

var sem_action
var sem_observation
var sem_physics

var mem
var env_action_tensor
var agent_action_tensor
var observation_tensor
var reward_tensor
var done_tensor

var reward_left = 0
var reward_right = 0

var done_left = 0
var done_right = 0
var done = 0

var send_flag = 0
var start_game = false

func _ready():
	var args = Array(OS.get_cmdline_args())
	
	mem = cSharedMemory.new()
	sem_physics = Semaphore.new()
	sem_physics.post()
	if mem.exists():
		sem_action = cSharedMemorySemaphore.new()
		sem_observation = cSharedMemorySemaphore.new()

		sem_action.init("sem_action_" + args[1])
		sem_observation.init("sem_observation_" + args[1])
		
		agent_action_tensor = mem.findFloatTensor("agent_action_" + args[1])
		env_action_tensor = mem.findIntTensor("env_action_" + args[1])
		reward_tensor = mem.findFloatTensor("reward_" + args[1])
		observation_tensor = mem.findUintTensor("observation_" + args[1])
		done_tensor = mem.findIntTensor("done_" + args[1])
	
	# By default, all nodes in server inherit from master, while all nodes in clients inherit from puppet.
	# set_multiplayer_authority is tree-recursive by default.
	if multiplayer.is_server():
		# For the server, give control of player 2 to the other peer.
		start_game = true
		player2.set_multiplayer_authority(multiplayer.get_peers()[0])
	else:
		start_game = true
		# For the client, give control of player 2 to itself.
		player2.set_multiplayer_authority(multiplayer.get_unique_id())

	print("Unique id: ", multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func update_score(add_to_left):
	if add_to_left:
		score_left += 1
		score_left_node.set_text(str(score_left))
		
		reward_left = 1.0
		reward_right = -1.0
	else:
		score_right += 1
		score_right_node.set_text(str(score_right))
		
		reward_left = -1.0
		reward_right = 1.0

	var game_ended = false
	
	if game_ended:
		$ExitGame.show()
		$Ball.stop.rpc()
		

func reset_score():
	score_left = 0
	score_right = 0
	score_left_node.set_text(str(score_left))
	score_right_node.set_text(str(score_right))


func game_over():
	reward_left = 0.0
	reward_right = 0.0
	done = 1
	
	$Ball.rpc("_reset_ball", true)
	$Player1.reset()
	$Player2.reset()
	
	reset_score()
	
	rpc("reset_ended")
	
	
@rpc("any_peer", "call_local")
func reset_ended():
	#print("reset_ended()")
	get_tree().paused = false
	
	
func _on_exit_game_pressed():
	game_finished.emit()


func _get_screen_frame():
	# get data
	var viewport = get_viewport()
	var texture = viewport.get_texture()
	
	var img = texture.get_image()
	img.convert(4)
	img.resize(128, 128, 0)
	
	var height = img.get_height()
	var width = img.get_width()

	var img_pool_vector = img.get_data().duplicate()
	
	return img_pool_vector
	
	
func _observation_function(node):
	sem_physics.wait()
	
	var return_values = _get_screen_frame()
	var observation = return_values
	
	if mem.exists():
		observation_tensor.write(observation)
		
		if node.name == "Player1":
			reward_tensor.write([reward_left])
			if reward_left == 1.0 or reward_left == -1.0:
				reward_left = 0
		elif node.name == "Player2":
			reward_tensor.write([reward_right])
			if reward_right == 1.0 or reward_right == -1.0:
				reward_right = 0
		
		done_tensor.write([done])
		
		if done == 1:
			done = 0
		
		sem_observation.post()

	node.timeout = true
	sem_physics.post()
