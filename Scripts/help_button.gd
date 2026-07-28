extends TextureButton

@onready var sprite = $AnimatedSprite2D
@onready var pause_overlay = $NinePatchRect
@onready var _close_button: TextureButton = $NinePatchRect/CloseButton

var paused := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)

	if _close_button:
		_close_button.process_mode = Node.PROCESS_MODE_ALWAYS
		_close_button.pressed.connect(_on_pressed)

	pause_overlay.visible = false
	sprite.play("idle")

func _on_pressed():
	_toggle_pause()

func _toggle_pause():
	paused = !paused
	get_tree().paused = paused

	sprite.play("click")

	if paused:
		pause_overlay.visible = true
	else:
		pause_overlay.visible = false

	await sprite.animation_finished

	if is_hovered():
		sprite.play("hover")
	else:
		sprite.play("idle")

func _on_enter():
	if sprite.animation != "click":
		sprite.play("idle")

func _on_exit():
	if sprite.animation != "click":
		sprite.play("idle")
