class_name Tool
extends Node

@export var tool_mesh_instance: MeshInstance3D
@export var tool_edge: Node3D

# offset between mesh origin and tool edge point
@onready var offset = tool_mesh_instance.global_position - tool_edge.global_position

var position: Vector2 = Vector2.ZERO
