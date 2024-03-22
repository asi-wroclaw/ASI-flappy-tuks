extends Node2D

func _ready():
	pass # Replace with function body.

func handle_input() -> Vector2:
	var vel = Vector2()
	
	if Input.is_action_pressed("ui_up"):
		vel.y=-1
	elif Input.is_action_pressed("ui_down"):
		vel.y=1
	if Input.is_action_pressed("ui_left"):
		vel.x=-1
	elif Input.is_action_pressed("ui_right"):
		vel.x=1
	
	vel.x-=Input.get_action_strength("joy_left")
	vel.x+=Input.get_action_strength("joy_right")
	vel.y+=Input.get_action_strength("joy_down")
	vel.y-=Input.get_action_strength("joy_up")
	
	if Input.is_action_pressed("brake") and false:
		vel.x = 0
		vel.y = 0
	return vel
