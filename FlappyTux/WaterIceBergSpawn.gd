extends Path2D

export (PackedScene) var waterTile
export (float) var waterTilesDistance=1975
export (float) var waterTileOffset=-2000

var lastWaterTileLocation=-700;

func _process(delta):
	var location=position.x+waterTilesDistance*1.5
	
	while location-lastWaterTileLocation>waterTilesDistance:
		lastWaterTileLocation+=waterTilesDistance
		spawn_new_water_tile(lastWaterTileLocation)

func spawn_new_water_tile(loc):
	var tile=waterTile.instance()
	
	tile.position=Vector2(loc,position.y-waterTileOffset)
	get_parent().add_child(tile)
