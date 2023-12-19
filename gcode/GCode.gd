class_name GCode

var valid = true

var blocks: Array[Block] = []

func invalidate(line, column, message) -> void:
	print("Line %s column %s error: %s" % [line, column, message])
	valid = false

func find_block_by_function(function_name: String):
	for i in blocks.size():
		var block = blocks[i]
		if block.functions.has(function_name):
			return i
