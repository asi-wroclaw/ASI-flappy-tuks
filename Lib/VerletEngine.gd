extends Node2D

var debug_grid:=false
var debug_statistics:=false setget set_debug_statistics, get_debug_statistics
var __debug_hud
var vertex_process_time:=0.0
var connection_process_time:=0.0
var debug_grid_draw_time:=.0

#None->idicates non existing connection, it's processing is skipped, left after removing connection, left to not shirk arrays after removal, replaced with actual connection when new ones are added
#Linear->ideal spring, uses:
#	connection_elasticity
#SingleTreshlod->ideal spring with elasticity change after reaching certin treshold, uses:
#	connection_elasticity
#	connection_elasticity2
#	connection_elsaticy_treshold-> treshold for elasticity change, compered directyly with actual connection length
#	connection_elsaticy_offset-> substracted from final force to ensure continus function
#DoubleTresholdLinear-> elascity calculated similar to SingleTreshold, but uses 2 tresholds and scales it lineary beetwen them, uses:
#	connection_elastiticity
#	connection_elastiticity2
#	connection_elasticity_freshold-> treshold for elasticity change, compered directyly with actual connection length, if length smaller connection_elascity used
#	connection_elasticity_treshold2-> second treshold for elasticity change, comperad directyly with actual connection length, if length bigger then connection elascity2 used
#	connection_elasticity_offset-> cached treshold2-treshold, varaible access in godot is very expensive
enum Connection_types{#In critical parts of code values are used intead of Connection_types.[...], way faster.
	None=0,
	Linear=1,
	SingleTreshold=2					#treshold function based, ___---- function, diffrend elasticity after certain point
	DoubleTresholdLinear=3				#2 treshold linear, ____/----  function, elascity changes lineary beetwen certain points
}

var vertex_position:=PoolVector2Array()
var vertex_previous_position:=PoolVector2Array()
var vertex_friction:=PoolRealArray()					#-1.0 indicates no existing, value is actually 1.0-friction, multiplier for displacement
var vertex_gravity:=PoolVector2Array()

var connection_type:=PoolByteArray()
var connection_vertex1:=PoolIntArray()					#first vertex always have smaller id then corresponding second vertex. Speed up connection searching
var connection_vertex2:=PoolIntArray()
var connection_length:=PoolRealArray()
var connection_elasticity:=PoolRealArray()
var connection_elasticity2:=PoolRealArray()
var connection_elasticity_treshold:=PoolRealArray()
var connection_elasticity_treshold2:=PoolRealArray()
var connection_elasticity_offset:=PoolRealArray()

var free_vertexes=[]
var free_connections=[]

var default_gravity=Vector2(.0,9.8)

func _ready():
	z_index=1
	
	__debug_hud=CanvasLayer.new()
	__debug_hud.name="HUD"
	var label=Label.new()
	label.name="Label"
	__debug_hud.add_child(label)
	
	if debug_statistics:
		add_child(__debug_hud)
	
	var prop=ProjectSettings.get_setting("physics/Verlet/default_gravity")
	if prop is Vector2:
		default_gravity=prop
	prop=ProjectSettings.get_setting("physics/Verlet/debug_grid")
	if prop is bool:
		debug_grid=prop
	prop=ProjectSettings.get_setting("physics/Verlet/debug_statistics")
	if prop is bool:
		set_debug_statistics(prop)

#Add new vertex in given position. returns id of new vertex
#@param gravity Constant adder to vertex move formula. type: float: multiplier for default physics 2d gravity, Vector2: final gravity vector
#Warning not async
func add_vertex(position,friction:=.999,gravity=1.0):
	if typeof(gravity)==TYPE_REAL:
		gravity=default_gravity*gravity
	
	var id
	if free_vertexes.empty():
		id=vertex_position.size()
		
		vertex_position.append(position)
		vertex_previous_position.append(position)
		vertex_friction.push_back(friction)
		vertex_gravity.push_back(gravity)
	else:
		id=free_vertexes.pop_back()
		
		vertex_position[id]=position
		vertex_previous_position[id]=position
		vertex_friction[id]=friction
		vertex_gravity[id]=gravity
	
	return id

#Remove vertex with given id
func remove_vertex(id):
	vertex_friction[id]=-1.0
	free_vertexes.push_back(id)

#Add connection beetwen vertexes. Returns id of added connection
#@param length: if >0 used as connectio lengt else final_length=distance_beetwen_points*(-length)
#Warning not async
func add_linear_connection(vertex_id,vertex2_id,elasticity=1.0,length:=-1.0)-> int:
	return __add_connection(Connection_types.Linear,vertex_id,vertex2_id,elasticity,elasticity,.0,.0,.0,length)

#Add connection beetwen vertexes. Returns id of added connection
#@param treshold: float>.0, use to choose witch elasticity apply, if actual_lenght/normal_length>treshold elasticity2 is used
#@param length: if >0 used as connectio lengt else final_length=distance_beetwen_points*(-length)
#Warning not async
func add_single_treshold_connection(vertex_id,vertex2_id,elasticity=.5,elasticity2=.9,treshold=.5,length:=-1.0)-> int:
	if length<.0:
		length*=-vertex_position[vertex_id].distance_to(vertex_position[vertex2_id])
	
	treshold*=length
	
	var elasticity_offset=treshold*elasticity
	
	return __add_connection(Connection_types.SingleTreshold,vertex_id,vertex2_id,elasticity,elasticity2,treshold,.0,elasticity_offset,length)

func add_double_treshold_linear_connection(vertex_id,vertex2_id,elasticity=.5,elasticity2=.9,treshold=.5,treshold2=.9,length:=-1.0)-> int:
	if length<.0:
		length*=-vertex_position[vertex_id].distance_to(vertex_position[vertex2_id])
	
	treshold*=length
	treshold2*=length
	
	return __add_connection(Connection_types.DoubleTresholdLinear,vertex_id,vertex2_id,elasticity,elasticity2,treshold,treshold2,treshold2-treshold,length)

func __add_connection(type,vertex_id,vertex2_id,elasticity,elasticity2,elasticity_treshold,elasticity_treshold2,elasticity_offset,length)-> int:
	if length<.0:
		length*=-vertex_position[vertex_id].distance_to(vertex_position[vertex2_id])
	
	if vertex_id>vertex2_id:
		var swap=vertex_id
		vertex_id=vertex2_id
		vertex2_id=swap
	
	var id
	if free_vertexes.empty():
		id=connection_vertex1.size()
		
		connection_type.append(type)
		connection_vertex1.append(vertex_id)
		connection_vertex2.append(vertex2_id)
		connection_length.push_back(length)
		connection_elasticity.push_back(elasticity)
		connection_elasticity2.push_back(elasticity2)
		connection_elasticity_treshold.push_back(elasticity_treshold)
		connection_elasticity_treshold2.push_back(elasticity_treshold2)
		connection_elasticity_offset.push_back(elasticity_offset)
	else:
		id=free_connections.pop_back()
		
		connection_type[id]=type
		connection_vertex1[id]=vertex_id
		connection_vertex2[id]=vertex2_id
		connection_length[id]=length
		connection_elasticity[id]=elasticity
		connection_elasticity2[id]=elasticity2
		connection_elasticity_treshold[id]=elasticity_treshold
		connection_elasticity_treshold2[id]=elasticity_treshold2
		connection_elasticity_offset[id]=elasticity_offset
	
	return id

#Remove connection with given id
func remove_connection(id):
	connection_type[id]=Connection_types.None
	free_connections.push_back(id)

var accum_delta:=.0
var delta_treshold=.5
#var a=true
func _physics_process(delta):
#	accum_delta+=delta
#	if accum_delta<delta_treshold:
#		return
#	accum_delta-=delta_treshold
	
#	if a:
#		__process_vertex(delta)
#	else:
#		__process_connection(delta)
#	a=a!=true
	
	var time=OS.get_system_time_msecs()
	__process_vertex(delta)
	var time2=OS.get_system_time_msecs()
	vertex_process_time=vertex_process_time*.99+(time2-time)*.01
	__process_connection(delta)
	connection_process_time=connection_process_time*.99+(OS.get_system_time_msecs()-time2)*.01
	pass

func __process_vertex(delta):
	for id in range(0,vertex_position.size()):
		if vertex_friction[id]==-1:
			continue
		
		if vertex_friction[id]==0.0:				#static vertex
			vertex_position[id]=vertex_previous_position[id]
		else:
			var dis=vertex_position[id]-vertex_previous_position[id]
			vertex_previous_position[id]=vertex_position[id]
			var grav=vertex_gravity[id]
			grav.x*=delta
			grav.y*=delta
#			vertex_position[id]+=dis*vertex_friction[id]+grav
			vertex_position[id]+=(dis+grav)*vertex_friction[id]

func __process_connection(_delta):
	for id in range(0,connection_vertex1.size()):
		var con_type=connection_type[id]
		if con_type==0:
			continue
		
		var pos1=vertex_position[connection_vertex1[id]]
		var pos2=vertex_position[connection_vertex2[id]]
		
		var distance_vec=pos1-pos2			#TODO very small x can lead to big rounding error. Some ditortion visible on simulation dunno if it's this
		
		var length=distance_vec.length()
		
		var force: float
		if con_type==1:
			force=(length-connection_length[id])/2.0*connection_elasticity[id]
		elif con_type==2:
			if length<=connection_elasticity_treshold[id]:
				force=(length-connection_length[id])/2.0*connection_elasticity[id]
			else:
				force=((length-connection_length[id])*connection_elasticity2[id]-connection_elasticity_offset[id])/2.0
		elif con_type==3:
			if length<=connection_elasticity_treshold[id]:
				force=(length-connection_length[id])*connection_elasticity[id]/2.0
			elif length>=connection_elasticity_treshold2[id]:
				force=((length-connection_length[id])*connection_elasticity2[id])/2.0
			else:
				var interpolation=(length-connection_elasticity_treshold[id])/connection_elasticity_offset[id]
				force=(length-connection_length[id])/2.0*(connection_elasticity[id]*(1-interpolation)+connection_elasticity2[id]*interpolation)
		
		if distance_vec.x!=0:
			var sinn=distance_vec.x/length
			var tangent=distance_vec.y/distance_vec.x
			
			var dx=sinn*force
			var pos_delta=Vector2(dx,dx*tangent)
			
			vertex_position[connection_vertex1[id]]-=pos_delta
			vertex_position[connection_vertex2[id]]+=pos_delta
		else:
			if distance_vec.y<0:
				force*=-1
			vertex_position[connection_vertex1[id]].y-=force
			vertex_position[connection_vertex2[id]].y+=force

#<Service><Service><Service><Service><Service><Service><Service>
func remove_static_connections(var connection_array):
	if connection_array is Dictionary:
		connection_array=connection_array.values()
	
	var end=connection_array.size()
	var i=0
	while i<end:
		var con=connection_array[i]
		if vertex_friction[connection_vertex1[con]]==.0 and vertex_friction[connection_vertex2[con]]==.0:
			connection_array.remove(i)
			remove_connection(con)
			end-=1
			continue
		i+=1

#<Debug><Debug><Debug><Debug><Debug><Debug><Debug><Debug><Debug>
func _process(_delta):
	update()
	
	if debug_statistics:
		$HUD/Label.text="vertices:       %6d  %4.2fms\nconnections: %6d  %4.2fms"%[vertex_position.size()-free_vertexes.size(),vertex_process_time,connection_vertex1.size()-free_vertexes.size(),connection_process_time]
		if debug_grid:
			$HUD/Label.text+="\ngrid draw: %4.2fms"%debug_grid_draw_time
		$HUD/Label.text+="\nmouse position: %s"%get_global_mouse_position()

func set_debug_statistics(val):
	if debug_statistics==val:
		return
	debug_statistics=val
	if val:
		add_child(__debug_hud)
	else:
		remove_child(__debug_hud)
func get_debug_statistics():
	return debug_statistics

func _draw():
	if !debug_grid:
		return
	
	var time=OS.get_system_time_msecs()
	
	var rect=Rect2(.0,.0,4.0,4.0)
	
	for connection in range(connection_vertex1.size()):
		if connection_type[connection]!=0:
			draw_line(vertex_position[connection_vertex1[connection]], vertex_position[connection_vertex2[connection]], Color.green)
	
	for vertex in range(vertex_position.size()):
		if vertex_friction[vertex]!=-1.0:
			rect.position=vertex_position[vertex]-Vector2(2.0,2.0)
			if vertex_friction[vertex]==0:
				draw_rect(rect,Color.blue)
			else:
				draw_rect(rect,Color.red)
	
	debug_grid_draw_time=debug_grid_draw_time*.99+(OS.get_system_time_msecs()-time)*.01
