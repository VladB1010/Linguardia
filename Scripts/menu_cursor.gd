class_name MenuCursor extends Control

var target: Control = null

var disabled: bool = false
@export var button_offset: Vector2 = Vector2(-140, -10)
@export var enemy_offset:  Vector2 = Vector2(-70, 50)

var current_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)
	hide()
	set_process(false)

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + current_offset

func _on_viewport_gui_focus_changed(node: Control) -> void:
	if disabled:
		hide()
		set_process(false)
		return
	if node and node is BaseButton:
		if _is_inside_minigame(node):
			hide()
			set_process(false)
			return

		if target:
			target.tree_exiting.disconnect(_on_target_tree_exiting)

		target = node
		target.tree_exiting.connect(_on_target_tree_exiting.bind(target))

		if node.has_method("get_cursor_offset"):
			current_offset = node.get_cursor_offset()
		elif node.name.begins_with("Enemy"):
			current_offset = enemy_offset
		else:
			current_offset = button_offset

		show()
		set_process(true)
	else:
		hide()
		set_process(false)

func _is_inside_minigame(node: Node) -> bool:
	var current: Node = node.get_parent()
	while current:
		if current is Minigame:
			return true
		current = current.get_parent()
	return false

func _on_target_tree_exiting(node: Control) -> void:
	if node == target:
		target = null
		set_process(false)
