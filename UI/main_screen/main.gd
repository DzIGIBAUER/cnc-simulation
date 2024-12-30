extends Control

@onready var _import_projects_file_dialog: FileDialog = %ImportProjectFileDialog
@onready var _projects_container: Container = %ProjectsContainer

func _ready() -> void:
	_update_projects_list()
	Config.projects_updated.connect(_update_projects_list)


func _update_projects_list() -> void:
	for ch in _projects_container.get_children(): ch.queue_free()

	for path in Config.get_projects():
		var project_card: = ProjectCard.create(path.get_basename().get_file(), path)
		project_card.pressed.connect(Global.open_project.bind(path))
		_projects_container.add_child(project_card)


func _on_button_pressed():
	
	# get_tree().change_scene_to_file("res://UI/lathe_simulation/lathe_simulation.tscn")

	Global.open_new_project()


func _on_import_projects_button_pressed() -> void:
	_import_projects_file_dialog.popup_centered()


func _on_import_project_file_dialog_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		Global.import_project(path)
