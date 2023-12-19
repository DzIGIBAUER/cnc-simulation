extends Node3D

func predment(anim: Animation):
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, "MeshInstance2D:position")
	anim.track_insert_key(track_index, 0, Vector2(0, 0))
	anim.track_insert_key(track_index, 1, Vector2(150, 0))
	anim.track_insert_key(track_index, 5, Vector2(150, -150))
	anim.track_insert_key(track_index, 6, Vector2(0, -150))

func krug(anim: Animation):
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, "Krug:rotation")
	anim.track_insert_key(track_index, 0, 0)
	anim.track_insert_key(track_index, 1, deg_to_rad(360))
	anim.track_insert_key(track_index, 5, deg_to_rad(360))
	anim.track_insert_key(track_index, 6, deg_to_rad(360*2))

# Called when the node enters the scene tree for the first time.
func _ready():
	var anim_lib = AnimationLibrary.new()
	
	var anim = Animation.new()
	anim.length = 20
	
#	predment(anim)
#	krug(anim)
	
	anim_lib.add_animation("test", anim)
	
	$AnimationPlayer.add_animation_library("test", anim_lib)
	
	$AnimationPlayer.play("test/test")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
