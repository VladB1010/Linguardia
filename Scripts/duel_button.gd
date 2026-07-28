extends TextureButton

@onready var _waiting_panel: NinePatchRect    = $NinePatchRect4
@onready var _waiting_label: Label            = $NinePatchRect4/Label
@onready var _wait_anim:     AnimatedSprite2D = $NinePatchRect4/AnimatedSprite2D

const DUEL_SCENE: String = "res://scene/duel_battle.tscn"

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	if _waiting_panel:
		_waiting_panel.visible = false
	pressed.connect(_on_pressed)

	DuelNetwork.matched.connect(_on_matched)
	DuelNetwork.waiting_for_opponent.connect(_on_waiting)
	DuelNetwork.network_error.connect(_on_error)
	DuelNetwork.opponent_disconnected.connect(_on_opponent_dc)

func _on_pressed() -> void:
	if _waiting_panel:
		_waiting_panel.visible = true
		_waiting_label.text    = "Conectare la server…"
	DuelNetwork.connect_and_queue()

func _on_waiting() -> void:
	if _waiting_panel:
		_waiting_panel.visible = true
		_waiting_label.text    = "Se caută adversar…"
		if _wait_anim and _wait_anim.sprite_frames:
			_wait_anim.play("default")

func _on_matched(_room_id: String) -> void:
	DuelNetwork.prepare_duel_data()
	get_tree().change_scene_to_file(DUEL_SCENE)

func _on_error(msg: String) -> void:
	if _waiting_panel:
		_waiting_panel.visible = true
		_waiting_label.text    = "Eroare: " + msg

func _on_opponent_dc() -> void:
	if _waiting_panel:
		_waiting_label.text = "Adversarul s-a deconectat."
