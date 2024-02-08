extends CodeEdit
class_name GCodeEdit


func _ready():
    # connect("text_changed", _on_text_changed)
    pass

# FIXME: fucks up undo history
# func _on_text_changed():
#     var carets: Array[Vector2i] = []

#     for i in range(get_caret_count()):
#         carets.append(Vector2i(get_caret_line(i), get_caret_column(i)))
    
    

#     text = text.to_upper()
    
#     for i in range(get_caret_count()):
#         set_caret_line(carets[i].x, true, true, 0, i)
#         set_caret_column(carets[i].y, true, i)
    