extends Node2D


@onready var machine: Machine = get_parent()

var part_polygon_node = Polygon2D.new()
var tool_polygon_node = Polygon2D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
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


	# var dw: DebugWindow = machine.get_node("../DebugWindow")

	# var item = DebugItem.new()
	# item.polygons = [part_polygon_node.polygon, tool_polygon_node.polygon]
	# dw.add_debug_item("bree", item)

	print("Initialized Lathe Simulation Environment")


func calculate_lathe_linear_interpolation_result_part(tool_start: Vector3, tool_end: Vector3) -> ArrayMesh:
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


	tool_polygon_node.polygon = extruded_tool_poly

	var dw: DebugWindow = machine.get_node("../DebugWindow")

	var item = DebugItem.new()
	item.polygons = [part_polygon_node.polygon, extruded_tool_poly, mirrored_extruded_tool_poly]
	dw.add_debug_item("Mirrored", item)

	item = DebugItem.new()
	item.polygons = [clipped_part]
	dw.add_debug_item("Clipped Part", item)


	var result = Simulation.cutoff_part(clipped_part, fix_point, true)

	item = DebugItem.new()
	item.polygons = [result]
	dw.add_debug_item("Cuttof Part", item)

	tool_polygon_node.polygon = displaced_tool_poly
	part_polygon_node.polygon = clipped_part
	
	return Simulation.extrudePartPolygon(machine, result, Vector3.DOWN, Vector3.UP)

	# item = DebugItem.new()
	# item.polygons = [part_polygon_node.polygon, tool_polygon_node.polygon]
	# dw.add_debug_item("bree", item)
	
	# item = DebugItem.new()
	# item.polygons = [part_polygon_node.polygon, tool_polygon_node.polygon]
	# dw.add_debug_item("bree", item)