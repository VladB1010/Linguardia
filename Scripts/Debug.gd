extends Node

const PRINT_CURRENT_FOCUS: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if PRINT_CURRENT_FOCUS:
		get_viewport().gui_focus_changed.connect(_on_viewport_gui_focus_changed)

func _unhandled_key_input(event: InputEvent) -> void:
	if Globals.text_input_active:
		return

	var input: InputEventKey = event

	if event.is_pressed():
		var key: int = input.keycode

		match key:
			KEY_R:
				get_tree().reload_current_scene()

			KEY_Q:
				get_tree().quit()

			KEY_F:
				var is_fullscreen: bool = (
					DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				)
				var target_mode: int = (
					DisplayServer.WINDOW_MODE_WINDOWED
					if is_fullscreen
					else DisplayServer.WINDOW_MODE_FULLSCREEN
				)
				DisplayServer.window_set_mode(target_mode)
func _on_viewport_gui_focus_changed(node: Control) -> void:
	print(node)
