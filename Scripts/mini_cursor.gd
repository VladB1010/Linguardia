class_name MinigameCursor extends TextureRect

@export var offset: Vector2 = Vector2(-80, 30)

var _target: Control = null

func _ready() -> void:
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	hide()
	set_process(false)

func _process(_delta: float) -> void:
	if _target and is_instance_valid(_target):
		global_position = _target.global_position + offset

func _on_focus_changed(node: Control) -> void:
	if node and node is Button and _is_inside_minigame(node):
		_target = node
		show()
		set_process(true)
	else:
		_target = null
		hide()
		set_process(false)

func _is_inside_minigame(node: Node) -> bool:
	var current: Node = node.get_parent()
	while current:
		if current is Minigame:
			return true
		current = current.get_parent()
	return false
