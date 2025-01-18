class_name Tool
extends Node

@export var tool_mesh_instance: MeshInstance3D
@export var tool_edge: Node3D

# offset between mesh origin and tool edge point
@onready var offset = tool_mesh_instance.global_position - tool_edge.global_position
@onready var tool_mesh_starting_position = tool_mesh_instance.position

var position: Vector2 = Vector2.ZERO

func _ready() -> void:
    print(tool_mesh_starting_position)