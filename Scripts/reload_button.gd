extends TextureButton

@onready var sprite = $AnimatedSprite2D

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)

	sprite.play("hover")

func _input(event):
	if event is InputEventKey \
	and event.pressed \
	and event.keycode == KEY_R:
		_restart()

func _on_pressed():
	_restart()

func _restart():
	disabled = true

	sprite.play("click")
	await sprite.animation_finished

	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_enter():
	if sprite.animation != "click":
		sprite.play("hover")

func _on_exit():
	if sprite.animation != "click":
		sprite.play("idle")
