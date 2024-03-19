class_name Simulation
extends Object

## Helper simulation functions

## mirror the tool and then do the difference and half of the result
## the difference is for another calculation run

static func calculate_lathe_linear_interpolation_result_part_df(machine: Machine, tool_start: Vector3, tool_end: Vector3):
	# tacka gde je zakacen pripremak u koord masine
	var fix_point = machine.chuck.chuck_mesh_instance.position
	fix_point = Vector2(fix_point.x, fix_point.y)

	var dw: DebugWindow = machine.get_node("../DebugWindow")

	var tool_start_2d = Vector2(tool_start.x, tool_start.y)
	var tool_end_2d = Vector2(tool_end.x, tool_end.y)

	var closer_point = tool_start_2d

	if tool_end_2d.distance_squared_to(fix_point) < tool_start_2d.distance_squared_to(fix_point):
		closer_point = tool_end_2d
	

	var part_poly: PackedVector2Array

	if machine.has_meta("clipped_part_result"):
		part_poly = machine.get_meta("clipped_part_result")
	else:
		var flat_part = projected(machine, machine.chuck.processed_part, machine.chuck.processed_part.mesh)

		for v in flat_part:
			part_poly.append(Vector2(v.x, v.y))
		part_poly = Geometry2D.convex_hull(part_poly)


	var tool_poly: PackedVector2Array

	if machine.has_meta("flat_tool"):
		tool_poly = machine.get_meta("flat_tool")
	else:
		var flat_tool = projected(machine, machine.tool.tool_mesh_instance, machine.tool.tool_mesh_instance.mesh)

		for v in flat_tool:
			tool_poly.append(Vector2(v.x, v.y))
		tool_poly = Geometry2D.convex_hull(tool_poly)

		machine.set_meta("flat_tool", tool_poly)


	print("#####")
	for p in tool_poly:
		print(p)
	print("#####")

	var extruded_tool_poly = extrude(tool_poly, 0, tool_end_2d)
	
	# for next operation
	var displaced_tool_poly = displace(tool_poly, 0, tool_end_2d)

	# take extruded tool poly and mirror it around the line at fix point height
	
	var mirrored_extruded_tool_poly = PackedVector2Array()
	for p in extruded_tool_poly:
		p.y = fix_point.y - ( p.y - fix_point.y )
		mirrored_extruded_tool_poly.append(p)
	
	var clipped_part = Geometry2D.clip_polygons(part_poly, extruded_tool_poly)[0]
	clipped_part = Geometry2D.clip_polygons(clipped_part, mirrored_extruded_tool_poly)[0]
	
	# var item = DebugItem.new()
	# item.polygons = [part_poly]
	# dw.add_debug_item("Part Poly", item)

	var item = DebugItem.new()
	item.polygons = [extruded_tool_poly, mirrored_extruded_tool_poly]
	dw.add_debug_item("Mirrored tool bre", item)
	
	item = DebugItem.new()
	item.polygons = [displaced_tool_poly]
	dw.add_debug_item("Displaced", item)
	
	# item = DebugItem.new()
	# item.polygons = [clipped_part]
	# dw.add_debug_item("Clipped new", item)

	var result
	if closer_point.y > fix_point.y:
		result = cutoff_part(clipped_part, fix_point, true)
	else:
		result = cutoff_part(clipped_part, fix_point, false)
	
	machine.set_meta("clipped_part_result", clipped_part)
	# machine.set_meta("tool_mesh_position", flat_part)

	return [extrudePartPolygon(machine, result, Vector3.DOWN, Vector3.UP), result, clipped_part, part_poly]

# returns vertices in machine coordinates
static func projected(machine: Machine, node: Node3D, mesh: Mesh) -> PackedVector3Array:
	var arr_mesh: ArrayMesh

	if mesh is ArrayMesh:
		arr_mesh = mesh
	else:
		arr_mesh = ArrayMesh.new()
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.get_mesh_arrays())

	var mdt = MeshDataTool.new()
	mdt.create_from_surface(arr_mesh, 0)

	var part_poly = PackedVector3Array()

	var A = Vector3.LEFT
	var B = Vector3.RIGHT

	for i in range(mdt.get_vertex_count()):
		# transform to machine coordinate system so we get rid of the Z axis
		var vertex = machine.to_local(node.to_global(mdt.get_vertex(i)))
		
		var result = vertex

		result.z = 0

		var pivot = Geometry3D.get_closest_point_to_segment_uncapped(vertex, A, B)

		var dist = pivot.distance_to(vertex)

		result.y = dist * sign(vertex.y)

		if result not in part_poly:
			part_poly.append(result)
	
	return part_poly

static func displace(polygon: PackedVector2Array, origin_index: int, to: Vector2) -> PackedVector2Array:
	var origin = polygon[origin_index]
	var offset = to - origin
	var displaced_polygon = PackedVector2Array([])
	
	for point in polygon:
		var moved = point + offset
		# displaced_polygon.append(point)
		displaced_polygon.append(moved)
	
	return Geometry2D.convex_hull(displaced_polygon)


static func extrude(polygon: PackedVector2Array, origin_index: int, to: Vector2) -> PackedVector2Array:
	var origin = polygon[origin_index]
	var offset = to - origin
	var extruded_polygon = PackedVector2Array([])
	
	for point in polygon:
		var moved = point + offset
		extruded_polygon.append(point)
		extruded_polygon.append(moved)
	
	return Geometry2D.convex_hull(extruded_polygon)


static func cutoff_part(polygon: PackedVector2Array, fix_point: Vector2, upper = true) -> PackedVector2Array:
	var intersected_polygon = polygon.duplicate()
	var half_poly = PackedVector2Array()

	# for i in range(polygon.size()-1):
	# 	var a = polygon[i]
	# 	var b = polygon[i+1 if i != polygon.size()-1 else 0]
	# 	var point = Geometry2D.segment_intersects_segment(a, b, fix_point * Vector2(-1000, 1), fix_point * Vector2(1000, 1))

	# 	# if point:
	# 	# 	intersected_polygon.insert(i+1, point)
		
	var compare = func(a, b): return a >= b if upper else a <= b

	for p in intersected_polygon:
		if compare.call(p.y, fix_point.y) or abs(p.y - fix_point.y) < 0.01:
			half_poly.append(p)
		else:
			half_poly.append(Vector2(p.x, fix_point.y))


		# if compare.call(p.y, fix_point.y) or abs(p.y - fix_point.y) < 0.01:
		# 	half_poly.append(p)

	# Geometry2D.convex_hull cant be used because it will return polygon with vertices that doesnt
	# necessary include all vertices, only those that construct a polygon that contains them all withing it
	return half_poly


static func extrudePartPolygon(machine: Machine, polygon: PackedVector2Array, pointA: Vector3, pointB: Vector3) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)

	for i in range(polygon.size()):
		# b is either next or first point if we reached the end
		var second_index = i+1 if i != polygon.size()-1 else 0

		var a = Vector3(polygon[i].x, polygon[i].y, 0)
		var b = Vector3(polygon[second_index].x, polygon[second_index].y, 0)

		a = machine.chuck.processed_part.to_local(machine.to_global(a))
		b = machine.chuck.processed_part.to_local(machine.to_global(b))
		
		for j in range(360):
			var pivot = Geometry3D.get_closest_point_to_segment_uncapped(a, pointA, pointB)
			var dir = a - pivot
			dir = Quaternion(pointA.direction_to(pointB), deg_to_rad(1)) * dir
			var c = dir + pivot
			
			pivot = Geometry3D.get_closest_point_to_segment_uncapped(b, pointA, pointB)
			dir = b - pivot
			dir = Quaternion(pointA.direction_to(pointB), deg_to_rad(1)) * dir
			var c1 = dir + pivot
			st.add_triangle_fan(PackedVector3Array([a, c, b]), PackedVector2Array([polygon[i], polygon[second_index], Vector2.ONE]), PackedColorArray([Color.BLUE, Color.BLUE, Color.BLUE]))

			st.add_triangle_fan(PackedVector3Array([c, c1, b]), PackedVector2Array([Vector2.ONE, Vector2.ONE, Vector2.ZERO]), PackedColorArray([Color.BLUE, Color.BLUE, Color.BLUE]))
			a = c
			b = c1
	
	st.generate_normals()
	
	return st.commit()

# same as above but adds step to y axis to look like a thread stuff idk...
static func extrudeThreadPolygon(machine: Machine, polygon: PackedVector2Array, pointA: Vector3, pointB: Vector3, step: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)

	for i in range(polygon.size()):
		# b is either next or first point if we reached the end
		var second_index = i+1 if i != polygon.size()-1 else 0

		var a = Vector3(polygon[i].x, polygon[i].y, 0)
		var b = Vector3(polygon[second_index].x, polygon[second_index].y, 0)

		a = machine.chuck.processed_part.to_local(machine.to_global(a))
		b = machine.chuck.processed_part.to_local(machine.to_global(b))
		
		for j in range(360):
			var pivot = Geometry3D.get_closest_point_to_segment_uncapped(a, pointA, pointB)
			var dir = a - pivot
			dir = Quaternion(pointA.direction_to(pointB), deg_to_rad(1)) * dir
			var c = dir + pivot
			c.y -= step
			
			pivot = Geometry3D.get_closest_point_to_segment_uncapped(b, pointA, pointB)
			dir = b - pivot
			dir = Quaternion(pointA.direction_to(pointB), deg_to_rad(1)) * dir
			var c1 = dir + pivot
			c1.y -= step

			st.add_triangle_fan(PackedVector3Array([a, c, b]), PackedVector2Array([polygon[i], polygon[second_index], Vector2.ONE]), PackedColorArray([Color.ORANGE_RED, Color.ORANGE_RED, Color.ORANGE_RED]))

			st.add_triangle_fan(PackedVector3Array([c, c1, b]), PackedVector2Array([Vector2.ONE, Vector2.ONE, Vector2.ZERO]), PackedColorArray([Color.ORANGE_RED, Color.ORANGE_RED, Color.ORANGE_RED]))
			
			a = c
			b = c1
	
	st.generate_normals()
	
	return st.commit()