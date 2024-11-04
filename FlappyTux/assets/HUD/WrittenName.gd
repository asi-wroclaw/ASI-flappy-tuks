extends RichTextLabel

var curr_acronym = ""
var max_acronym_length = 5
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
# _ _ _ _ _ 
func write_name():
	var temp_text = ""
	var curr_letter = 0
	while curr_letter < max_acronym_length:
		if curr_acronym.length() <= curr_letter:
			temp_text += "_ "
		else:
			temp_text += curr_acronym[curr_letter] + " "
		curr_letter += 1
	text = temp_text

func write_to_file():
	var file = File.new()
	if file.open("user://leaderboards.csv", File.WRITE) == OK:
		file.store_line("%s, %d \n" % [curr_acronym, get_parent().score])
	else:
		print('File reading eror, data:')
		print("%s, %d" % [curr_acronym, get_parent().score])



func write_character(letter_code: int):
	if letter_code == KEY_BACKSPACE:
		if curr_acronym == "":
			return
		curr_acronym[curr_acronym.length()-1] = ""
		write_name()
	if (letter_code > 48 and letter_code < 58) or (letter_code > 64 and letter_code < 90) \
		or (letter_code > 97 and letter_code < 122):
		if curr_acronym.length() >= max_acronym_length:
			return
		curr_acronym += OS.get_scancode_string(letter_code)
		write_name()
	if letter_code == KEY_ENTER:
		write_to_file()
		get_tree().quit()
		# get_tree().reload_current_scene() GOES BACK TO BEGINNING

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
