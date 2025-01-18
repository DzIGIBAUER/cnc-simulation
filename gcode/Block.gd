extends RefCounted
class_name Block


var functions: Array[String]:
	get:
		# https://www.reddit.com/r/godot/comments/12dm8i2/comment/jf79eri/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
		var array_of_strings: Array[String] = []
		var fcs = params.keys().map(func(key): return "%s%s" % [key, params[key]])
		array_of_strings.assign(fcs)
		return array_of_strings
	
var params: Dictionary

func _init(params_: Dictionary):
	params = params_

## Gets the parameter value. Raises an error if parameter key doesn't exist.
## Check if the parameter exists [code]if "X" in block.parameters:[/code]
func get_param(param_name: String) -> float:
	if not param_name in params:
		push_error("Tried to get parameter %s from parameters where it doesn't exist." % [param_name])

	return float(params.get(param_name))

func _to_string():
	return "Block: %s" % params
