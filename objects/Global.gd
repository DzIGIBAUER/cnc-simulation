extends Node


const _lathe_scene_path: = "res://UI/lathe_simulation/lathe_simulation.tscn"

var debug_window: DebugWindow

var machine: Machine


func open_new_project() -> void:
	var simulation_scene: = LatheSimulation.create()

	get_tree().root.get_node("Main").queue_free()
	get_tree().root.add_child(simulation_scene)
	get_tree().current_scene = simulation_scene


func open_project(project_path: String = "") -> void:
	
	var data = Project.load(project_path)
	if not data:
		return

	var simulation_scene: = LatheSimulation.create(data)

	get_tree().root.get_node("Main").queue_free()
	get_tree().root.add_child(simulation_scene)	
	get_tree().current_scene = simulation_scene


func import_project(project_path: String) -> void:
	var data = Project.load(project_path)
	if not data: return

	Config.add_project(project_path)