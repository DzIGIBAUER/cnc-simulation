extends Node

## Default config file values.[br]
## Top level keys are section names
## and values are key-value pairs of actual data in that section.
const _default_values: = {
    PROJECTS_SECTION: {
        "projects": []
    }
}

const PROJECTS_SECTION: = "Projects"

signal projects_updated()

var file: = ConfigFile.new()

var path: String = "user://config.cfg"


func _ready() -> void:

    var err: = file.load(path)

    # if we can't open the file, create a new one with default values
    if err != OK:
        print("Couldn't open the user config file at %s. Error: %s" % [path, error_string(err)])

        for section in _default_values:
            var values: Dictionary = _default_values[section]

            for key in values:
                var value = values[key]
                file.set_value(section, key, value)
        
        file.save(path)
        return


func get_projects() -> Array[String]:
    var projects: Array[String] = []
    var arr = file.get_value(PROJECTS_SECTION, "projects", [])

    projects.assign(arr)
    return projects


func add_project(project_path: String) -> void:
    var projects: = get_projects()
    
    if not project_path in projects: return

    projects.append(project_path)

    file.set_value(PROJECTS_SECTION, "projects", projects)
    file.save(path)
    projects_updated.emit()
