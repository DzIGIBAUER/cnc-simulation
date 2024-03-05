extends Control

var simulation_scene = preload("res://UI/simulation/simulation.tscn").instantiate()

@onready var machine: Machine = simulation_scene.get_node("SubViewportContainer/SubViewport/Node3D/Machine")
@onready var gcode_edit: GCodeEdit = $VBoxContainer/VBoxContainer/GCodeEdit


func _ready():
	gcode_edit.machine = machine


func _on_button_pressed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	add_child(simulation_scene)

	machine.load_gcode($VBoxContainer/VBoxContainer/GCodeEdit.text)
	machine.run()
