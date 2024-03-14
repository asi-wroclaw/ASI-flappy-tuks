extends Path2D

export (PackedScene) var waterTile
export (float) var waterTilesDistance=1975
export (float) var waterTileOffset=-2000

export (Array, PackedScene) var bergTemplates;
export (float) var startBergDistance=400;
export (float) var minBergDistance=200;
export (float) var bergDistanceIncrease=5;

export (float) var speed_randomization=100;

var bergDistance=startBergDistance

var lastWaterTileLocation=-700;

var lastBergLocation=500;

func _process(delta):
	bergDistance-=bergDistanceIncrease*delta
	if bergDistance<minBergDistance:
		bergDistance=minBergDistance
	
	var location=position.x+waterTilesDistance*1.5
	
	while location-lastWaterTileLocation>waterTilesDistance:
		lastWaterTileLocation+=waterTilesDistance
		spawn_new_water_tile(lastWaterTileLocation)
	
	while location-lastBergLocation>bergDistance:
		lastBergLocation+=bergDistance
		spawn_iceberg(lastBergLocation)

func spawn_new_water_tile(loc):
	var tile=waterTile.instance()
	
	tile.position=Vector2(loc,position.y-waterTileOffset)
	get_parent().add_child(tile)

func spawn_iceberg(position_x):
	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	
	$PathFollow2D.set_offset(randi())
	var direction = $PathFollow2D.rotation + PI / 2
	berg.position.x=position_x
	berg.position.y = $PathFollow2D.position.y
	
	direction += rand_range(-PI / 4, PI / 4)
	
	var velocity = Vector2(rand_range(-speed_randomization, speed_randomization), 0)
	berg.linear_velocity = velocity.rotated(direction)
	
	berg.rotation = rand_range(0, 2*PI);
	
	get_parent().add_child(berg)
