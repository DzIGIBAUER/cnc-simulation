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

func get_param(param_name: String, keep_string = false) -> float:
	return params.get(param_name) if keep_string else float(params.get(param_name))

func _to_string():
	return "Block: %s" % params

