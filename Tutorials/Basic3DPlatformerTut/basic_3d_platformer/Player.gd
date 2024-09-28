extends RigidBody3D
class_name Player

var mouse_sensitivity := 0.001 
var twist_input := 0.0 
var pitch_input := 0.0


@onready var twist_pivot := $TwistPivot 
@onready var pitch_pivot := $TwistPivot/PitchPivot 
@onready var label := $CanvasLayer/Label
@onready var character := $Character
@onready var animator := $AnimationTree
@onready var playback = animator["parameters/playback"]
var blend_path := "parameters/Run/blend_position"

var coin_count := 0:
	set(value):
		coin_count = value
		label.text = "Coins: " + str(coin_count)

var sem_action
var sem_observation
var sem_physics

var mem
var env_action_tensor
var agent_action_tensor
var observation_tensor
var reward_tensor
var done_tensor

var reward = 0
var done = 0

var timeout = true
var time_elapsed = 0.0
var prev_time = 0.0
var sem_delta = 0.0
var target_delta = 0.01

var agent_action = [0.0]
var env_action = [0,0]
var action = 0

var turbo_mode = false
var game_speed = 1
var deltat = 0.05
var first_start = true

var handle
var speed_scale = 1
var process_count = 0

var input := Vector3.ZERO

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
		#print("len(args): ", len(args))
		handle = args[1]
		
		sem_action = cSharedMemorySemaphore.new()
		sem_observation = cSharedMemorySemaphore.new()

		sem_action.init("sem_action_" + handle)
		sem_observation.init("sem_observation_" + handle)
		
		agent_action_tensor = mem.findFloatTensor("agent_action_" + handle)
		
		env_action_tensor = mem.findIntTensor("env_action_" + handle)
		reward_tensor = mem.findFloatTensor("reward_" + handle)
		observation_tensor = mem.findUintTensor("observation_" + handle)
		done_tensor = mem.findIntTensor("done_" + handle)
		
		print("Running as OpenAIGym environment")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	_reset()
	
	
func _reset():
	done = 0
	coin_count = 0
	
	position = Vector3(0, 1.468796, 0)
	
	var transform_origin = Transform3D()
	transform_origin.basis.x = Vector3(1, 0, 0)
	transform_origin.basis.y = Vector3(0, 1, 0)
	transform_origin.basis.z = Vector3(0, 0, 1)
	transform_origin.origin = Vector3(0, -0.901278, 0)
	character.transform = transform_origin

	get_parent()._clear_coins()

	get_parent()._add_coin("coin1", -4.681, 9.731)
	get_parent()._add_coin("coin2", 9.694, 12.097)
	get_parent()._add_coin("coin3", -11.072, 3.732)
	get_parent()._add_coin("coin4", -9.917, -6.651)
	get_parent()._add_coin("coin5", -3.806, -0.79)
	get_parent()._add_coin("coin6", -4.544, -9.752)
	get_parent()._add_coin("coin7", 9.384, -7.837)
	get_parent()._add_coin("coin8", 9.49, 5.216)
	get_parent()._add_coin("coin9", -10.221, 12.351)
	get_parent()._add_coin("coin10", 2.023, -5.001)
	
	$TwistPivot.rotation.x = 0
	$TwistPivot.rotation.y = 0
	$TwistPivot.rotation.z = 0
	
	#$TwistPivot/PitchPivot.rotation.x = 0
	#$TwistPivot/PitchPivot.rotation.y = 0
	#$TwistPivot/PitchPivot.rotation.z = 0
	
	
func _process(delta):
	if process_count > 0:
		process_count -= 1
		
	if timeout == false and process_count == 0:
		_observation_function()
	
	if timeout == true:
		sem_physics.wait()
		if mem.exists():
			sem_action.wait()
			
			agent_action = agent_action_tensor.read()
			env_action = env_action_tensor.read()
			
			#sprint("agent_action: ", agent_action)
			
			if env_action[0] == 1:
				if first_start == true:
					first_start = false
				else:
					done = 1
				
			if agent_action[2] <= 10:
				if agent_action[2] != 0:
					input.x = agent_action[2]
					input.z = 0
			
			if agent_action[3] <= 10:
				if agent_action[3] != 0:
					input.z = agent_action[3]
					input.x = 0
			
			if agent_action[4] == 1:
				if $RayCast3D.is_colliding(): 
					apply_central_impulse(Vector3.UP * 20.0)
					playback.start("Hop")
				
			if agent_action[0] <= 100:
				twist_input = -agent_action[0] * mouse_sensitivity
			
			if agent_action[1] <= 100:
				pitch_input = -agent_action[1] * mouse_sensitivity
				
			#input.x = Input.get_axis("move_left", "move_right")
			#input.z = Input.get_axis("move_forward", "move_back")
		else:
			var x_input = Input.get_axis("move_left", "move_right")
			var z_input = Input.get_axis("move_forward", "move_back") 
			
			if x_input != 0:
				input.x = Input.get_axis("move_left", "move_right") 
				input.z = 0
				
			if z_input != 0:
				input.z = Input.get_axis("move_forward", "move_back") 
				input.x = 0
	
		apply_central_force(twist_pivot.basis * input * 100.0) 
		
		if Input.is_action_just_pressed("ui_cancel"): 
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
			
			
		print("twist_input: ", twist_input)
		twist_pivot.rotate_y(twist_input)
		pitch_pivot.rotate_x(pitch_input) 
		pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(30)) 
		twist_input = 0 
		pitch_input = 0
		
		if not input.is_zero_approx():
			var move_direction = twist_pivot.basis * input
			var align = character.transform.looking_at(character.transform.origin - move_direction)
			var transform_result = character.transform.interpolate_with(align, 0.05 * 20.0)
			character.transform = character.transform.interpolate_with(align, 0.05 * 20.0)
			
		animator[blend_path] = lerp(animator[blend_path], input.length(), 0.05 * 5.0)
		get_tree().call_group("FootstepParticle", "set_emitting", animator[blend_path] > 0.5)
		
		process_count = 1
		timeout = false
		sem_physics.post()
		
		if done == 1:
			_reset()
		
		
func _unhandled_input(event): 
	if event is InputEventMouseMotion: 
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: 
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
			 
	if event.is_action_pressed("jump"): 
		if $RayCast3D.is_colliding(): 
			apply_central_impulse(Vector3.UP * 20.0)
			playback.start("Hop")
			

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
	
	
func _observation_function():
	sem_physics.wait()
	
	var return_values = _get_screen_frame()
	var observation = return_values
	
	if mem.exists():
		observation_tensor.write(observation)
		reward_tensor.write([reward])
		
		if reward == 1.0:
			reward = 0.0
		
		done_tensor.write([done])
		sem_observation.post()
		
	timeout = true
	sem_physics.post()
