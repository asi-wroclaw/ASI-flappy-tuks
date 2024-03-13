extends Node2D

export (Array, PackedScene) var bergTemplates
export (float) var bergsDistance=150

var speed=0;

var lastBergLocation=0;

func _process(delta):
	var location=position.x
	
	while location-lastBergLocation>bergsDistance:
		lastBergLocation+=bergsDistance
		spawn_new_shore_berg(lastBergLocation)

func set_speed(speed_value):
	speed=speed_value

func spawn_new_shore_berg(loc):
	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	berg.mode = RigidBody2D.MODE_STATIC
	
	get_parent().add_child(berg)
	
	#$IcebergSpawnPath/PathFollow2D.set_offset(randi())
	
	#berg.position = $IcebergSpawnPath/PathFollow2D.position
	berg.position=Vector2(loc,0)
	berg.rotation = rand_range(0, 2*PI);
