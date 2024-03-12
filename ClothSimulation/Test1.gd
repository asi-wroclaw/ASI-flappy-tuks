extends Node2D

export (float) var rotation_speed=2.09

onready var used_node=$Polygon2D2

func _process(delta):
	used_node.position=get_global_mouse_position()
	
	var rotation:=.0
	if Input.is_action_pressed("rotate_right"):
		rotation+=rotation_speed
	if Input.is_action_pressed("rotate_left"):
		rotation-=rotation_speed
	
	used_node.rotate(rotation*delta)

func _unhandled_input(event):
	if event.is_action_pressed("debug_grid_toggle"):
		VerletEngine.debug_grid=VerletEngine.debug_grid!=true
	if event.is_action_pressed("node_change"):
		var nodes=get_children()
		var node_found=false
		for node in nodes:
			if !node is Polygon2D:
				continue
			
			if node_found:
				used_node=node
				node_found=false
				break
			if used_node==node:
				node_found=true
		if node_found:
			used_node=nodes[0]
