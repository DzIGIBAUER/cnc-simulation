extends Node3D

@onready var poly: Polygon2D = get_node("Polygon2D")
@onready var poly2: Polygon2D = get_node("Polygon2D2")
@onready var poly3: Polygon2D = get_node("Polygon2D3")

func _process(delta):
	if Input.is_action_just_released("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE
		$DebugWindow.visible = !$DebugWindow.visible

# Called when the node enters the scene tree for the first time.
func _ready():

	# var msh = $Machine/Chuck/MeshInstance3D/MeshInstance3D

	# var ts = Vector3(0, 0.4, -0)
	# var te = Vector3(-0.4, 0.4, -0)

	# var results = Simulation.calculate_linear_interpolation_result_part($Machine, ts, te)

	# poly.polygon = results[1]
	# poly2.polygon = results[2]
	# poly3.polygon = results[3]
	
	# msh.mesh = results[0]
	
	
	# # # poly2.polygon = Simulation.extrude(results[1], 0, Vector2(-1, 0))

	# # # # poly3.polygon = Simulation.cutoff_part(Geometry2D.clip_polygons(poly.polygon, poly2.polygon)[0], Vector2(-1, 0.5))


	# # msh.mesh = Simulation.extrudePartPolygon($Machine, Geometry2D.clip_polygons(poly.polygon, poly2.polygon)[0], Vector3.DOWN, Vector3.UP)
	# msh.mesh = Simulation.extrudePartPolygon($Machine, Geometry2D.clip_polygons(poly.polygon, poly2.polygon)[0], Vector3.DOWN, Vector3.UP)

	# var ppp = Geometry2D.clip_polygons(poly.polygon, poly2.polygon)[0]
	# var plg = []
	# for p in ppp:
	# 	plg.append(($Machine as Machine).chuck.processed_part.to_local(($Machine as Machine).to_global(Vector3(p.x, p.y, 0))))

	# var pf = []
	# for p in plg:
	# 	pf.append(Vector2(p.x, p.y))
	
	# poly3.polygon = pf

	# msh.mesh = Simulation.extrudePartPolygon($Machine, pf, Vector3.DOWN, Vector3.UP)



	# var tl = ($Machine as Machine).tool

	# poly.polygon = Simulation.flat(msh.mesh, Vector3.LEFT, Vector3.RIGHT)

	# var tool_flat = Simulation.flat(tl.tool_mesh_instance.mesh, Vector3.LEFT, Vector3.RIGHT, Vector3.UP)
	# tool_flat = Simulation.extrude(tool_flat, 0, Vector2(-3, 0))
	# print(tool_flat)
	
	# msh.mesh = Simulation.extrudeAround(Geometry2D.clip_polygons(poly.polygon, tool_flat)[0], Vector3.DOWN, Vector3.UP)
	# msh.mesh = Simulation.extrudeAround(poly.polygon, Vector3.DOWN, Vector3.UP)
	
	var machine: Machine = $Machine

	# var arr_mesh = Simulation.extrudeThreadPolygon(machine, $Polygon2D2.polygon, Vector3.DOWN, Vector3.UP, 0.01)
	# var arr_mesh2 = Simulation.extrudePartPolygon(machine, machine.simulation_environment.part_polygon_node.polygon, Vector3.DOWN, Vector3.UP)

	# $MeshInstance3D.mesh = arr_mesh
	# $MeshInstance3D2.mesh = arr_mesh2

	machine.load_gcode("M03 S500\nG01 X40 Z100\nG01 X40 Z80\nG02 X0 Z60 R0.4")
	machine.load_gcode("G01 X40 Z100 F1\nG01 X40 Z80 F1\nG03 X0 Z60 R0.4 F1")
	if machine.gcode.valid:
		machine.run()
	else:
		print("GCode invalid")
	
	# pass
	# print(masina.control_unit.M03.validate({"M": "03", "S": "800"}))
	
	
#	$Machine/simulationAnimation.advance(0.6)
#
#	$Machine/simulationAnimation.active = false
#
#	await get_tree().create_timer(2).timeout
#	$Machine/simulationAnimation.active = true
#	$Machine/simulationAnimation.advance(0.6)

