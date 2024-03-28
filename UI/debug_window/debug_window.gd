extends Control
class_name DebugWindow


var item_node_mapping := {}
var events := {}


func _ready():
	Global.debug_window = self

func _input(event):
	# MOBILE: for mobile devices
	if event is InputEventScreenTouch:
		if event.pressed:
			events[event.index] = event
		else:
			events.erase(event.index)

		if events.size() == 3:
			visible = !visible
			get_viewport().set_input_as_handled()

	if event.is_action_pressed("debug"):
		visible = !visible
		get_viewport().set_input_as_handled()


func _on_v_box_container_gui_input(event: InputEvent):
	var node_2d = _get_visible_node()
	if not node_2d: return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			node_2d.scale -= Vector2.ONE * 5
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			node_2d.scale += Vector2.ONE * 5
	
	elif event is InputEventScreenDrag:
		node_2d.position += event.relative




func add_debug_item(
	title: String,
	item: DebugItem
):
	
	# create and add node2d to show polygons
	var node_2d = Node2D.new()
	node_2d.visible = false
	node_2d.scale = Vector2(200, 200)
	node_2d.position = Vector2.ONE * $HBoxContainer/VBoxContainer.size / 2.0
	
	if not item.polygons.is_empty():
		for poly in item.polygons:
			var polygon_node = Polygon2D.new()
			polygon_node.polygon = poly
			
			polygon_node.vertex_colors = PackedColorArray(range(poly.size()).map(func(_n): return Color.from_hsv(randf(), randf(), randf())))

			node_2d.add_child(polygon_node)

			# add point for every vertex
			for p in poly:
				var mesh_node = MeshInstance2D.new()
				var mesh = CapsuleMesh.new()
				mesh.height = 0.02
				mesh_node.mesh = mesh
				mesh_node.position = p
				
				node_2d.add_child(mesh_node)

	$HBoxContainer/VBoxContainer/SubViewportContainer/SubViewport.add_child(node_2d)

	var item_index = $HBoxContainer/ItemList.add_item(title)
	
	item_node_mapping[item_index] = node_2d



func _on_item_list_item_selected(index: int):
	unselect_all()

	# show node2d if it has one
	var item = item_node_mapping.get(index)
	if item:
		item_node_mapping[index].visible = true

	# $HBoxContainer/SubItemListContainer/SubitemList.add_item()

func _get_visible_node():
	for node in item_node_mapping.values():
		if node.visible: return node


func unselect_all():
	for node in item_node_mapping.values():
		node.visible = false

	$HBoxContainer/SubItemListContainer/SubitemList.clear()

func _on_item_list_empty_clicked(_at_position, _mouse_button_index):
	unselect_all()
