extends Area3D

 
func _on_body_entered(body):
	if body.name == "Player":
		var parent_node = get_parent().get_parent().get_node("Player")
		#print("parent_node: ", parent_node)
		parent_node.reward = 1.0;
		
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "global_position", body.global_position, 0.2)
		tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
		tween.set_parallel(false)
		tween.tween_callback(
			func(): body.coin_count += 1
		)
		tween.tween_callback(queue_free)
