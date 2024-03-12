#Code documentation in VerletPolygon.md
extends Polygon2D

enum SortType{
	NONE=0,						#No sorting
	FORWARD=1,					#Left/Upper site last(drawed at top)
	BACKWARD=-1					#Right/Bottom site last(drawed at top)
}

#Make vertices with diffrend uv and polygon positions static
export (bool) var displaced_static=true
#Which vertices are static, if entry negative it's ignored during adding new static based on displacement
export (Array, int) var static_vertices=[]
#Subarray used in chained way - for [[1,2],[3,4,5]] adds 1,2 connections and 3,4 4,5 5,3 
export (Array, Array, int) var additional_connections=[]
#Sort polygons
export (SortType) var x_sort=SortType.FORWARD
export (SortType) var y_sort=SortType.FORWARD
export (int, 10) var interpolation_steps=1				#Waring each step increase computation time ~3 times
export (bool) var smooth_interpolation=true				#If adjust static vertices position during interpolation to make smooth line
#Connection types:
#None: c'mon why you would like to use this??
#Linear: constant elasticity connection.
#	fastest
#	uses:
#		strech_elasticity
#SingleTreshold: almost constant elasticity, changes immediately to other value after reaching certain treshold.
#	more realistic, can couse flickering
#	use with always moving cloth to hide flickering
#	uses:
#		compress_elasticity
#		strech_elasticity
#		strech_treshold
#DoubleTresholdLinear: changes elasticity lineary beetwen two tresholds.
#	like single treshold but without flickering, slowest
#	use in most important places
#	uses:
#		compress_elasticity
#		strech_elasticity
#		compress_treshold
#		strech_treshold
export (VerletEngine.Connection_types) var connections_type=VerletEngine.Connection_types.DoubleTresholdLinear
export (float,0,1.1) var compress_elasticity=.01
export (float,0,1.1) var strech_elasticity=.8
export (float,0,2) var compress_treshold=.9
export (float,0,2) var strech_treshold=1.1

var default_vertex_friction:=.99

var vertexes=PoolIntArray()
var connections={}							#[ver1, ver2]->con_id

func _ready():
	#displaced verices to static
	if displaced_static:
		for i in range(polygon.size()):
			if polygon[i]!=uv[i] and static_vertices.find(i)==-1 and static_vertices.find(-i):
				static_vertices.push_back(i)
	
	var n=static_vertices.size()
	var i:=0
	while i<n:
		if static_vertices[i]<0:
			static_vertices.remove(i)
			n-=1
		else:
			i+=1
	
	for _i in range(0,interpolation_steps):
		__interpolate_polygons()
	
	#Discard empty polygons
	if polygon.size()==0||polygons.size()==0:
		assert(false,"Invalid polygon2d you have to define vertexes/polygons")
		return
	
	#Vertexes from polygon
	for vertex in uv:
		vertexes.push_back(VerletEngine.add_vertex(__get_global_point_position(vertex),default_vertex_friction))
	
	#Connections from polygon
	for poly in polygons:
		for con in __get_polygon_connections(poly):
			__add_connection(vertexes[con[0]],vertexes[con[1]])
	
	var new_poly=[]
	#Triangelization
	for poly in polygons:
		match poly.size():
			3:
				new_poly.append(poly)
			4:
				new_poly.append([poly[0],poly[1],poly[2]])
				new_poly.append([poly[0],poly[2],poly[3]])
			_:
				new_poly.append(poly)
				
#				for i in range(1,poly.size()-1):
#					new_poly.append([poly[0],poly[i],poly[i+1]])
	
	polygons=new_poly
	
	#sort polygons
	if x_sort!=SortType.NONE or y_sort!=SortType.NONE:
		#Calculate polygon centers(vertexes position avarage) for sorting
		var polygons_center=PoolVector2Array()
		for poly in polygons:
			var pos=Vector2()
			for vertex in poly:
				pos+=VerletEngine.vertex_position[vertexes[vertex]]
			pos.x/=poly.size()
			pos.y/=poly.size()
			polygons_center.append(pos)
		
		var ready=false
		while !ready:								#Double way bubble sort
			ready=true
			for j in range(1,polygons.size()):
				if __sort_compare(polygons_center[j],polygons_center[j-1])<0:
					ready=false
					
					var swap=polygons_center[j]
					polygons_center[j]=polygons_center[j-1]
					polygons_center[j-1]=swap
					
					swap=polygons[j]
					polygons[j]=polygons[j-1]
					polygons[j-1]=swap
			for j in range(polygons.size()-1,0):
				if __sort_compare(polygons_center[i],polygons_center[j+1])>0:
					ready=false
					
					var swap=polygons_center[j]
					polygons_center[j]=polygons_center[j+1]
					polygons_center[j+1]=swap
					
					swap=polygons[j]
					polygons[j]=polygons[j+1]
					polygons[j+1]=swap
	
	#Custom connections
	if additional_connections!=static_vertices:					#Godot bug makes array pointer point to same aray if both teh same
		for poly in additional_connections:
			for con in __get_polygon_connections(poly):
				__add_connection(vertexes[con[0]],vertexes[con[1]])
	
	#Change pointed vertices to static
	for vertex in static_vertices:
		VerletEngine.vertex_friction[vertexes[vertex]]=.0
	
	#Calculate verticles "weight" based on local point density
#	var neighborhood_weight=PoolRealArray()
#	for vertex in vertexes:
#		var weight=1.0
#		for vertex2 in vertexes:
#			var distance=VerletEngine.vertex_position[vertex].distance_to(VerletEngine.vertex_position[vertex2])
#			if distance==0:
#				continue
#			weight+=1.0/distance
#		neighborhood_weight.append(weight*2.0)
#	var min_weight=neighborhood_weight[0]
#	for weight in neighborhood_weight:
#		if weight<min_weight:
#			min_weight=weight
#	for i in range(neighborhood_weight.size()):
#		neighborhood_weight[i]/=min_weight
#		VerletEngine.vertex_gravity[vertexes[i]]/=Vector2(neighborhood_weight[i],neighborhood_weight[i])
	
	for j in range(0,vertexes.size()):
		var pos=__get_global_point_position(polygon[j])
		VerletEngine.vertex_position[vertexes[j]]=pos
		VerletEngine.vertex_previous_position[vertexes[j]]=pos
	
	VerletEngine.remove_static_connections(connections)
	
#	displace_vertexes(32)

#Interpolate polygons, generate additional vertexes and polygons for better simalation details.
#Increases vertexes number ~2 times, polygons >4 times and connections for VerletEngine 3 times in each pass
#Details:
#traingle polygons: add new vertex in sites centers and from new triangle from them
#n-gon: add new vertex in sites centers and n-gon center(points avarage), from new 4-gon from corner, center, 2-sitescenters
func __interpolate_polygons():
	var new_polygons=[]
	var new_polygon=polygon
	var new_uv=uv
	
	var added_vertexes={}						#[pre_ver1,pre_ver2]:new_ver			pre_ver1<pre_ver2
	for i in range(0,polygons.size()):
		var poly=polygons[i]
		
		match poly.size():
			3:
				var new_ver=[]
				for con in __get_polygon_connections(poly):
					var vertex_id=added_vertexes.get(con)
					if vertex_id!=null:
						new_ver.push_back(vertex_id)
					else:
						var vertex=(polygon[con[0]]+polygon[con[1]])/Vector2(2,2)
						
						added_vertexes[con]=new_polygon.size()
						new_ver.push_back(new_polygon.size())
						
						new_polygon.append(vertex)
						new_uv.append((uv[con[0]]+uv[con[1]])/Vector2(2,2))
				
				new_polygons.push_back([poly[0],new_ver[1],new_ver[0]])
				new_polygons.push_back([poly[1],new_ver[2],new_ver[1]])
				new_polygons.push_back([poly[2],new_ver[0],new_ver[2]])
				new_polygons.push_back([new_ver[0],new_ver[1],new_ver[2]])
			_:
				var size=poly.size()
				var new_ver=[]
				
				var polygon_center=Vector2()
				var uv_center=Vector2()
				for vertex in poly:
					polygon_center+=polygon[vertex]
					uv_center+=uv[vertex]
				polygon_center/=Vector2(size,size)
				uv_center/=Vector2(size,size)
				
				var center=new_polygon.size()
				
				new_polygon.append(polygon_center)
				new_uv.append(uv_center)
				
				for con in __get_polygon_connections(poly):
					if con[0]>con[1]:
						var swap=con[0]
						con[0]=con[1]
						con[1]=swap
					
					var vertex_id=added_vertexes.get(con)
					if vertex_id!=null:
						new_ver.push_back(vertex_id)
					else:
						var vertex=(polygon[con[0]]+polygon[con[1]])/Vector2(2,2)
						
						added_vertexes[con]=new_polygon.size()
						new_ver.push_back(new_polygon.size())
						
						new_polygon.append(vertex)
						new_uv.append((uv[con[0]]+uv[con[1]])/Vector2(2,2))
				
				for j in range(size):
					new_polygons.push_back([poly[j],new_ver[(j+1)%size],center,new_ver[j]])
	
	#Make vertexes beetwen 2 static vertexes static
	for key in added_vertexes.keys():
		if static_vertices.find(key[0])!=-1 and static_vertices.find(key[1])!=-1:
			static_vertices.append(added_vertexes[key])
			
			if !smooth_interpolation:
				continue
			
			var poly_angle=(polygon[key[0]]-polygon[key[1]]).angle()
			if poly_angle<0:
				poly_angle+=PI
			
			var uv_angle=(uv[key[0]]-uv[key[1]]).angle()
			if uv_angle<0:
				uv_angle+=PI
			
			var angle2_delta=100.0
			var vertex2:=-1
			
			var angle3_delta=100.0
			var vertex3:=-1
			
			#Get closest(by uv and polygon angle sum) neightbours
			for poly in polygons:
				var poly_size=poly.size()
				
				var index=__find(poly,key[0])
				var index2=__find(poly,key[1])
				
				if index!=-1:
					for index3 in [index-1,index+1]:
						if index3<0:
							index3=poly_size-1
						elif index3==poly_size:
							index3=0
						
						if poly[index3]!=key[1] and __find(static_vertices,poly[index3])!=-1:
							var temp_angle=(uv[poly[index]]-uv[poly[index3]]).angle()
							if temp_angle<.0:
								temp_angle+=PI
							
							var angle_delta=abs(uv_angle-temp_angle)
							
							temp_angle=(polygon[poly[index]]-polygon[poly[index3]]).angle()
							if temp_angle<.0:
								temp_angle+=PI
							angle_delta+=abs(poly_angle-temp_angle)
							
							if angle_delta<angle2_delta:
								angle2_delta=angle_delta
								vertex2=poly[index3]
				
				if index2!=-1:
					for index3 in [index2-1,index2+1]:
						if index3<0:
							index3=poly_size-1
						elif index3==poly_size:
							index3=0
						
						if poly[index3]!=key[0] and __find(static_vertices,poly[index3])!=-1:
							var temp_angle=(uv[poly[index2]]-uv[poly[index3]]).angle()
							if temp_angle<.0:
								temp_angle+=PI
							
							var angle_delta=abs(uv_angle-temp_angle)
							
							temp_angle=(polygon[poly[index2]]-polygon[poly[index3]]).angle()
							if temp_angle<.0:
								temp_angle+=PI
							
							angle_delta+=abs(poly_angle-temp_angle)
							
							if angle_delta<angle3_delta:
								angle3_delta=angle_delta
								vertex3=poly[index3]
			
			if vertex2+vertex3==-2:
				continue
			
			var points=[vertex2,key[0],key[1],vertex3]
			var points_pos=[null,polygon[key[0]],polygon[key[1]],null]
			var uv_pos=[null,uv[key[0]],uv[key[1]],null]
			
			if points[0]!=-1:
				points_pos[0]=polygon[vertex2]
				uv_pos[0]=uv[vertex2]
			if points[3]!=-1:
				points_pos[3]=polygon[vertex3]
				uv_pos[3]=uv[vertex3]
			
			var poly_line=AnaliticGeometry.line(points_pos[1],points_pos[2])
			var poly_perpend=AnaliticGeometry.perpendicular(poly_line,AnaliticGeometry.middle_point(points_pos[1],points_pos[2]))
			
			var uv_line=AnaliticGeometry.line(uv_pos[1],uv_pos[2])
			var uv_perpend=AnaliticGeometry.perpendicular(uv_line,AnaliticGeometry.middle_point(uv_pos[1],uv_pos[2]))
			
			var poly_position:=Vector2()
			var uv_position:=Vector2()
			
			#TODO refactor, find nice way to use functional programing in godot script, following 4 blocks of code are the same except minor change in used variables
			if points[0]!=-1:
				var line2=AnaliticGeometry.line(points_pos[1],points_pos[0])
				if !AnaliticGeometry.parallel_raw(poly_line,line2):
					line2=AnaliticGeometry.perpendicular(line2,AnaliticGeometry.middle_point(points_pos[1],points_pos[0]))
					var cross_point=AnaliticGeometry.cross_point(poly_perpend,line2)
					
					var dis=AnaliticGeometry.distance(cross_point,points_pos[0])
					var new_pos=AnaliticGeometry.move_point(cross_point,poly_perpend,dis)
					var new_pos2=AnaliticGeometry.move_point(cross_point,poly_perpend,-dis)
					if AnaliticGeometry.line_point_distance(poly_line,new_pos)<AnaliticGeometry.line_point_distance(poly_line,new_pos2):
						poly_position+=new_pos
					else:
						poly_position+=new_pos2
				else:
					poly_position+=AnaliticGeometry.middle_point(points_pos[1],points_pos[2])
				
				line2=AnaliticGeometry.line(uv_pos[1],uv_pos[0])
				if !AnaliticGeometry.parallel_raw(uv_line,line2):
					line2=AnaliticGeometry.perpendicular(line2,AnaliticGeometry.middle_point(uv_pos[1],uv_pos[0]))
					var cross_point=AnaliticGeometry.cross_point(uv_perpend,line2)
					
					var dis=AnaliticGeometry.distance(cross_point,uv_pos[0])
					var new_pos=AnaliticGeometry.move_point(cross_point,uv_perpend,dis)
					var new_pos2=AnaliticGeometry.move_point(cross_point,uv_perpend,-dis)
					if AnaliticGeometry.line_point_distance(uv_line,new_pos)<AnaliticGeometry.line_point_distance(uv_line,new_pos2):
						uv_position+=new_pos
					else:
						uv_position+=new_pos2
				else:
					uv_position+=AnaliticGeometry.middle_point(uv_pos[1],uv_pos[2])
			
			if points[3]!=-1:
				var line2=AnaliticGeometry.line(points_pos[3],points_pos[2])
				if !AnaliticGeometry.parallel_raw(poly_line,line2):
					line2=AnaliticGeometry.perpendicular(line2,AnaliticGeometry.middle_point(points_pos[3],points_pos[2]))
					var cross_point=AnaliticGeometry.cross_point(poly_perpend,line2)
					
					var dis=AnaliticGeometry.distance(cross_point,points_pos[3])
					var new_pos=AnaliticGeometry.move_point(cross_point,poly_perpend,dis)
					var new_pos2=AnaliticGeometry.move_point(cross_point,poly_perpend,-dis)
					if AnaliticGeometry.line_point_distance(poly_line,new_pos)<AnaliticGeometry.line_point_distance(poly_line,new_pos2):
						poly_position+=new_pos
					else:
						poly_position+=new_pos2
				else:
					poly_position+=AnaliticGeometry.middle_point(points_pos[1],points_pos[2])
				
				line2=AnaliticGeometry.line(uv_pos[3],uv_pos[2])
				if !AnaliticGeometry.parallel_raw(uv_line,line2):
					line2=AnaliticGeometry.perpendicular(line2,AnaliticGeometry.middle_point(uv_pos[3],uv_pos[2]))
					var cross_point=AnaliticGeometry.cross_point(uv_perpend,line2)
					
					var dis=AnaliticGeometry.distance(cross_point,uv_pos[3])
					var new_pos=AnaliticGeometry.move_point(cross_point,uv_perpend,dis)
					var new_pos2=AnaliticGeometry.move_point(cross_point,uv_perpend,-dis)
					if AnaliticGeometry.line_point_distance(uv_line,new_pos)<AnaliticGeometry.line_point_distance(uv_line,new_pos2):
						uv_position+=new_pos
					else:
						uv_position+=new_pos2
				else:
					uv_position+=AnaliticGeometry.middle_point(uv_pos[1],uv_pos[2])
			
			if points[0]!=-1 and points[3]!=-1:
				poly_position/=Vector2(2,2)
				uv_position/=Vector2(2,2)
			
			var vertex_id=added_vertexes[key]
			
			new_polygon[vertex_id]=poly_position
			new_uv[vertex_id]=uv_position
	
	polygons=new_polygons
	polygon=new_polygon
	uv=new_uv

func __get_global_point_position(position)->Vector2:
	return position.rotated(global_rotation)+global_position
func __get_local_point_position(position)->Vector2:
	return (position-global_position).rotated(-global_rotation)

func __add_connection(vertex1, vertex2):
	var key=[vertex1,vertex2]
	if connections.get(key)!=null:
		return
	
	var con_id=-1
	if connections_type==1:
		con_id=VerletEngine.add_linear_connection(vertex1, vertex2, strech_elasticity)
	elif connections_type==2:
		con_id=VerletEngine.add_single_treshold_connection(vertex1, vertex2, compress_elasticity, strech_elasticity, strech_treshold)
	elif connections_type==3:
		con_id=VerletEngine.add_double_treshold_linear_connection(vertex1, vertex2, compress_elasticity, strech_elasticity, compress_treshold, strech_treshold)
	else:
		print("Unhandled connection type")
	
	if con_id!=-1:
		connections[key]=con_id

#shourtcut for getting connections in polygons
func __get_polygon_connections(polygon)->Array:
	var ret=[]
	
	ret.push_back([polygon[0],polygon[polygon.size()-1]])
	for i in range(1,polygon.size()):
		ret.push_back([polygon[i-1],polygon[i]])
	
	for i in range(0,ret.size()):
		if ret[i][0]>ret[i][1]:
			var swap=ret[i][0]
			ret[i][0]=ret[i][1]
			ret[i][1]=swap
	
	return ret

#returns inner id of connection beetwen points or -1 if not found
func __get_connection(vertex1,vertex2)->int:
	vertex1=vertexes[vertex1]
	vertex2=vertexes[vertex2]
	
	if vertex1>vertex2:
		var swap=vertex1
		vertex1=vertex2
		vertex2=swap
	
	for i in range(0,connections.size()):
		var connection=connections[i]
		
		var ver1=VerletEngine.connection_vertex1[connection]
		var ver2=VerletEngine.connection_vertex2[connection]
		
		if vertex1==ver1 and vertex2==ver2:
			return i
	
	return -1

#returns: ret==0: pos1==pos2 ret>0: pos1>pos2 ret<0: pos1<pos2. Comparision done according to setted sort rules
func __sort_compare(var pos1, var pos2)->float:
	return (pos2.x-pos1.x)*x_sort+(pos2.y-pos1.y)*y_sort

func __find(poolArray, value):
	for i in range(poolArray.size()):
		if poolArray[i]==value:
			return i
	return -1

#Move each non static vertex by random vector
func displace_vertexes(displacement):
	for vertex in vertexes:
		if VerletEngine.vertex_friction[vertex]!=0:
			VerletEngine.vertex_position[vertex]+=Vector2(rand_range(-displacement,displacement),rand_range(-displacement,displacement))
			VerletEngine.vertex_previous_position[vertex]+=Vector2(rand_range(-displacement,displacement),rand_range(-displacement,displacement))

onready var previus_global_position:=global_position
onready var previus_rotation:=global_rotation
func _physics_process(_delta):
	var position_delta=global_position-previus_global_position
	if position_delta.length()>.01:
		for vertex in static_vertices:
			VerletEngine.vertex_previous_position[vertexes[vertex]]+=position_delta
		previus_global_position=global_position
	
	var rotation_delta=global_rotation-previus_rotation
	if abs(rotation_delta)>.01:				#<1 deegre
		for vertex in static_vertices:
			VerletEngine.vertex_previous_position[vertexes[vertex]]=(VerletEngine.vertex_previous_position[vertexes[vertex]]-global_position).rotated(rotation_delta)+global_position
		previus_rotation=global_rotation
	
	for i in range(vertexes.size()):
		polygon[i]=__get_local_point_position(VerletEngine.vertex_position[vertexes[i]])
