class_name GCodeError
extends RefCounted

var line: int
var column: int
var message: String

func _init(line_num: int, column_num: int, message_text: String):
    line = line_num
    column = column_num
    message = message_text

func _to_string():
    return "(%s, %s) %s" % [line, column, message]
