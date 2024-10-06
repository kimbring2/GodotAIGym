extends Area2D

const DEFAULT_SPEED = 200

var direction = Vector2.LEFT
var stopped = false
var _speed = DEFAULT_SPEED

@onready var _screen_size = get_viewport_rect().size

func _process(delta):
	#print("delta: ", delta)
	#_speed += 0.1
	
	# Ball will move normally for both players, even if it's sightly out of sync between them,
	# so each player sees the motion as smooth and not jerky.
	if not stopped:
		translate(_speed * 0.03 * direction)

	# Check screen bounds to make ball bounce.
	var ball_pos = position
	if (ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > _screen_size.y and direction.y > 0):
		direction.y = -direction.y

	if is_multiplayer_authority():
		# Only the master will decide when the ball is out in the left side (it's own side). This makes the game
		# playable even if latency is high and ball is going fast. Otherwise ball might be out in the other
		# player's screen but not this one.
		if ball_pos.x < 0:
			get_parent().update_score.rpc(false)
			_reset_ball.rpc(false)
	else:
		# Only the puppet will decide when the ball is out in the right side, which is it's own side. This makes
		# the game playable even if latency is high and ball is going fast. Otherwise ball might be out in the
		# other player's screen but not this one.
		if ball_pos.x > _screen_size.x:
			get_parent().update_score.rpc(true)
			_reset_ball.rpc(true)


@rpc("any_peer", "call_local")
func bounce(left, bounce_scale):
	# Using sync because both players can make it bounce.
	if left:
		direction.x = abs(direction.x)
	else:
		direction.x = -abs(direction.x)

	#_speed *= 1.1
	#print("random: ", random)
	
	#direction.y = random * 2.0 - 1
	#print("bounce_scale: ", bounce_scale)
	direction.y = bounce_scale * 2.0
	#direction.y = -abs(direction.y)
	direction = direction.normalized()


@rpc("any_peer", "call_local")
func stop():
	stopped = true


@rpc("any_peer", "call_local")
func _reset_ball(for_left):
	position = _screen_size / 2
	
	#var rng = RandomNumberGenerator.new()
	#position.x = _screen_size.x / 2
	#position.y = rng.randi_range(0, _screen_size.y)
	#position.y = _screen_size.y / 4
	
	if for_left:
		direction = Vector2.LEFT
	else:
		direction = Vector2.RIGHT
		
	_speed = DEFAULT_SPEED
