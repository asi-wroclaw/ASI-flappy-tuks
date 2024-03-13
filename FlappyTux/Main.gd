extends Node2D

export (Array, PackedScene) var bergTemplates;

export (float) var start_speed=150;
export (float) var speed_increase=10;
export (float) var speed_randomization=100;

var speed=0;

func _init():
	speed=start_speed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	speed+=speed_increase*delta

func _on_Obstangle_Timer_timeout():
	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	add_child(berg)
	
	$IcebergSpawnPath/PathFollow2D.set_offset(randi())
	var direction = $IcebergSpawnPath/PathFollow2D.rotation + PI / 2
	berg.position = $IcebergSpawnPath/PathFollow2D.position
	
	direction += rand_range(-PI / 4, PI / 4)
	berg.rotation = direction
	
	var velocity = Vector2(rand_range(-speed_randomization, speed_randomization) - speed,
		rand_range(-speed_randomization, speed_randomization))
	berg.linear_velocity = velocity.rotated(direction)
