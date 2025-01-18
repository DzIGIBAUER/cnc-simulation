class_name LatheControlUnit
extends ControlUnit

# NOTE: y axis doesnt exist on lathe and machine zero point is oriented that way
# NOTE: resulting vector for simulation is (x, 0, y)

func valid_letters() -> Array[String]:
	return [
		"G",
		"M",
		"F",
		"S",
		"X",
		"Z",
		"R",
		"P",
	]

class M03 extends Function:

	static func validate(block_: Block):
		if not "S" in block_.params:
			return false
		return true

	
	func get_category(): return FunctionCategory.MCODE

	func set_state():
		super()
		self.machine.chuck.speed = block.get_param("S")

	func calculate_duration():
		return 0
	
	func animate(sim_anim: SimulationAnimation):
		var animate_to = machine.gcode.blocks.size()-1

		var chuck_function_names = [
			"M03",
			"M05",
			"M30"
		]

		# check which index is greater
		for func_name in chuck_function_names:
			var block_index = machine.gcode.find_block_by_function(func_name, block.params.get("N", 0).to_int() + 1)
			if block_index:
				animate_to = block_index

		set_meta("total_duration", 0)

		var ost = func(function: Function):
			if function.block.params["N"].to_int() > block.params["N"].to_int():
				set_meta("total_duration", get_meta("total_duration") + function.calculate_duration())

			if machine.gcode.blocks[animate_to] != function.block: return

			var start_time = sim_anim.get_track_last_key_time(sim_anim.Tracks.CHUCK)
			var end_time = get_meta("total_duration")


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


class InterpolationFunction extends Function:
	var last_position: Vector2
	var simulation_result: LatheSimulationEnvironment.SimulationResult

	static func validate(block_: Block):
		var x = block_.params.get("X")
		var z = block_.params.get("Z")

		return x or z

	func get_category(): return FunctionCategory.MOTION
	
	func get_feedrate() -> float:
		return block.get_param("F")

	func set_state():
		super()

		var x = machine.control_unit.convert2mm(block.get_param("X") / 100.0)
		var z = machine.control_unit.convert2mm(block.get_param("Z") / 100.0)

		last_position = machine.tool.position
		print("last_position set to: ", last_position)

		machine.tool.position = Vector2(x, z)
		print("machine.tool.position is now: ", machine.tool.position)

		machine.tool.tool_mesh_instance.position = machine.reference_point.position
		# machine.tool.tool_mesh_instance.position = machine.program_point.to_global(Vector3(last_position.x, 0, last_position.y))
	
	func calculate_duration():
		var x = machine.control_unit.convert2mm(block.get_param("X") / 100.0)
		var z = machine.control_unit.convert2mm(block.get_param("Z") / 100.0)
		
		# y axis doesnt exist on lathe and machine zero point is oriented that way
		var move_to = machine.program_point.to_global(Vector3(x, 0, z)) + machine.tool.offset

		# multiply by 1000 to get mm
		var distance = machine.tool.tool_mesh_instance.global_position.distance_to(move_to) * 1000

		print("Calculated distance is %s" % distance)
		print("Feedrate is %s" % self.get_feedrate())
		print("Calculated duration is %s" % (distance / self.get_feedrate()))

		return distance / self.get_feedrate()

	func calculate_interpolation_results(tool_start: Vector3, tool_end: Vector3):
		simulation_result = machine.simulation_environment.calculate_lathe_linear_interpolation_result(tool_start, tool_end)
	
	func animate_part(sim_anim: SimulationAnimation, start_time: float, length: float):
		sim_anim.animation.track_insert_key(sim_anim.Tracks.WASTE, start_time, simulation_result.waste_mesh, 1)
		# sim_anim.animation.track_insert_key(sim_anim.Tracks.WASTE, start_time + length, simulation_result.waste_mesh, 0)

		# if start_time == 0:
		# sim_anim.animation.track_insert_key(sim_anim.Tracks.PART, start_time, machine.chuck.processed_part.mesh, 0)

		var k1 = sim_anim.animation.track_insert_key(sim_anim.Tracks.PART, start_time, simulation_result.mesh, 1)
		# var k2 = sim_anim.animation.track_insert_key(sim_anim.Tracks.PART, start_time + length, simulation_result.mesh, 1)

		print("Animated part at time %s with key %s" % [start_time, k1])
		# print("Animated part at time %s with key %s" % [start_time + length, k2])
	
	func animate_tool(sim_anim: SimulationAnimation, start_time: float, length: float):
		# sim_anim.animation.position_track_insert_key(sim_anim.Tracks.TOOL, start_time, simulation_result.tool_positions[0] + machine.tool.offset)
		sim_anim.animation.position_track_insert_key(sim_anim.Tracks.TOOL, start_time + length, simulation_result.tool_positions[1] + machine.tool.offset)

		print("Animated tool at time %s" % [start_time])
		print("Animated tool at time %s" % [start_time + length])


	func animate(sim_anim: SimulationAnimation):
		var start_time = sim_anim.get_track_last_key_time(sim_anim.Tracks.TOOL)
		
		var x = machine.control_unit.convert2mm(block.get_param("X") / 100.0)
		var z = machine.control_unit.convert2mm(block.get_param("Z") / 100.0)

		# y axis doesnt exist on lathe and machine zero point is oriented that way
		var move_to = machine.program_point.to_global(Vector3(x, 0, z)) + machine.tool.offset

		var move_from: Vector3
		print("machine.tool.position: ", machine.tool.position)
		
		if last_position != null:
			move_from = machine.program_point.to_global(Vector3(last_position.x, 0, last_position.y)) + machine.tool.offset
		
		
		print("Move from is %s" % move_from)
			
		# coord. system of machine and world are in same
		var ts = machine.to_local(move_from - machine.tool.offset)
		var te = machine.to_local(move_to - machine.tool.offset)

		print("ts: ", ts)
		print("te: ", te)

		# var result = machine.simulation_environment.calculate_lathe_linear_interpolation_result(ts, te)
		calculate_interpolation_results(ts, te)

		var length = calculate_duration()
		
		animate_part(sim_anim, start_time, length)
		animate_tool(sim_anim, start_time, length)

		sim_anim.animation.length += length


class G00 extends InterpolationFunction:
	func get_feedrate() -> float:
		return machine.MAX_TOOL_SPEED


class G01 extends InterpolationFunction:
	static func validate(block_: Block):
		var f = block_.params.get("F")

		return super(block_) and f




class G02 extends InterpolationFunction:
	
	static func validate(block_: Block):
		var r = block_.params.get("R")

		return super(block_) and r
	
	func calculate_interpolation_results(tool_start: Vector3, tool_end: Vector3):
		var radius = machine.control_unit.convert2mm(block.get_param("R") / 100.0)

		simulation_result = machine.simulation_environment.calculate_lathe_circular_interpolation_result(tool_start, tool_end, radius)
	
	func animate_tool(sim_anim: SimulationAnimation, start_time: float, length: float):
		for i in range(simulation_result.tool_positions.size()):
			# if i == 0: continue

			var tool_position = simulation_result.tool_positions[i] + machine.tool.offset

			var end_time = start_time + (length / simulation_result.tool_positions.size()) * i

			sim_anim.animation.position_track_insert_key(sim_anim.Tracks.TOOL, end_time, tool_position)


class G03 extends G02:
	func calculate_interpolation_results(tool_start: Vector3, tool_end: Vector3):
		var radius = machine.control_unit.convert2mm(block.get_param("R") / 100.0)
		simulation_result = machine.simulation_environment.calculate_lathe_circular_interpolation_result(tool_start, tool_end, radius, false)

class G04 extends Function:

	static func validate(block_: Block):
		var p = block_.params.get("P")
		var x = block_.params.get("X")

		return p or x
	
	func get_category(): return FunctionCategory.MOTION

	func set_state():
		super()

	func calculate_duration():
		var length: float

		if "P" in block.params:
			length = block.get_param("P") / 100
		else:
			length = block.get_param("X")
		
		return length
	
	func animate(sim_anim: SimulationAnimation):
		var start_time = sim_anim.get_track_last_key_time(sim_anim.Tracks.TOOL)

		var length = calculate_duration()

		# sim_anim.animation.track_insert_key(sim_anim.Tracks.TOOL, start_time, machine.tool.tool_mesh_instance.position + machine.tool.offset);
		sim_anim.animation.track_insert_key(sim_anim.Tracks.TOOL, start_time + length, machine.tool.tool_mesh_instance.position + machine.tool.offset);
		sim_anim.animation.length += length




class G20 extends Function:
	static func validate(_block: Block):
		return true
	
	func get_category(): return FunctionCategory.COORDINATE

	func set_state():
		super()
		machine.control_unit.selected_unit = machine.control_unit.Unit.INCHES
	
	func calculate_duration():
		return 0


class G21 extends Function:
	static func validate(_block: Block):
		return true
	
	func get_category(): return FunctionCategory.COORDINATE

	func set_state():
		super()
		machine.control_unit.selected_unit = machine.control_unit.Unit.MILLIMETERS
	
	func calculate_duration():
		return 0


class G32 extends G01:
	
	func get_category(): return FunctionCategory.CANNED

	func calculate_interpolation_results(tool_start: Vector3, tool_end: Vector3):
		simulation_result = machine.simulation_environment.calculate_lathe_thread_result(tool_start, tool_end)


class G90 extends Function:
	static func validate(_block: Block):
		return true
	
	func get_category(): return FunctionCategory.COORDINATE

	func set_state():
		super()
		machine.control_unit.selected_positioning_mode = PositioningMode.ABSOLUTE
	
	func calculate_duration():
		return 0


class G91 extends Function:
	static func validate(_block: Block):
		return true
	
	func get_category(): return FunctionCategory.COORDINATE

	func set_state():
		super()
		machine.control_unit.selected_positioning_mode = PositioningMode.RELATIVE
	
	func calculate_duration():
		return 0

class G92 extends Function:
	static func validate(_block: Block):
		var x = _block.params.get("X")
		var z = _block.params.get("Z")
		return x or z
	
	func get_category(): return FunctionCategory.COORDINATE

	func set_state():
		super()
		# program point is machine zero point with user defined offset
		machine.program_point.position = machine.to_local(machine.machine_zero_point.position)
		print(machine.program_point.position)

		if "X" in block.params:
			machine.program_point.position.y += block.get_param("X")

		if "Z" in block.params:
			machine.program_point.position.x += block.get_param("Z")

		print("Set the program point to %s." % [machine.program_point.position])
