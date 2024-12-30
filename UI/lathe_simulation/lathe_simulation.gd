class_name LatheSimulation
extends Control

const _scene: = preload("res://UI/lathe_simulation/lathe_simulation.tscn")


var code_editor_scene: GCodeEditor = preload("res://UI/code_edit/code_editor.tscn").instantiate()


static func create(project_data: Dictionary = {}) -> LatheSimulation:
	var ls: LatheSimulation = _scene.instantiate()

	ls.code_editor_scene.code_edit.text = project_data.machine.gcode
	
	return ls


func _ready():
	$SidePanel.add_content(code_editor_scene)

	Global.debug_window = $DebugWindow
