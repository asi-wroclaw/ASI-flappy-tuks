extends CanvasLayer

var you_died=false
var score=0
var delta_timer = 0
export (float) var score_update_interval
export (float) var score_multiplier
var time_to_show = 60

func _ready():
	$DiedText.hide()
	$WriteYourName.hide()
	$WrittenName.hide()

func died():
	you_died=true
	$DiedText.show()

func _process(delta):
	if you_died and time_to_show >= 0:
		if time_to_show == 0:
			$WriteYourName.show()
			$WrittenName.show()
		time_to_show -= 1
		return
	if not you_died:
		score+=delta*score_multiplier
	delta_timer += delta
	if (delta_timer > score_update_interval):
		delta_timer = 0
		$Scores.text="Score: " + str(int(score))
