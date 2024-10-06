extends Area2D

@export var left = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	var shape = self.get_node("CollisionShape2D").get_shape()
	#print("shape: ", shape)
	
	var size = shape.get_size()
	#print("size: ", size)
	
	#var height = self.get_node("CollisionShape2D").shape.radius * 2
	#var width = self.get_node("CollisionShape2D").shape.height * 2 
	
	#print("position.y: ", position.y)
	#print("area.position.y: ", area.position.y)
	
	var bounce_scale = (area.position.y - 200) / 400 / 2.0
	#print("bounce_scale: ", bounce_scale)
	
	if is_multiplayer_authority():
		# Random for new direction generated checked each peer.
		area.bounce.rpc(left, bounce_scale)
