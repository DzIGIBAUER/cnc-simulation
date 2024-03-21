extends VBoxContainer

@export var error_label: Label
@export var run_button: Button

func _on_g_code_edit_errors_changed():
	if not Global.machine or not Global.machine.gcode: return

	run_button.visible = Global.machine.gcode.valid
	error_label.visible = not Global.machine.gcode.valid
	
	var selected_line = $GCodeEdit.get_caret_line()

	var errs = Global.machine.gcode.errors.filter(func(err): return err.line == selected_line)

	var error: GCodeError

	# show the error of selected line or first error
	if not errs.is_empty():
		error = errs[0]
	elif not Global.machine.gcode.errors.is_empty():
		error = Global.machine.gcode.errors[0]
	
	if error:
		error_label.text = error.to_string()
	else:
		error_label.text = ""



func _on_run_button_pressed():
	Global.machine.run()
