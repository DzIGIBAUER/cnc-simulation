class_name ControlUnit
extends Node

enum Unit {
	MILLIMETERS,
	INCHES,
}

var selected_unit: Unit = Unit.MILLIMETERS

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



class Function extends RefCounted:

	var machine: Machine
	var block: Block

	func _init(machine_: Machine, block_: Block):
		self.machine = machine_
		self.block = block_
	
	static func validate(_block: Block) -> bool:
		return false
	
	func set_state() -> void:
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

		# set metadata for duration here
		gcode.blocks.append(block)
	
	return gcode
