extends Node2D

export (Array, PackedScene) var bergTemplates;

export (float) var start_speed=150;
export (float) var speed_increase=10;
export (float) var speed_randomization=100;
export (float) var spawn_delay=3;
export (float) var min_spawn_delay=0.4;
export (float) var spawn_delay_change=8;

var speed=0;
var next_spawn_time=0;
var last_spawn_time_change;

var current_distance=0;

var maxTuxX=0;

func _init():
	speed=start_speed

# Called when the node enters the scene tree for the first time.
func _ready():
	last_spawn_time_change = Time.get_unix_time_from_system()
	current_distance=$Tuks.position.x

func get_spawning_cooldown():
	return 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	speed+=speed_increase*delta
	var curr_time = Time.get_unix_time_from_system()
	if next_spawn_time < curr_time:
		spawn_iceberg()
		next_spawn_time = curr_time + spawn_delay
		if last_spawn_time_change + spawn_delay_change < curr_time:
			spawn_delay -= 0.1
		if spawn_delay < min_spawn_delay:
			spawn_delay = min_spawn_delay
	
	var tuks_position=$Tuks.position.x
	if tuks_position>maxTuxX:
		$Shore.position.x=tuks_position+1000;
		$Shore2.position.x=tuks_position+1000;
	
 
func spawn_iceberg():
	$Shore.set_speed(speed)
	$Shore2.set_speed(speed)

	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	add_child(berg)
	
	$IcebergSpawnPath/PathFollow2D.set_offset(randi())
	var direction = $IcebergSpawnPath/PathFollow2D.rotation + PI / 2
	berg.position = $IcebergSpawnPath/PathFollow2D.position
	
	direction += rand_range(-PI / 4, PI / 4)
	
	var velocity = Vector2(rand_range(-speed_randomization, speed_randomization) - speed,
		rand_range(-speed_randomization, speed_randomization))
	berg.linear_velocity = velocity.rotated(direction)
	
	berg.rotation = rand_range(0, 2*PI);

func _on_Obstangle_Timer_timeout():
	pass
