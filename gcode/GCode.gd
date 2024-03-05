class_name GCode

var valid: bool :
	get: return errors.is_empty()

var errors: Array[GCodeError] = []

var blocks: Array[Block] = []

func invalidate(line, column, message) -> void:
	print("Line %s column %s error: %s" % [line, column, message])
	
	errors.append(GCodeError.new(line, column, message))

func find_block_by_function(function_name: String, from: int = 0):
	for i in blocks.size()-from:
		var block = blocks[from+i]
		if block.functions.has(function_name):
			return from+i
