extends RigidBody2D
#export (Vector3) var clor

# Called when the node enters the scene tree for the first time.
func _ready():
	#print($Iceberg.self_modulate)
		
	var green = 230
	var red = rand_range(170, green)
	var blue = rand_range(green, 255)
	get_node("Iceberg").modulate = Color( red / 255.0, green / 255.0, blue / 255.0, 1)
	#$Iceberg1.modulate = (Color(rand_range(88, 190),rand_range(77, 255),rand_range(250,255)))
	pass # Replace with function body.
