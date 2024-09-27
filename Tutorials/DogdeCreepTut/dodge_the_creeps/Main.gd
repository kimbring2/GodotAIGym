extends Node

var sem_action
var sem_observation
var sem_physics

var mem
var env_action_tensor
var agent_action_tensor
var observation_tensor
var reward_tensor
var done_tensor

var policy
var policy_action

@export var mob_scene: PackedScene
@export var coin_scene: PackedScene
var score

var reward = 0
var done = 0
var speed_scale = 4


func _ready():
	var args = Array(OS.get_cmdline_args())
	
	Engine.set_time_scale(speed_scale)
	Engine.set_max_fps(30 * speed_scale)
	Engine.set_physics_ticks_per_second(60 * speed_scale)
	Engine.set_max_physics_steps_per_frame(8 * speed_scale)
	
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
		print("Running as OpenAIGym environment")
		_clear_coins()
	else:
		_clear_coins()
		new_game()

	#randomize()
	#set_physics_process(true)
	

func game_over():
	reward = 0.0
	done = 1.0
	#_clear_coins()
	#new_game()

func _clear_coins():
	for n in $Coins.get_children():
		$Coins.remove_child(n)
		n.queue_free()


func get_coin():
	reward = 1.0
	$Player.update_score_player(score)
	$ScoreLabel.text = str(score)


func new_game():
	_clear_coins()
	
	score = 0
	$ScoreLabel.text = str(score)
	
	done = 0
	reward = 0.0
	
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("coins", "queue_free")
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
	_add_Coin(50, 250, 'coin1')
	_add_Coin(100, 100, 'coin2')
	_add_Coin(200, 450, 'coin3')
	_add_Coin(700, 100, 'coin4')
	_add_Coin(300, 300, 'coin5')
	_add_Coin(100, 700, 'coin6')
	_add_Coin(600, 250, 'coin7')
	_add_Coin(400, 50, 'coin8')
	_add_Coin(500, 700, 'coin9')
	_add_Coin(700, 700, 'coin10')
	

func _on_MobTimer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = get_node("MobPath/MobSpawnLocation")
	mob_spawn_location.offset = randi()

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Set the mob's position to a random location.
	mob.position = mob_spawn_location.position

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	
	
func _add_Coin(x, y, name):
	var coin = coin_scene.instantiate()
	coin.name = name
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spawn_height = rng.randi_range(10, 790)
	var spawn_width = rng.randi_range(10, 790)
	spawn_width = x
	spawn_height = y
	
	var position = Vector2(spawn_height, spawn_width)
	coin.position = position
	
	# Add some randomness to the direction.
	var direction = randf_range(-PI / 4, PI / 4)
	coin.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(0.0, 0.0), 0.0)
	coin.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	$Coins.add_child(coin)
	
	
func _on_CoinTimer_timeout():
	var coin = coin_scene.instantiate()

	#randomize()
	#var spawn_height = randi() % 600 + 1
	#var spawn_width = randi() % 600 + 1
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var spawn_height = rng.randi_range(0, 700)
	var spawn_width = rng.randi_range(0, 700)
	spawn_width = 260
	
	var position = Vector2(spawn_height, spawn_width)
	coin.position = position
	
	# Add some randomness to the direction.
	var direction = randf_range(-PI / 4, PI / 4)
	coin.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(0.0, 0.0), 0.0)
	coin.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(coin)


func _on_ScoreTimer_timeout():
	#score += 1
	#$HUD.update_score(score)
	#$Player.new_game_player(score)
	pass


func _on_StartTimer_timeout():
	#$MobTimer.start()
	#$CoinTimer.start()
	$ScoreTimer.start()
	#$Timer.start()
	$EndTimer.start()


func _get_screen_frame():
	# get data
	var time_start = Time.get_ticks_usec()
	
	var viewport = get_viewport()
	var texture = viewport.get_texture()
	
	var img = texture.get_image()
	var time_end = Time.get_ticks_usec()
	var sem_delta = time_end - time_start
	
	img.convert(4)
	img.resize(128, 128, 0)
	
	var height = img.get_height()
	var width = img.get_width()

	var img_pool_vector = img.get_data().duplicate()
	
	return img_pool_vector


func _observation_Function():
	#print("check 2")
	#print("")
	sem_physics.wait()
	
	var return_values = _get_screen_frame()
	var observation = return_values
	
	if mem.exists():
		observation_tensor.write(observation)
		reward_tensor.write([reward])
		if reward == 1.0:
			reward = 0
		
		done_tensor.write([done])
		sem_observation.post()
	
	$Player.timeout = true
	sem_physics.post()
	

func _on_end_timer_timeout():
	game_over()
	#pass
