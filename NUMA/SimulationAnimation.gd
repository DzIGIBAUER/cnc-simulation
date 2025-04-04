class_name SimulationAnimation
extends AnimationPlayer

@export var machine: Machine

enum Tracks {
	CHUCK,
	TOOL,
	PART,
	WASTE,
}

var animation = Animation.new()

var block_animation_duration: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	animation.length = 0

	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("simulation", animation)
	
	add_animation_library("animation", anim_lib)

	_init_tracks()


func _init_tracks():
	# animation.add_track(Animation.TYPE_ROTATION_3D, Tracks.CHUCK)
	# TYPE_ROTATION_3D Uses quats and they cant represent agnles above 360deg
	animation.add_track(Animation.TYPE_VALUE, Tracks.CHUCK)
	animation.track_set_path(Tracks.CHUCK, "%s:rotation" % machine.get_path_to(machine.chuck.chuck_mesh_instance))

	animation.add_track(Animation.TYPE_POSITION_3D, Tracks.TOOL)
	animation.track_set_path(Tracks.TOOL, "%s:position" % machine.get_path_to(machine.tool.tool_mesh_instance))
	# animation.track_set_interpolation_type(Tracks.TOOL, Animation.INTERPOLATION_LINEAR)
	
	animation.add_track(Animation.TYPE_VALUE, Tracks.PART)
	animation.track_set_path(Tracks.PART, "%s:mesh" % machine.get_path_to(machine.chuck.processed_part))

	animation.add_track(Animation.TYPE_VALUE, Tracks.WASTE)
	animation.track_set_path(Tracks.WASTE, "%s:mesh" % machine.get_path_to(machine.chuck.waste))

	animation.length = 0

## Resets animation to clean state with all track present
func clear_animations():
	animation.clear()
	_init_tracks()


func get_track_last_key_time(track: Tracks) -> float:
	var key_count = animation.track_get_key_count(track)

	if key_count:
		return animation.track_get_key_time(track, key_count-1)
	
	return 0
