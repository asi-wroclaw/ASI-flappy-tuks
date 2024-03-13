extends Node2D

export (float) var gc_threshold=3000;

var next_spawn_time=0;
var last_spawn_time_change;

var maxTuxX=0;

var last_gc_run=0;

func _init():
	pass

func _ready():
	last_spawn_time_change = Time.get_unix_time_from_system()
	last_gc_run=Time.get_unix_time_from_system()

func get_spawning_cooldown():
	return 1

func _process(delta):
	gc()
	
	var tuks_position=$Tuks.position.x
	if tuks_position>maxTuxX:
		$Shore.position.x=tuks_position+1500;
		$Shore2.position.x=tuks_position+1500;
		$IcebergSpawn.position.x=tuks_position+1500;

func gc():
	var time=Time.get_unix_time_from_system()
	if(time-last_gc_run<10):
		return
	
	last_gc_run=time
	
	var gc_x=$Tuks.position.x-gc_threshold
	for child in get_children():
		if child.position.x < gc_x:
			child.queue_free()
