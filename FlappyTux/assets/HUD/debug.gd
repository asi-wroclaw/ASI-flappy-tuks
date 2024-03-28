extends CanvasLayer
var tux_position
var boleslaw_position
var displayed_text
var disabled

func _ready():
	disabled = true
	
func update_count_line(curr_pos, line_name):
	var pos_text = "(%s), (%s)"
	pos_text = pos_text % [curr_pos.x, curr_pos.y]
	return line_name + ": " + pos_text
	
func count_objects(main_obj):
	var count = 0
	for child in main_obj.get_children():
		count += 1
	return count
	
func update_display(tux_obj, boleslaw_obj, main_obj):
	displayed_text = ""
	displayed_text += update_count_line(tux_obj.position, "Tux Position") + "\n"
	displayed_text += update_count_line(boleslaw_obj.position, "Boleslaw Position") + "\n"
	displayed_text += "Boleslaw Speed: " + String(round(boleslaw_obj.speed)) + "\n"
	displayed_text += "Object Count: " + String(count_objects(main_obj))
	
	if disabled:
		$DebugOutput.text = ""
		return
	$DebugOutput.text = displayed_text
	

func _physics_process(delta):
	var main_obj = get_parent().get_parent()
	update_display(get_parent(), \
					main_obj.get_node("BoleslawBrama"), 
					main_obj)
