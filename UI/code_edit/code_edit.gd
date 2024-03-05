extends CodeEdit
class_name GCodeEdit

@export var error_label: Label

var machine: Machine

func _ready():
	connect("text_changed", _on_text_changed)
	connect("caret_changed", _on_caret_changed)

func _on_text_changed():
	machine.load_gcode(text)

	for i in range(get_line_count()):
		set_line_background_color(i, Color.TRANSPARENT)

	if not machine.gcode.valid:
		for err in machine.gcode.errors:
			set_line_background_color(err.line, Color.DARK_RED)


func _on_caret_changed():
	if not machine.gcode: return

	var selected_line = get_caret_line()

	var errs = machine.gcode.errors.filter(func(err): return err.line == selected_line)

	var error: GCodeError

	# show the error of selected line or first error
	if not errs.is_empty():
		error = errs[0]
	elif not machine.gcode.errors.is_empty():
		error = machine.gcode.errors[0]
	
	if error:
		error_label.text = error.to_string()
	else:
		error_label.text = ""
