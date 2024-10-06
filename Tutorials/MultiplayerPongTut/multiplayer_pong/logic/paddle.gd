extends Area2D

const MOTION_SPEED = 300

@export var left = false

var _motion = 0
var _you_hidden = false

@onready var _screen_size_y = get_viewport_rect().size.y

var timeout = true
var deltat = 0.01
var agent_action = [0.0]
var env_action = [0,0]
var action = 0
var process_count = 0
var resetting = false
var total_step = 0

func _process(delta):
	#print("total_step: ", total_step)	
	total_step += 1
	
	if process_count > 0:
		process_count -= 1
		
	if timeout == false and process_count == 0:
		get_parent()._observation_function(self)
		
	# Is the master of the paddle.
	if is_multiplayer_authority():
		if timeout == true and get_parent().start_game == true:
			get_parent().sem_physics.wait()
			if get_parent().mem.exists():
				
				get_parent().sem_action.wait()
				agent_action = get_parent().agent_action_tensor.read()
				env_action = get_parent().env_action_tensor.read()
				action = agent_action[0]
				
				if env_action[0] == 1 and self.name == "Player1":
					#print("env_action[0] == 1 and self.name == \"Player1\"")
					rpc("player2_reset")
					reset()
					get_tree().paused = true
					get_parent().game_over()
					
				if action == 0:
					_motion = 0.0
				elif action == 1:
					_motion = 1.0
				elif action == 2:
					_motion = -1.0
			else:
				_motion = Input.get_axis(&"move_up", &"move_down")
			
		if not _you_hidden and _motion != 0:
			_hide_you_label()

		_motion *= MOTION_SPEED

		# Using unreliable to make sure position is updated as fast as possible, even if one of the calls is dropped.
		set_pos_and_motion.rpc(position, _motion)
	else:
		if not _you_hidden:
			_hide_you_label()

	translate(Vector2(0, _motion * 0.03))

	# Set screen limits.
	position.y = clamp(position.y, 16, _screen_size_y - 16)

	if timeout == true and get_parent().start_game == true:
		if is_multiplayer_authority():
			process_count = 1
			timeout = false
			get_parent().sem_physics.post()


# Synchronize position and speed to the other peers.
@rpc("unreliable")
func set_pos_and_motion(pos, motion):
	position = pos
	_motion = motion


@rpc("any_peer", "call_local")
func player2_reset():
	#print("player2_reset()")
	reset()
	get_tree().paused = true
	self.get_parent().game_over()
	
		
func reset():
	position.y = _screen_size_y / 2.0
	_motion = 0.0


func _hide_you_label():
	_you_hidden = true
	get_node(^"You").hide()


func _on_paddle_area_enter(area):
	var height = self.get_node("Shape3D").shape.radius * 2
	var width = self.get_node("Shape3D").shape.height * 2 
	var bounce_scale = (position.y - area.position.y) / width / 2.0
	
	if is_multiplayer_authority():
		# Random for new direction generated checked each peer.
		area.bounce.rpc(left, bounce_scale)
