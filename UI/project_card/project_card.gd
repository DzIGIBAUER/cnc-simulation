class_name ProjectCard
extends Button

const _scene: = preload("res://UI/project_card/ProjectCard.tscn")


@onready var _project_name_label: Label = %ProjectName
@onready var _project_path_label: Label = %ProjectPath


var title: String:
	set(value):
		title = value
		
		if not is_node_ready(): await ready
		_project_name_label.text = title

var path: String:
	set(value):
		path = value

		if not is_node_ready(): await ready
		_project_path_label.text = path


static func create(project_title: String, project_path: String) -> ProjectCard:
	var pc: = _scene.instantiate()
	
	pc.title = project_title
	pc.path = project_path

	return pc
