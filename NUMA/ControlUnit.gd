class_name ControlUnit
extends Node

enum Unit {
	MILLIMETERS,
	INCHES,
}

enum FunctionCategory {
	MOTION,
	COMPENSATION,
	COORDINATE,
	CANNED,
	OTHER,
	MCODE,
}

enum PositioningMode {
	ABSOLUTE,
	RELATIVE,
}

var selected_unit: Unit = Unit.MILLIMETERS
var selected_positioning_mode: PositioningMode = PositioningMode.ABSOLUTE

## Converts input value from [member ControlUnit.selected_unit] to millimeters
## [member ControlUnit.selected_unit] is modified by GCode functions like G20 and G21
func convert2mm(value: float) -> float:

	match selected_unit:
		Unit.MILLIMETERS:
			return value 
		Unit.INCHES:
			return value * 25.4
		_:
			push_error("Variable selected_unit doesn't match any Unit Enum value. Current value is %s " % selected_unit)
			return value

## Fills the [param block] parameter [params param_name] with value from first previous function block that contains it and has
## the caregory of [param function_category]. Called internaly from Function init.
## Assumes the [param functions] is a list of functions before the function where the [param block] is part of.
func _fill_in_missing_parameter(functions: Array[Function], block: Block, param_name: String, function_category: FunctionCategory):
	print("Processing block %s for value %s" % [block, param_name])

	if param_name in block.params:
		print("Block %s already has parameter %s. Returning..." % [block, param_name])
		return block
	
	var updated_block = Block.new(block.params)
	
	if selected_positioning_mode == PositioningMode.RELATIVE:
		updated_block.params[param_name] = "0"
		return updated_block

	for i in range(functions.size()-1, -1, -1):
		var func_ = functions[i]

		if func_.category != function_category: continue

		if not param_name in func_.block.params: continue

		print("Populated %s with value of %s from %s" % [block, param_name, func_])
		updated_block.params[param_name] = func_.block.params[param_name]
		break


	return updated_block
	

func _process_function_block(function: Function) -> Block:
	
	var processed_block = Block.new(function.block.params)

	var previous_functions = function.machine.gcode.functions.slice(0, function.machine.gcode.functions.find(function))

	# TODO: Also check for CANNED

	# fill in if theres missing X or Z coordinate
	if function.category == FunctionCategory.MOTION:
		var updated_block = _fill_in_missing_parameter(previous_functions, function.block, "X", FunctionCategory.MOTION)
		processed_block.params.merge(updated_block.params)

		updated_block = _fill_in_missing_parameter(previous_functions, function.block, "Z", FunctionCategory.MOTION)
		processed_block.params.merge(updated_block.params)

	# Convert to millimeters if inches are used in GCode and we have a motion function
	# Not sure if there are any other parameters that are affected by selected unit
	if selected_unit == Unit.INCHES and function.category == FunctionCategory.MOTION:
		function.block.params["X"] *= 25.4
		function.block.params["Z"] *= 25.4
	
	# Now we have populated X and Z for previous function
	if selected_positioning_mode == PositioningMode.RELATIVE:
		print("relative je")

		# Find first previous function that we have to take X and Z from
		for i in range(previous_functions.size()-1, -1, -1):
			var func_ = previous_functions[i]

			if func_.category != FunctionCategory.MOTION: continue

			processed_block.params["X"] = processed_block.get_param("X") + func_.block.get_param("X")
			processed_block.params["Z"] = processed_block.get_param("Z") + func_.block.get_param("Z")

			break
			
	return processed_block


class Function extends RefCounted:

	var category: FunctionCategory : get = get_category
	var machine: Machine
	var block: Block

	func _init(machine_: Machine, block_: Block):
		self.machine = machine_
		self.block = block_
	
	func _to_string():
		var function_name: String
		
		if "G" in block.params.keys():
			function_name = "G" + block.params["G"]
		elif "M" in block.params.keys():
			function_name = "M" + block.params["M"]
		
		return function_name
	
	static func validate(_block: Block) -> bool:
		return false
	
	func get_category() -> FunctionCategory: return FunctionCategory.OTHER

	func set_state() -> void:
		self.block = machine.control_unit._process_function_block(self)
		machine.on_state_set.emit(self)
		return

	func calculate_duration() -> float:
		return -1

	func animate(_sim_anim: SimulationAnimation) -> void:
		pass
	

func valid_letters() -> Array[String]:
	push_error("NotImplemented: function valid_letters is not implemented.")
	return []

func parse_gcode(code: String) -> GCode:
	var lines = code.split("\n")
	
	var gcode = GCode.new()
	
	for line_num in range(lines.size()):
		var line = lines[line_num].strip_edges()
		if not line.length(): continue
		
		var params = {}
		var words = line.split(" ", false)

		var main_function: String
		
		for word in words:
			var col = line.find(word)
			var letter = word.substr(0, 1)
			var number = word.substr(1)
			
			if not letter in valid_letters():
				gcode.invalidate(line_num, col, "Letter %s is not a valid letter" % letter)
			
			if number and not number.is_valid_float():
				gcode.invalidate(line_num, col+1, "Number %s is not a valid parameter value" % number)

			if letter in ["G", "M"]:
				main_function = "%s%s" % [letter, number]
				if get(main_function) == null:
					gcode.invalidate(line_num, col, "Function %s doesn't exist." % main_function)
			
			params[letter] = number
		
		if not params.has("G") and not params.has("M"):
			gcode.invalidate(line_num, 0, "Can't find function to run.")
		
		# bolje ovo, mozda neka linija ima N namesteno na vrednost line_num
		if not params.has("N"):
			params["N"] = str(line_num)
		
		var block = Block.new(params)
		
		if get(main_function):
			var valid = get(main_function).validate(block)
			if not valid:
				gcode.invalidate(line_num, 0, "Wrong parameters")

		gcode.blocks.append(block)
	
	return gcode
