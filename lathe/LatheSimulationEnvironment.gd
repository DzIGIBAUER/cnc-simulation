class_name LatheSimulationEnvironment
extends Node2D


var base_part_mesh = preload("res://part.tres")

# FIXME: not like this
@onready var tool_starting_position = Vector3(-0.028, 0.092, 0)

# TODO: use Global.machine instead
@onready var machine: Machine = get_parent()

var part_polygon_node = Polygon2D.new()
var tool_polygon_node = Polygon2D.new()

var part_material: Material

# Called when the node enters the scene tree for the first time.
func _ready():
	_project_meshes()

	# var dw: DebugWindow = machine.get_node("../DebugWindow")

	# var item = DebugItem.new()
	# item.polygons = [part_polygon_node.polygon, tool_polygon_node.polygon]
	# dw.add_debug_item("bree", item)

	print("Initialized Lathe Simulation Environment")


## Takes part and tool meshes and projects them to 2D polygons for simulation
func _project_meshes():
	# for mesh in machine.chuck.processed_part.meshes:
	# 	for v in Simulation.projected(machine, machine.chuck.processed_part, mesh):
	# 		part_poly.append(Vector2(v.x, v.y))

	var	flat_part = Simulation.projected(machine, machine.chuck.processed_part, machine.chuck.processed_part.mesh)	
	var part_poly = PackedVector2Array()
	for v in flat_part:
		part_poly.append(Vector2(v.x, v.y))
	part_polygon_node.polygon = Geometry2D.convex_hull(part_poly)


	var	flat_tool = Simulation.projected(machine, machine.tool.tool_mesh_instance, machine.tool.tool_mesh_instance.mesh)	
	var tool_poly = PackedVector2Array()
	for v in flat_tool:
		tool_poly.append(Vector2(v.x, v.y))
	tool_polygon_node.polygon = Geometry2D.convex_hull(tool_poly)



## Resets the simulation environment by reseting the part mesh, tool position and animation
func reset():
	Global.machine.simulation_animation.clear_animations()
	
	Global.machine.simulation_animation.animation.track_insert_key(
		Global.machine.simulation_animation.Tracks.PART,
		0,
		base_part_mesh,
		0
	)

	# Global.machine.tool.tool_mesh_instance.position = Global.machine.tool.tool_mesh_starting_position

	Global.machine.tool.tool_mesh_instance.position = Global.machine.reference_point.position
	
	print(Global.machine.tool.tool_mesh_instance.position)

	Global.machine.simulation_animation.animation.position_track_insert_key(
		Global.machine.simulation_animation.Tracks.TOOL,
		0,
		Global.machine.reference_point.position
	)

	# remove everything to clear the meshes
	# Global.machine.chuck.processed_part.clear_children()


	Global.machine.chuck.processed_part.mesh = base_part_mesh
	_project_meshes()

class SimulationResult extends RefCounted:
	var tool_positions: PackedVector3Array
	var mesh: ArrayMesh
	var waste_mesh: ArrayMesh



func calculate_lathe_linear_interpolation_result(tool_start: Vector3, tool_end: Vector3) -> SimulationResult:
	var tool_start_2d = Vector2(tool_start.x, tool_start.y)
	var tool_end_2d = Vector2(tool_end.x, tool_end.y)

	var extruded_tool_poly = Simulation.extrude(tool_polygon_node.polygon, 0, tool_end_2d)
	var displaced_tool_poly = Simulation.displace(tool_polygon_node.polygon, 0, tool_end_2d)


	var fix_point = machine.chuck.chuck_mesh_instance.position
	fix_point = Vector2(fix_point.x, fix_point.y)

	var mirrored_extruded_tool_poly = PackedVector2Array()
	for p in extruded_tool_poly:
		p.y = fix_point.y - ( p.y - fix_point.y )
		mirrored_extruded_tool_poly.append(p)
	

	# var merged_tool_polygon = Geometry2D.merge_polygons(extruded_tool_poly, mirrored_extruded_tool_poly)[0]

	var clipped_part = Geometry2D.clip_polygons(part_polygon_node.polygon, extruded_tool_poly)[0]
	clipped_part = Geometry2D.clip_polygons(clipped_part, mirrored_extruded_tool_poly)[0]
	
	# TODO: make this cleaner
	# clip_polygons can return multiple polygons
	# we need the upper one if the cutoff_part takes upper=true as third argument
	var clipped_waste: PackedVector2Array
	for poly in Geometry2D.clip_polygons(part_polygon_node.polygon, clipped_part):
		if not clipped_waste:
			clipped_waste = poly
		else:
			if poly[0].y > clipped_waste[0].y:
				clipped_waste = poly

	var dw = Global.debug_window
	
	var item = DebugItem.new()
	item.polygons = [clipped_part]
	dw.add_debug_item("Clipped", item)

	

	tool_polygon_node.polygon = extruded_tool_poly

	var cutoff_part = Simulation.cutoff_part(clipped_part, fix_point, true)
	var cutoff_waste = Simulation.cutoff_part(clipped_waste, fix_point, true)
	
	item = DebugItem.new()
	item.polygons = [clipped_waste]
	dw.add_debug_item("Waste BRE", item)
	
	item = DebugItem.new()
	item.polygons = [cutoff_part]
	dw.add_debug_item("Cutoff Part", item)

	tool_polygon_node.polygon = displaced_tool_poly
	part_polygon_node.polygon = clipped_part
	
	var result = SimulationResult.new()
	result.mesh = Simulation.extrudePartPolygon(machine, cutoff_part, Vector3.DOWN, Vector3.UP)
	result.waste_mesh = Simulation.extrudePartPolygon(machine, cutoff_waste, Vector3.DOWN, Vector3.UP)
	result.tool_positions = PackedVector3Array([tool_start, tool_end])

	return result




func calculate_lathe_circular_interpolation_result(tool_start: Vector3, tool_end: Vector3, radius: float, clockwise: bool = true) -> SimulationResult:
	var tool_start_2d = Vector2(tool_start.x, tool_start.y)
	var tool_end_2d = Vector2(tool_end.x, tool_end.y)

	print("tool_start: ", tool_start)
	print("tool_end: ", tool_end)

	var dw = Global.debug_window
	var item = DebugItem.new()
	
	var center = calculate_center_point_r(tool_start_2d, tool_end_2d, radius, clockwise)

	prints("CIRCLE:", tool_start, tool_end, center)
	
	var circle_points = calculate_circle_points(tool_start_2d, tool_end_2d, center, clockwise)

	var extruded_tool_poly = tool_polygon_node.polygon
	for point in circle_points:
		extruded_tool_poly = Simulation.extrude(extruded_tool_poly, 0, point)

	item = DebugItem.new()
	item.polygons = [tool_polygon_node.polygon, part_polygon_node.polygon]
	dw.add_debug_item("Displaced, Before", item)

	var displaced_tool_poly = Simulation.displace(tool_polygon_node.polygon, 0, tool_end_2d)

	var fix_point = machine.chuck.chuck_mesh_instance.position
	fix_point = Vector2(fix_point.x, fix_point.y)

	var mirrored_extruded_tool_poly = PackedVector2Array()
	for p in extruded_tool_poly:
		p.y = fix_point.y - ( p.y - fix_point.y )
		mirrored_extruded_tool_poly.append(p)

	var clipped_part = Geometry2D.clip_polygons(part_polygon_node.polygon, extruded_tool_poly)[0]
	clipped_part = Geometry2D.clip_polygons(clipped_part, mirrored_extruded_tool_poly)[0]

	# TODO: make this cleaner
	# clip_polygons can return multiple polygons
	# we need the upper one if the cutoff_part takes upper=true as third argument
	var clipped_waste: PackedVector2Array
	for poly in Geometry2D.clip_polygons(part_polygon_node.polygon, clipped_part):
		if not clipped_waste:
			clipped_waste = poly
		else:
			if poly[0].y > clipped_waste[0].y:
				clipped_waste = poly

	tool_polygon_node.polygon = extruded_tool_poly

	var cutoff_part = Simulation.cutoff_part(clipped_part, fix_point, true)
	var cutoff_waste = Simulation.cutoff_part(clipped_waste, fix_point, true)

	tool_polygon_node.polygon = displaced_tool_poly
	part_polygon_node.polygon = clipped_part


	item = DebugItem.new()
	item.polygons = [part_polygon_node.polygon, extruded_tool_poly]
	dw.add_debug_item("Extruded", item)
	
	item = DebugItem.new()
	item.polygons = [displaced_tool_poly, part_polygon_node.polygon]
	dw.add_debug_item("Displaced", item)
	
	item = DebugItem.new()
	item.polygons = [Utils.generate_circle_polygon(radius, 360, center)]
	dw.add_debug_item("Circle", item)
	
	item = DebugItem.new()
	item.polygons = [clipped_waste, cutoff_waste]
	dw.add_debug_item("Circle Waste", item)

	item = DebugItem.new()
	item.polygons = [cutoff_part]
	dw.add_debug_item("Circle Cutoff Part", item)

	var result = SimulationResult.new()
	result.mesh = Simulation.extrudePartPolygon(machine, cutoff_part, Vector3.DOWN, Vector3.UP)
	result.waste_mesh = Simulation.extrudePartPolygon(machine, cutoff_waste, Vector3.DOWN, Vector3.UP)
	result.tool_positions = PackedVector3Array([tool_start])

	for point in circle_points:
		result.tool_positions.append(Vector3(point.x, point.y, tool_start.z))

	result.tool_positions.append(tool_end)

	return result


func calculate_center_point_r(start: Vector2, end: Vector2, radius: float, clockwise: bool = true) -> Vector2:
	var midpoint = (start + end) / 2.0
	var d = start.distance_to(end)
	
	if abs(radius) < d/2:
		push_error("Radius too small")
		return midpoint
		
	var h = sqrt(pow(abs(radius), 2) - pow(d/2, 2))
	var direction = (end - start).rotated(PI/2).normalized()
	
	if (radius < 0 and clockwise) or (radius > 0 and not clockwise):
		direction = -direction
		
	return midpoint + direction * h


func calculate_circle_points(start: Vector2, end: Vector2, center: Vector2, clockwise: bool = true) -> PackedVector2Array:
	var circle_points = PackedVector2Array()
	var radius = center.distance_to(start)
	
	# Make points relative to center
	var rel_start = start - center
	var rel_end = end - center
	
	var angle = rel_start.angle_to(rel_end)
	if (clockwise and angle < 0) or (not clockwise and angle > 0):
		angle = -angle
		
	var angle_step = 0.1
	var steps = int(angle / angle_step)
	
	for i in range(steps + 1):
		var step_angle = angle * (float(i) / steps)
		var point = rel_start.rotated(step_angle) + center
		circle_points.append(point)
	

	var poly_string: String = ""
	for p in circle_points:
		if not poly_string.is_empty():
			poly_string += ","	
		
		poly_string += "(%s, %s)" % [p.x, p.y]

	print(rel_start.angle())
	print(rel_end.angle())

	print(start)
	print(end)
	print("polygon(%s)" % poly_string)

	return circle_points


func calculate_lathe_thread_result(tool_start: Vector3, tool_end: Vector3) -> SimulationResult:
	var tool_start_2d = Vector2(tool_start.x, tool_start.y)
	var tool_end_2d = Vector2(tool_end.x, tool_end.y)

	var extruded_tool_poly = Simulation.extrude(tool_polygon_node.polygon, 0, tool_end_2d)
	var displaced_tool_poly = Simulation.displace(tool_polygon_node.polygon, 0, tool_end_2d)


	var fix_point = machine.chuck.chuck_mesh_instance.position
	fix_point = Vector2(fix_point.x, fix_point.y)

	var mirrored_extruded_tool_poly = PackedVector2Array()
	for p in extruded_tool_poly:
		p.y = fix_point.y - ( p.y - fix_point.y )
		mirrored_extruded_tool_poly.append(p)
	

	# var merged_tool_polygon = Geometry2D.merge_polygons(extruded_tool_poly, mirrored_extruded_tool_poly)[0]

	var clipped_part = Geometry2D.clip_polygons(part_polygon_node.polygon, extruded_tool_poly)[0]
	clipped_part = Geometry2D.clip_polygons(clipped_part, mirrored_extruded_tool_poly)[0]
	
	# TODO: make this cleaner
	# clip_polygons can return multiple polygons
	# we need the upper one if the cutoff_part takes upper=true as third argument
	var clipped_waste: PackedVector2Array
	for poly in Geometry2D.clip_polygons(part_polygon_node.polygon, clipped_part):
		if not clipped_waste:
			clipped_waste = poly
		else:
			if poly[0].y > clipped_waste[0].y:
				clipped_waste = poly

	var dw = Global.debug_window
	
	var item = DebugItem.new()
	item.polygons = [clipped_part]
	dw.add_debug_item("Thread Clipped", item)

	

	tool_polygon_node.polygon = extruded_tool_poly

	var cutoff_part = Simulation.cutoff_part(clipped_part, fix_point, true)
	var cutoff_waste = Simulation.cutoff_part(clipped_waste, fix_point, true)
	
	item = DebugItem.new()
	item.polygons = [clipped_waste]
	dw.add_debug_item("Thread Waste BRE", item)

	tool_polygon_node.polygon = displaced_tool_poly
	part_polygon_node.polygon = clipped_part
	
	var result = SimulationResult.new()

	var existing = Simulation.extrudePartPolygon(machine, cutoff_part, Vector3.DOWN, Vector3.UP)
	result.mesh = Simulation.extrudeThreadPolygon(machine, cutoff_waste, Vector3.DOWN, Vector3.UP, 0, existing)

	result.waste_mesh = Simulation.extrudePartPolygon(machine, cutoff_waste, Vector3.DOWN, Vector3.UP)
	result.tool_positions = PackedVector3Array([tool_start, tool_end])

	return result
