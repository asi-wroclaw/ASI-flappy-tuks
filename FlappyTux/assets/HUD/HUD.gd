extends CanvasLayer

var you_died=false
var score=0

func _ready():
	$DiedText.hide()

func died():
	you_died=true
	$DiedText.show()

func _process(delta):
	if not you_died:
		score+=delta
	
	$Scores.text="Score: "+str(int(score))
