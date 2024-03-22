extends RigidBody2D
# Tuks's speed and BoleslawBrama's speed aren't the same
# Should probably rename them in the future
export var speed=4000 
export var maxSpeed=4000; # Around 950 Boleslaw's speed
export (int) var max_drift_value=12000
export (float) var drift_cooldown=3

var screen_size
var game_over=false
var drift_timer = 0
var to_be_drift_value = {"x": 0, "y": 0}
var previous_drift_value = {"x": 0, "y": 0}

func _init():
	pass

func _ready():
#	hide()
	screen_size=get_viewport_rect().size
	set_contact_monitor(true)
	$DriftTimer.connect("timeout", self, "do_drift")

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
	
	vel.x-=Input.get_action_strength("joy_left")
	vel.x+=Input.get_action_strength("joy_right")
	vel.y+=Input.get_action_strength("joy_down")
	vel.y-=Input.get_action_strength("joy_up")
	
	if Input.is_action_pressed("brake") and false:
		vel.x = 0
		vel.y = 0
	
	vel=vel.normalized()
	
	linear_velocity+=vel*delta*speed;
	var currentSpeed=linear_velocity.length()
	if currentSpeed>maxSpeed:
		linear_velocity=linear_velocity.normalized()*maxSpeed
	handle_drift(delta)

func handle_friction():
	var friction=0.07
	if Input.is_action_pressed("brake"):
		friction=0.2
	
	linear_velocity += -linear_velocity*friction

func do_drift():
	previous_drift_value = to_be_drift_value

func handle_drift(delta):
	#return
	drift_timer += delta
	if (drift_timer > drift_cooldown):
		drift_timer = 0
		to_be_drift_value.x = randi() % max_drift_value - round(max_drift_value / 2)
		to_be_drift_value.y = randi() % max_drift_value - round(max_drift_value / 2)
		$DriftTimer.start()
		
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

func _on_RigidBody2D_body_entered(body):
	pass
	#hide()
	$CollisionShape2D.set_deferred("disabled",true)
	game_over=true
	$CPUParticles2D.set_emitting(true)
	
	$HUD.died()
