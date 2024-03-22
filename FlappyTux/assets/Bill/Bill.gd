extends StaticBody2D

export (float) var startSpeed=200;
export (float) var maxSpeed=250;
export (float) var speedIncrease=25;

export (float) var closeTuksDistance=750;
export (float) var maxTuksDistance=2000;

var speed;

var tuks_position
var overspeed=0;

func _ready():
	speed = startSpeed

func _process(delta):
	speed+=speedIncrease*delta
	if speed>maxSpeed:
		speed=maxSpeed
	
	var dist=tuks_position.x-position.x
	if dist>maxTuksDistance:
		overspeed+=dist/5*delta
	elif dist<closeTuksDistance:
		overspeed/=8
	position.x+=(speed+overspeed)*delta;

func set_tuks_position(position):
	tuks_position=position
