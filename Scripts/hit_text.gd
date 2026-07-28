extends Label

const SPEED : float  = 0.05

func _process(delta: float) -> void:
	position.y -= SPEED

func set_color(color: Color) -> void:
	add_theme_color_override("font_color", color)

func _on_free_timeout() -> void:
	queue_free()
