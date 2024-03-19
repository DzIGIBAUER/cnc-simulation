@tool
extends Control



func set_label_text(label_path: NodePath, text: String):	
	var label_node = get_node_or_null(label_path)
	if label_node:
		label_node.text = text


@export var title: String:
	get: return %TitleLabel.text
	set(value): set_label_text(^"%TitleLabel", value)

@export var description: String:
	get: return %DescriptionLabel.text
	set(value): set_label_text(^"%DescriptionLabel", value)

@export var date: String:
	get: return %DateLabel.text
	set(value): set_label_text(^"%DateLabel", value)

