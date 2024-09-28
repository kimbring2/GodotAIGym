extends Node3D

const CoinResource = preload("res://coin.tscn")

func _clear_coins():
	for n in $Coins.get_children():
		$Coins.remove_child(n)
		n.queue_free()


func _add_coin(name, x, y):
	var CoinInstance = CoinResource.instantiate()
	
	#You could now make changes to the new instance if you wanted
	CoinInstance.name = name
	
	CoinInstance.position = Vector3(x, -1.0, y)
	
	#Attach it to the tree
	$Coins.add_child(CoinInstance)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
