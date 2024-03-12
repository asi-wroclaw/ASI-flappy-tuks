#Set of functions and class'es for analistic geometry
extends Node

const Vector_2_2=Vector2(2.0,2.0)

class Line:			#0=c+ax+by
	var a:float
	var b:float
	var c:float
	
	func _to_string():
		return "0=%.2fx+%.2fy+%.2f"%[a,b,c]

#Return Vector2 of location beetwen thoose 2 vectors
func middle_point(vec1:Vector2,vec2:Vector2)->Vector2:
	return (vec1+vec2)/Vector_2_2

#Return line beetwen these 2 points. It's "direction" is from vec1 to vec2
func line(vec1:Vector2,vec2:Vector2)->Line :
	var ret:=Line.new()
	
	var dis=vec1-vec2
	
	ret.a=dis.y
	ret.b=-dis.x
	
	ret.c=-ret.a*vec1.x-ret.b*vec1.y
	
	return ret

#Return line perpendicual to given line. Optionaly give point to make line wchich go thru it.
func perpendicular(line:Line,point=null)->Line:
	var ret:=Line.new()
	
	ret.a=line.b
	ret.b=-line.a
	
	if point!=null:
		ret.c=-ret.a*point.x-ret.b*point.y
	
	return ret

#return if given 2 lines are parallel, service function for avoiding dividing by 0, do not take into account rounding errors so most likeli true will be returned
func parallel_raw(line1:Line,line2:Line)->bool:
	return line1.a*line2.b-line1.b*line2.a==0

#Returns point ini wchich these 2 lines crosses or (0,0) if there are parallel, should not make program crash and allows func return type
func cross_point(line1:Line,line2:Line)->Vector2:
	if parallel_raw(line1,line2):
		return Vector2()
	
	if line1.a==0:			#line2.a can't be 0, beacouse othervise there are parallel
		var swap=line1
		line1=line2
		line2=swap
	
	var c=-line1.c/line1.a
	var b=-line1.b/line1.a
	
	var y=line2.b+line2.a*b
	c=line2.c+c*line2.a
	
	var ret=Vector2()
	ret.y=c/-y
	ret.x=(line1.c+line1.b*ret.y)/-line1.a
	
	return ret

func distance(point1:Vector2,point2:Vector2):
	return (point1-point2).length()

#Move point in direction indicated by line.
func move_point(point:Vector2,line:Line,distance:float)->Vector2:
	if line.b!=.0:
		var tg:=-line.a/line.b
		var sinn:=line.b/sqrt(line.a*line.a+line.b*line.b)
		
		var x=distance*sinn
		return point+Vector2(x,x*tg)
	else:
		return point-Vector2(0,distance*sign(line.a))

func line_point_distance(line:Line,point:Vector2)->float:
	return abs(line.a*point.x+line.b*point.y+line.c)/sqrt(line.a*line.a+line.b*line.b)

#func _ready():
#	var l1=line(Vector2(),Vector2(1,3))
#	var l2=line(Vector2(0,4),Vector2(4,0))
#
#	print(l1,"\n",l2)
#
#	l1=perpendicular(l1,Vector2())
#	l2=perpendicular(l2,Vector2(4,0))
#
#	print(l1,"\n",l2)
#
#	print("cross: ",cross_point(l1,l2))
