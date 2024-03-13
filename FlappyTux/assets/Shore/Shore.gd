extends Node2D

export (Array, PackedScene) var bergTemplates
export (float) var bergsDistance=125
export (bool) var disabled=false

export (PackedScene) var snowTile
export (float) var snowTilesDistance=510
export (float) var snowTileYOffset=0;

var lastBergLocation=-700;
var lastSnowTileLocation=-700;

func _process(delta):
	var location=position.x
	
	while location-lastSnowTileLocation>snowTilesDistance and not disabled:
		lastSnowTileLocation+=snowTilesDistance
		spawn_new_snow_tile(lastSnowTileLocation)
		
	while location-lastBergLocation>bergsDistance and not disabled:
		lastBergLocation+=bergsDistance
		spawn_new_shore_berg(lastBergLocation)

func spawn_new_shore_berg(loc):
	var berg=bergTemplates[randi()%bergTemplates.size()].instance()
	berg.mode = RigidBody2D.MODE_STATIC
	
	get_parent().add_child(berg)
	
	#$IcebergSpawnPath/PathFollow2D.set_offset(randi())
	
	#berg.position = $IcebergSpawnPath/PathFollow2D.position
	berg.position=Vector2(loc,position.y)
	berg.rotation = rand_range(0, 2*PI);

func spawn_new_snow_tile(loc):
	var tile=snowTile.instance()
	
	get_parent().add_child(tile)

	tile.position=Vector2(loc,position.y+snowTileYOffset)
