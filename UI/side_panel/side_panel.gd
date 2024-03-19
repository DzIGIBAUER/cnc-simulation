extends Control

@export var animation_player: AnimationPlayer

var open = true

func _ready():
	animation_player.connect("animation_finished", _on_animation_finished)



func add_content(node: Control):
	$Content.add_child(node)


func _on_animation_finished(anim_name: StringName):
	if anim_name == "slide":
		open = animation_player.current_animation_position > 0


func _on_slide_button_pressed():
	if not open:
		animation_player.play("slide")
	else:
		animation_player.play_backwards("slide")
