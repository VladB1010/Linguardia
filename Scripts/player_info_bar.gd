class_name PlayerInfoBar extends HBoxContainer

signal atb_ready()

@onready var data: BattleActor = Data.party[get_index()]
@onready var _name: Label = $Name
@onready var _health : Label = $Health
@onready var _mana : Label = $Mana
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _atb: ATBar = $ATBar

func _ready() -> void:
	_anim.play("RESET")
	_name.text = data.name
	_health.text = "HP  "+ str(data.hp)
	_mana.text = str(data.mp)
	data.hp_changed.connect(_on_data_hp_changed)
	data.mp_changed.connect(_on_data_sp_changed)
	_mana.text = str(int(data.mp)) + "/" + str(data.mp_max)

func _on_data_hp_changed(hp: int, change: int) -> void:
	_health.text ="HP  "+ str(hp)
	if hp == 0:
		modulate = Color.DARK_RED
		_atb.reset(false)
		_atb.stop()

func _on_data_sp_changed(mp: float) -> void:
	_mana.text = str(int(mp)) + "/" + str(data.mp_max)

func highlight(on: bool = true ) -> void:
	var anim: String  = "Highlight" if on else "RESET"
	_anim.play(anim)

func _on_at_bar_filled() -> void:
	atb_ready.emit()

func reset()-> void:
	_atb.reset()

func stop() -> void:
	_atb.stop()
func _on_animation_player_tree_exiting() -> void:
	pass
