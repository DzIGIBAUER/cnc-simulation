extends CodeEdit
class_name GCodeEdit

## Emited every time GCodeEdit text has changed and parsed
signal errors_changed()


@export var error_label: Label
@export var run_button: Button

func _ready():

	# in case the code edit is prepopulated
	_on_text_changed()

func _on_text_changed():
	Global.machine.load_gcode(text)

	for i in range(get_line_count()):
		set_line_background_color(i, Color.TRANSPARENT)

	if not Global.machine.gcode.valid:
		for err in Global.machine.gcode.errors:
			set_line_background_color(err.line, Color.DARK_RED)
		
	errors_changed.emit()
