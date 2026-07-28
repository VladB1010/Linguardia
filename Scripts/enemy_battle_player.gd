class_name EnemyBattlePlayer extends HBoxContainer

signal atb_ready()

@onready var _name:   Label           = $Name
@onready var _health: Label           = $Health
@onready var _mana:   Label           = $Mana
@onready var _anim:   AnimationPlayer = $AnimationPlayer
@onready var _atb:    ATBar           = $ATBar

var data: BattleActor = null

var _pending_text: String = ""

var text: String = "":
	set(val):
		text = val
		if is_node_ready():
			_apply_text(val)
		else:
			_pending_text = val

func _ready() -> void:
	if _pending_text != "":
		_apply_text(_pending_text)
		_pending_text = ""

func _apply_text(val: String) -> void:
	if val.is_empty():
		_name.text   = ""
		_health.text = ""
		_mana.text   = ""
		return

	var parts: PackedStringArray = val.split("  ", false)

	_name.text = parts[0].strip_edges() if parts.size() > 0 else val

	var hp_str:  String = ""
	var def_str: String = ""
	for i in range(parts.size()):
		var p: String = parts[i].strip_edges()
		if p == "HP" and i + 1 < parts.size():
			hp_str = "HP " + parts[i + 1].strip_edges()
		if p.begins_with("🛡"):
			def_str = p

	_health.text = hp_str
	_mana.text   = def_str

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
	_mana.text   = str(int(data.mp)) + "/" + str(data.mp_max)

func _on_data_hp_changed(hp: int, _change: int) -> void:
	_health.text = "HP  " + str(hp)
	if hp == 0:
		modulate = Color.DARK_RED

func _on_data_sp_changed(mp: float) -> void:
	_mana.text = str(int(mp)) + "/" + str(data.mp_max)

func _on_data_acting() -> void:
	highlight(true)
	await get_tree().create_timer(1.0, false).timeout
	if is_instance_valid(self):
		highlight(false)

func highlight(on: bool = true) -> void:
	_anim.play("Highlight" if on else "RESET")

func _on_at_bar_filled() -> void:
	atb_ready.emit()
