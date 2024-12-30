class_name Project
extends RefCounted


static func save(save_path: String = "user://save.json") -> void:
	var data: = {
		"machine": {
			"gcode": Global.machine.gcode.raw
		}
	}


	var save_file: = FileAccess.open(save_path, FileAccess.WRITE)
	
	var err: = FileAccess.get_open_error()
	if err != OK:
		push_error("Couldn't open the save file while saving at %s. Error: %s" % [save_path, error_string(err)])
		return

	save_file.store_string(JSON.stringify(data))
	print("Saved to %s" % save_path)


static func load(path: String = "user://save.json") -> Variant:

	var file: = FileAccess.open(path, FileAccess.READ)

	var err: = FileAccess.get_open_error()
	if err != OK:
		push_error("Couldn't open the save file while loading from %s. Error: %s" % [path, error_string(err)])
		return

	var data = JSON.parse_string(file.get_as_text())

	return data
