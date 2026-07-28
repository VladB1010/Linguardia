class_name EnemyInfo extends HBoxContainer

@onready var _name_label:   Label = $Name
@onready var _health_label: Label = $Health
@onready var _mana_label:   Label = $Mana

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
		_name_label.text   = ""
		_health_label.text = ""
		_mana_label.text   = ""
		return

	var parts: PackedStringArray = val.split("  ", false)

	_name_label.text = parts[0].strip_edges() if parts.size() > 0 else val

	var hp_str:  String = ""
	var def_str: String = ""
	for i in range(parts.size()):
		var p: String = parts[i].strip_edges()
		if p == "HP" and i + 1 < parts.size():
			hp_str = "HP " + parts[i + 1].strip_edges()
		if p.begins_with("🛡"):
			def_str = p

	_health_label.text = hp_str
	_mana_label.text   = def_str

func connect_actor(actor: BattleActor) -> void:
	if actor == null:
		return
	_name_label.text   = actor.name.strip_edges()
	_update_hp(actor.hp, 0)
	_update_defend(actor.defend)
	if not actor.hp_changed.is_connected(_update_hp):
		actor.hp_changed.connect(_update_hp)
	if not actor.defend_changed.is_connected(_update_defend):
		actor.defend_changed.connect(_update_defend)
	if not actor.defeated.is_connected(_on_actor_defeated):
		actor.defeated.connect(_on_actor_defeated)

func _update_hp(hp: int, _change: int = 0) -> void:
	_health_label.text = "HP " + str(hp)

func _update_defend(defend: int) -> void:
	_mana_label.text = "🛡" + str(defend) if defend > 0 else ""

func _on_actor_defeated() -> void:
	text = ""
