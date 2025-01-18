class_name Machine
extends Node3D

## This signal is called after control unit G or M function is called
signal function_called(machine: Machine, function_name: String, block: Dictionary, duration: float)

signal on_state_set(function: ControlUnit.Function)

# this may need to change if we ever create mill machine
@export var simulation_environment: Node2D
@export var machine_mesh_instance: Node
@export var control_unit: ControlUnit
@export var simulation_animation: SimulationAnimation
@export var camera: Camera3D

@export var machine_zero_point: Node3D
@export var program_point: Node3D
@export var reference_point: Node3D

@export var chuck: Chuck
@export var tool: Tool

const MAX_TOOL_SPEED = 5_000

var workspace: AABB

var gcode: GCode

func _ready():
	workspace = AABB(machine_zero_point.position, reference_point.position-machine_zero_point.position).abs()
	
	# simulation_environment

	# turn machine zero point to local coorinates
	program_point.position = to_local(machine_zero_point.position)
	
	Global.machine = self

# TODO: don't run this all the time
func _process(_delta):
	chuck.waste.material_override.set_shader_parameter("retreat_position", chuck.waste.to_local(chuck.chuck_mesh_instance.global_position))
	chuck.waste.material_override.set_shader_parameter("tool_position", chuck.waste.to_local(tool.tool_edge.global_position))

func is_point_inside_workspace(point: Vector3) -> bool:
	return workspace.has_point(point)

## Trasform vector3 from machine to workspace coordinate system
func point_to_workspace(point: Vector3) -> Vector3:
	return to_global(point) - workspace.position


func load_gcode(code: String):
	gcode = control_unit.parse_gcode(code)

	for block in gcode.blocks:
		var function_name: String
		
		if "G" in block.params.keys():
			function_name = "G" + block.params["G"]
		elif "M" in block.params.keys():
			function_name = "M" + block.params["M"]
		
		if control_unit.get(function_name):
			var function: ControlUnit.Function = control_unit.get(function_name).new(self, block)
			gcode.functions.append(function)


func run():
	for function in gcode.functions:
		print("Setting state and animating %s" % function)
		function.set_state()
		function.animate(simulation_animation)
	
	simulation_animation.play("animation/simulation")
