extends Area2D

signal hit
signal coin

@export var speed = 300 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

var reset = false
var timeout = true
var deltat = 0.05
var time_elapsed = 0.0
var prev_time = 0.0
var sem_delta = 0.0
var target_delta = 0.025

var agent_action = [0.0]
var env_action = [0,0]
var action = 0

var process_count = 0

var velocity = Vector2.ZERO # The player's movement vector.


func _ready():
	screen_size = get_viewport_rect().size
	hide()


func new_game_player(score):
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$HUD.hide_game_over()
	

func update_score_player(score):	
	get_parent().score += 1
	
'''
func _physics_process(delta):
	#Engine.set_time_scale(4.0)
	#Engine.set_max_fps(240)
	if get_parent().mem.exists():
		var cur_time = Time.get_ticks_usec()
		var fps_est = 1000000.0 / (cur_time - prev_time - sem_delta)
		Engine.set_max_fps(fps_est)
		Engine.set_time_scale(Engine.get_max_fps() * target_delta)
		sem_delta = 0.0
		prev_time = cur_time
'''
		

func _process(delta):
	#print("check 1")
	#print("timeout: ", timeout)
	#print("process_count: ", process_count)
	
	if process_count > 0:
		process_count -= 1
		
	if timeout == false and process_count == 0:
		get_parent()._observation_Function()
		#$Timer.start(deltat)
	
	if timeout == true:
		get_parent().sem_physics.wait()
		
		if get_parent().mem.exists():
			var time_start = Time.get_ticks_usec()
			get_parent().sem_action.wait()
			var time_end = Time.get_ticks_usec()
			sem_delta = time_end - time_start
			
			##################################
			var cur_time = Time.get_ticks_usec()
			var fps_est = 1000000.0 / (cur_time - prev_time - sem_delta)
			
			#print("delta: ", delta)
			#print("fps_est: ", fps_est)
		
			var time_scale = fps_est * target_delta
			#print("time_scale: ", time_scale)
			#Engine.set_max_fps(fps_est)
			#print("30.0 / fps_est: ", 30.0 / fps_est)
			#Engine.set_time_scale(fps_est / 30.0)
			sem_delta = 0.0
			prev_time = cur_time
			#print("")
			##################################
			
			agent_action = get_parent().agent_action_tensor.read()
			env_action = get_parent().env_action_tensor.read()
			action = agent_action[0]
			
			if env_action[0] == 1:
				get_parent().new_game()
				#$HUD._on_StartButton_pressed()
			
			if action == 0:
				velocity.x = 1
				velocity.y = 0
				
			if action == 1:
				velocity.x = -1
				velocity.y = 0
				
			if action == 2:
				velocity.y = 1
				velocity.x = 0
				
			if action == 3:
				velocity.y = -1
				velocity.x = 0
		else:	
			if Input.is_action_pressed("move_right"):
				velocity.x = 1
				velocity.y = 0
			if Input.is_action_pressed("move_left"):
				velocity.x = -1
				velocity.y = 0
			if Input.is_action_pressed("move_down"):
				velocity.y = 1
				velocity.x = 0
			if Input.is_action_pressed("move_up"):
				velocity.y = -1
				velocity.x = 0
	
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
			$AnimatedSprite2D.play()
		else:
			$AnimatedSprite2D.stop()
	
		position += velocity * 0.05 * get_parent().speed_scale
		position.x = clamp(position.x, 0, screen_size.x)
		position.y = clamp(position.y, 0, screen_size.y)
	
		if velocity.x != 0:
			$AnimatedSprite2D.animation = "right"
			$AnimatedSprite2D.flip_v = false
			$AnimatedSprite2D.flip_h = velocity.x < 0
		elif velocity.y != 0:
			$AnimatedSprite2D.animation = "up"
			$AnimatedSprite2D.flip_v = velocity.y > 0
		
		process_count = 1
	
		#$Timer.start(deltat)
		timeout = false
		get_parent().sem_physics.post()


func _on_timer_timeout():
	#print("_on_Timer_timeout()")
	get_parent()._observation_Function()


func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false


func _on_Player_body_entered(_body):
	var height = self.get_node("CollisionShape2D").shape.radius * 2
	var width = self.get_node("CollisionShape2D").shape.height * 2 
	
	#hide() # Player disappears after being hit.
	if "Mob" in _body.name:
		hide()
		emit_signal("hit")
		
		## Must be deferred as we can't change physics properties on a physics callback.
		$CollisionShape2D.set_deferred("disabled", true)
	elif "coin" in _body.name:
		emit_signal("coin")
		get_parent().get_coin()
		_body.queue_free()
