extends Control

var code_editor_scene = preload("res://UI/code_edit/code_editor.tscn").instantiate()

func _ready():
	$SidePanel.add_content(code_editor_scene)

	Global.debug_window = $DebugWindow
