class_name BattleActor extends Resource

signal hp_changed(hp,change)
signal defeated()
signal acting()
signal mp_changed(mp)
signal defend_changed(defend)
signal defend_absorbed(amount)
var sprite_id: String = ""
var name: String  = "Not Set"
var hp_max: int = 50
var hp: int = hp_max
var strength: int = 3
var texture: Texture = null
var friendly:bool = false
var defend: int = 0

var mp_max: int = 5
var sp_gain: float = 1.0
var mp: float = 6.0

func _init(_hp: int = hp_max, _strength: int = strength) -> void:
	hp_max = _hp
	hp = _hp
	strength = _strength

func set_names_custom(value: String) -> void:
	name = value

	if !friendly:
		var path_name := sprite_id
		if path_name == "":
			path_name = name

		path_name = path_name.to_lower().strip_edges().replace(" ", "-")

		var path := "res://Asset/Enemies/%s.png" % path_name

		if ResourceLoader.exists(path):
			texture = load(path)
		else:
			push_warning("Missing texture: " + path)
func healhurt(value: int) -> void:
	var hp_start : int = hp
	var change : int = 0
	if value < 0 and defend > 0:
		var absorbed: int = mini(-value, defend)
		defend -= absorbed
		defend_changed.emit(defend)
		defend_absorbed.emit(absorbed)
		value += absorbed
		if value == 0:
			hp_changed.emit(hp, 0)
			return
	hp += value
	hp = clampi(hp, 0, hp_max)
	change = hp - hp_start
	hp_changed.emit(hp, change)

	if !has_hp():
		defeated.emit()

func gain_defend(amount: int = 4) -> void:
	defend += amount
	defend_changed.emit(defend)

func gain_sp(amount: float = -1.0) -> void:
	var actual: float = amount if amount >= 0.0 else sp_gain
	mp = minf(mp + actual, float(mp_max))
	mp_changed.emit(mp)

func can_special() -> bool:
	return mp >= float(mp_max)

func consume_sp() -> void:
	mp = 0.0
	mp_changed.emit(mp)

func duplicate_custom() -> BattleActor:
	var dup: BattleActor = BattleActor.new(hp_max, strength)
	dup.hp       = hp
	dup.name     = name
	dup.texture  = texture
	dup.friendly = friendly
	dup.defend   = defend
	dup.mp       = mp
	dup.mp_max   = mp_max
	dup.sp_gain  = sp_gain
	return dup

func act() -> void:
	acting.emit()

func has_hp() -> bool:
	return hp > 0

func can_act() -> bool:
	return has_hp()
