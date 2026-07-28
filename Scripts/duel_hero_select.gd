class_name DuelHeroSelect extends Control

signal atb_ready()

@onready var _name:   Label           = $Name
@onready var _health: Label           = $Health
@onready var _mana:   Label           = $Mana
@onready var _anim:   AnimationPlayer = $AnimationPlayer
@onready var _atb:    ATBar           = $ATBar

var data: BattleActor = null

func setup(_data: BattleActor) -> void:
	if not is_node_ready():
		await ready

	data = _data
	_anim.play("RESET")
	_refresh()

	data.hp_changed.connect(_on_data_hp_changed)
	data.mp_changed.connect(_on_data_sp_changed)
	data.acting.connect(_on_data_acting)

	_atb.stop()

func _refresh() -> void:
	if data == null:
		return
	_name.text   = data.name
	_health.text = "HP  " + str(data.hp)
	_mana.text   = str(int(data.mp))

func _on_data_hp_changed(hp: int, _change: int) -> void:
	_health.text = "HP  " + str(hp)
	if hp == 0:
		modulate = Color.DARK_RED

func _on_data_sp_changed(mp: float) -> void:
	_mana.text = str(int(mp))

func _on_data_acting() -> void:
	highlight(true)
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(self):
		highlight(false)

func highlight(on: bool = true) -> void:
	_anim.play("Highlight" if on else "RESET")

func _on_at_bar_filled() -> void:
	atb_ready.emit()
