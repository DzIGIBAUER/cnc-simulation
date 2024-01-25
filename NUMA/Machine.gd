class_name Machine
extends Node3D

## This signal is called after control unit G or M function is called
signal function_called(machine: Machine, function_name: String, block: Dictionary, duration: float)

signal on_state_set(function: ControlUnit.Function)

# this may need to change if we ever create mill machine
@export var simulation_environment: Node2D
@export var machine_mesh_instance: Node
@export var control_unit: ControlUnit

@export var machine_zero_point: Node3D
@export var reference_point: Node3D

@export var chuck: Chuck
@export var tool: Tool

const MAX_TOOL_SPEED = 0.5

var workspace: AABB

var gcode: GCode

func _ready():
	workspace = AABB(machine_zero_point.position, reference_point.position-machine_zero_point.position).abs()
	

func is_point_inside_workspace(point: Vector3) -> bool:
	return workspace.has_point(point)

## Trasform vector3 from machine to workspace coordinate system
func point_to_workspace(point: Vector3) -> Vector3:
	return to_global(point) - workspace.position


func load_gcode(code: String):
	gcode = control_unit.parse_gcode(code)

func run():
	for block in gcode.blocks:
		var function_name: String
		
		if "G" in block.params.keys():
			function_name = "G" + block.params["G"]
		elif "M" in block.params.keys():
			function_name = "M" + block.params["M"]

		var function: ControlUnit.Function = control_unit.get(function_name).new(self, block)
		print("function %s takes %s seconds to complete" % [function_name, function.calculate_duration()])
		function.set_state()
		function.animate($SimulationAnimation)
	
	$SimulationAnimation.play("animation/simulation")

