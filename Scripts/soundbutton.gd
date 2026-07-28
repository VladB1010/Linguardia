extends TextureButton

@onready var sprite = $AnimatedSprite2D
@onready var music = $AudioStreamPlayer2D

var muted = false

func _ready():
	music.play()
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	pressed.connect(_on_pressed)

	_update_animation()

func _on_pressed():
	muted = !muted

	if muted:
		music.volume_db = -80.0
	else:
		music.volume_db = 0.0

	_update_animation()

func _on_enter():
	if muted:
		sprite.play("hover_mute")
	else:
		sprite.play("hover_unmute")

func _on_exit():
	_update_animation()

func _update_animation():
	if muted:
		sprite.play("idle_mute")
	else:
		sprite.play("idle_unmute")
