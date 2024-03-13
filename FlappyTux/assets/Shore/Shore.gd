extends Node2D

export (Array, PackedScene) var bergTemplates
export (float) var bergsDistance=150

var speed=0;

var lastBergLocation=0;
var location=0;

var currentBergs=Array()

func _process(delta):
	location+=speed*delta
	
	if location-lastBergLocation>bergsDistance:
		lastBergLocation=location
		spawn_new_shore_berg()
	
	print(currentBergs)
	
func _physics_process(delta):
	for berg in currentBergs:
		berg.position.x-=speed*delta;

func set_speed(speed_value):
	speed=speed_value

func spawn_new_shore_berg():
	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	berg.mode = RigidBody2D.MODE_STATIC
	
	add_child(berg)
	
	#$IcebergSpawnPath/PathFollow2D.set_offset(randi())
	
	#berg.position = $IcebergSpawnPath/PathFollow2D.position
	berg.position=Vector2(0,0)
	berg.linear_velocity = Vector2(0,0)	
	berg.rotation = rand_range(0, 2*PI);

	currentBergs.push_back(berg)
