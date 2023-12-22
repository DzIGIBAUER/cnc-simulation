class_name LatheControlUnit
extends ControlUnit

func valid_letters() -> Array[String]:
	return [
		"G",
		"M",
		"F",
		"S",
		"X",
		"Z"
	]

class M03 extends Function:

	static func validate(params: Dictionary):
		if not "S" in params:
			return false
		return true
	
	func set_state():
		super()
		self.machine.chuck.speed = self.block.params["S"]

	func calculate_duration():
		return 0
	
	func animate(sim_anim: SimulationAnimation):
		var animate_to = machine.gcode.blocks.size()-1

		var chuck_function_names = [
			"M03",
			"M05",
			"M30"
		]

		for func_name in chuck_function_names:
			var block_index = machine.gcode.find_block_by_function(func_name)
			if block_index:
				animate_to = block_index

		var ost = func(function: Function):
			if machine.gcode.blocks[animate_to] != function.block: return

			var start_time = sim_anim.get_track_last_key_time(sim_anim.Tracks.CHUCK)
			var end_time = function.calculate_duration()


			var current_rotation = machine.chuck.chuck_mesh_instance.rotation
			var rotation_axis = Vector3.AXIS_X

			var rpm = 60
			var rps = rpm / 60.0
			
			var length = end_time - start_time
			
			var rotation_amount = 360 * length / rps

			var new_rotation = current_rotation
			current_rotation[rotation_axis] = rotation_amount
			
			sim_anim.animation.track_insert_key(sim_anim.Tracks.CHUCK, start_time, current_rotation);
			sim_anim.animation.track_insert_key(sim_anim.Tracks.CHUCK, start_time + length, new_rotation);
			
			sim_anim.animation.length += length

		machine.on_state_set.connect(ost)


class G00 extends Function:
	var last_position: Vector2
	
	static func validate(params: Dictionary):
		var x = params.get("X")
		var z = params.get("Z")

		if not x and not z: return false
		
		return true
	
	func set_state():
		super()

		var x = int(block.params["X"]) / 100.0
		var z = int(block.params["Z"]) / 100.0

		last_position = machine.tool.position
		machine.tool.position = Vector2(x, z)
	
	func calculate_duration():
		var x = int(block.params["X"]) / 100.0
		var z = int(block.params["Z"]) / 100.0
		
		# y axis doesnt exist on lathe and machine zero point is oriented that way
		var move_to = machine.machine_zero_point.to_global((Vector3(x, 0, z))) + machine.tool.offset

		var distance = machine.tool.tool_mesh_instance.global_position.distance_to(move_to)

		return distance / machine.MAX_TOOL_SPEED

	func animate(sim_anim: SimulationAnimation):
		var start_time = sim_anim.get_track_last_key_time(sim_anim.Tracks.TOOL)
		
		var x = int(block.params["X"]) / 100.0
		var z = int(block.params["Z"]) / 100.0

		# y axis doesnt exist on lathe and machine zero point is oriented that way
		var move_to = machine.machine_zero_point.to_global(Vector3(x, 0, z)) + machine.tool.offset

		var move_from: Vector3
		if last_position:
			move_from = machine.machine_zero_point.to_global(Vector3(last_position.x, 0, last_position.y)) + machine.tool.offset
		else:
			move_from = machine.tool.tool_mesh_instance.position
		
			
		# coord. system of machine and world are in same
		var ts = machine.to_local(move_from - machine.tool.offset)
		var te = machine.to_local(move_to - machine.tool.offset)

		var results: Array = Simulation.calculate_linear_interpolation_result_part(machine, ts, te)

		var dw: DebugWindow = machine.get_node("../DebugWindow")
		
		for i in range(1, 4):
				var item = DebugItem.new()
				item.polygons = [results[i]]

				dw.add_debug_item(str(block), item)

		print(ts, te)

		machine.chuck.processed_part.mesh = results[0]
		machine.tool.tool_mesh_instance.position = move_to

		sim_anim.animation.track_insert_key(sim_anim.Tracks.PART, start_time, machine.chuck.processed_part.mesh, 0)
		sim_anim.animation.track_insert_key(sim_anim.Tracks.PART, start_time + calculate_duration(), results[0], 0)

		sim_anim.animation.position_track_insert_key(sim_anim.Tracks.TOOL, start_time, move_from)
		sim_anim.animation.position_track_insert_key(sim_anim.Tracks.TOOL, start_time + calculate_duration(), move_to)

		sim_anim.animation.length += calculate_duration()
