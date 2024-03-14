extends RigidBody2D

export var speed=4000
export var maxSpeed=4000;
export (int) var max_drift_value=12000

var screen_size
var game_over=false
var frame_count = 0
var previous_drift_value = {"x": 0, "y": 0}

func _ready():
#	hide()
	screen_size=get_viewport_rect().size
	set_contact_monitor(true)

func start(pos):
	position=pos
	show()
	$CollisionShape2D.disabled=false

func _process(delta):
	if(game_over):
		modulate.a -= 0.8*delta
		return;
		
	var vel=Vector2();
	
	if Input.is_action_pressed("ui_up"):
		vel.y=-1
	elif Input.is_action_pressed("ui_down"):
		vel.y=1
	if Input.is_action_pressed("ui_left"):
		vel.x=-1
	elif Input.is_action_pressed("ui_right"):
		vel.x=1
	
	linear_velocity+=vel*delta*speed;
	linear_velocity.x*lerp(linear_velocity.y,0,friction)
	var currentSpeed=linear_velocity.length()
	if currentSpeed>maxSpeed:
		linear_velocity=linear_velocity.normalized()*maxSpeed
	handle_drift(delta)

func handle_friction():
	linear_velocity += -linear_velocity*0.07

func handle_drift(delta):
	frame_count += 1
	if (frame_count % 180 == 0):
		previous_drift_value.x = randi() % max_drift_value - round(max_drift_value / 2)
		previous_drift_value.y = randi() % max_drift_value - round(max_drift_value / 2)
	else:
		previous_drift_value.x -= round(previous_drift_value.x / 16)
		previous_drift_value.y -= round(previous_drift_value.y / 16)
	if previous_drift_value.x != 0 and previous_drift_value.y != 0:
		linear_velocity.x += (randi() % int(previous_drift_value.x) - \
							previous_drift_value.x) * delta
		linear_velocity.y += (randi() % int(previous_drift_value.y) - \
							previous_drift_value.y) * delta

func _physics_process(delta):
	handle_friction()

#func _on_Tuks_body_entered(body):
#	print("collision")
#	hide()
#	$CollisionShape2D.set_deferred("disabled",true)
#	emit_signal("hit")

func _on_RigidBody2D_body_entered(body):
	pass
	#hide()
	$CollisionShape2D.set_deferred("disabled",true)
	game_over=true
	$CPUParticles2D.set_emitting(true)
