extends TextureButton

@onready var sprite = $AnimatedSprite2D

const BATTLE_SCENE: String = "res://scene/battle.tscn"

func _ready():
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)

func _on_enter():
	sprite.play("hover")

func _on_exit():
	sprite.play("normal")

func _on_down():
	sprite.play("pressed")

func _on_up():
	sprite.play("hover")

func _on_pressed() -> void:
	if disabled:
		return
	disabled = true
	WaveManager.reset(WaveManager.difficulty)

	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(BATTLE_SCENE)
