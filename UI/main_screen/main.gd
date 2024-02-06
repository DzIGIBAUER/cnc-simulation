extends Control

var simulation_scene = preload("res://UI/simulation/simulation.tscn").instantiate()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_button_pressed():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	add_child(simulation_scene)

	var masina: Machine = simulation_scene.get_node("SubViewportContainer/SubViewport/Node3D/Machine")

	masina.load_gcode($VBoxContainer/CodeEdit.text)
	masina.run()
