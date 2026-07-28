extends TextureButton

@onready var sprite = $AnimatedSprite2D

const MAIN_MENU_SCENE: String = "res://scene/main_menu.tscn"
const CLICK_ANIM_DURATION: float = 0.3

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode = Control.FOCUS_NONE

	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)

	sprite.animation = "hover"
	sprite.stop()

func _on_pressed():
	_go_to_main_menu()

func _go_to_main_menu():
	disabled = true

	sprite.play("click")

	await get_tree().create_timer(CLICK_ANIM_DURATION, true).timeout

	get_tree().paused = false
	WaveManager.reset(WaveManager.difficulty)
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_enter():
	if sprite.animation != "click":
		sprite.play("hover")

func _on_exit():
	if sprite.animation != "click":
		_show_neutral()

func _show_neutral() -> void:
	sprite.animation = "hover"
	sprite.stop()
