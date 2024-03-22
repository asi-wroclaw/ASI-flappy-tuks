extends Node2D

export (PackedScene) var levelPacked

var menuNodes=[]

func _ready():
	pass # Replace with function body.

func _on_Start_button_pressed():
	menuNodes.push_back($Background)
	menuNodes.push_back($Menu)
	
	remove_child($Background)
	remove_child($Menu)
	
	var level=levelPacked.instance()
	add_child(level)
