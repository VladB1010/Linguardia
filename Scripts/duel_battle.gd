extends Control

enum DuelState {
	MY_TURN_FILL,
	MY_TURN_ACTION,
	MY_TURN_MINI,
	OPPONENT_TURN,
	GAME_OVER
}

const HEROES: Dictionary = {
	"Arthur": {
		"hp": 150, "str": 12, "spd": 0.7,
		"tex": "res://Asset/Heroes/Duel_Magnus.png",
		"fw": 400, "fh": 285, "fc": 20,
		"idle": [0, 7], "atk": [8, 14], "death": [15, 19],
	},
	"Sofia": {
		"hp": 100, "str": 18, "spd": 1.2,
		"tex": "res://Asset/Heroes/Duel_Tris.png",
		"fw": 320, "fh": 163, "fc": 25,
		"idle": [0, 7], "atk": [8, 16], "death": [17, 24],
	},
	"Eliza": {
		"hp": 110, "str": 8, "spd": 0.9,
		"tex": "res://Asset/Heroes/Duel-Anna.png",
		"fw": 160, "fh": 192, "fc": 50,
		"idle": [0, 12], "atk": [13, 34], "death": [35, 49],
	},
	"Nyssa": {
		"hp": 80, "str": 22, "spd": 0.8,
		"tex": "res://Asset/Heroes/Duel-Shingen.png",
		"fw": 320, "fh": 170, "fc": 25,
		"idle": [0, 7], "atk": [8, 16], "death": [17, 24],
	},
}

const ATB_SPEED_BASE: float = 0.04
const ATB_MAX:        float = 100.0

@onready var _player_sprite:  AnimatedSprite2D = $PlayerSide/HeroSprite
@onready var _player_hp_bar:  ProgressBar      = $PlayerSide/HPBar
@onready var _player_hp_lbl:  Label            = $PlayerSide/HPLabel
@onready var _player_name:    Label            = $PlayerSide/NameLabel
@onready var _atbar_slot:     Control          = $PlayerSide/ATBarSlot
@onready var _def_lbl:        Label            = $PlayerSide/DefendLabel

@onready var _opp_sprite:     AnimatedSprite2D = $OpponentSide/HeroSprite
@onready var _opp_hp_bar:     ProgressBar      = $OpponentSide/HPBar
@onready var _opp_hp_lbl:     Label            = $OpponentSide/HPLabel
@onready var _opp_name:       Label            = $OpponentSide/NameLabel
@onready var _opp_def_lbl:    Label            = $OpponentSide/OppDefendLabel

@onready var _turn_lbl:       Label            = $CenterUI/TurnLabel
@onready var _action_panel:   HBoxContainer    = $CenterUI/ActionPanel
@onready var _attack_btn:     Button           = $CenterUI/ActionPanel/AttackBtn
@onready var _defend_btn:     Button           = $CenterUI/ActionPanel/DefendBtn
@onready var _special_btn:    Button           = $CenterUI/ActionPanel/SpecialBtn

@onready var _minigame:       Minigame         = $Minigame
@onready var _result_panel:   Control          = $ResultPanel
@onready var _result_lbl:     Label            = $ResultPanel/ResultLabel
@onready var _return_btn:     Button           = $ResultPanel/ReturnBtn

var _state:      DuelState = DuelState.OPPONENT_TURN
var _my_hero:    String    = ""
var _opp_hero:   String    = ""

var _my_hp:      int  = 100
var _my_hp_max:  int  = 100
var _my_str:     int  = 10
var _my_def:     int  = 0
var _my_shield:  bool = false

var _opp_hp:     int  = 100
var _opp_hp_max: int  = 100
var _opp_def:    int  = 0
var _opp_shield: bool = false

var _atb_value:  float = 0.0
var _atb_speed:  float = ATB_SPEED_BASE
var _atb_active: bool  = false

var _atb_bar:    ProgressBar = null

func _ready() -> void:
	_my_hero  = Globals.duel_my_hero
	_opp_hero = Globals.duel_opponent_hero

	_setup_hero(_my_hero,  _player_sprite, true)
	_setup_hero(_opp_hero, _opp_sprite,    false)
	_setup_atbar()

	var my_d:   Dictionary = HEROES[_my_hero]
	var opp_d:  Dictionary = HEROES[_opp_hero]

	_my_hp       = my_d["hp"];  _my_hp_max  = my_d["hp"]
	_my_str      = my_d["str"]
	_atb_speed   = ATB_SPEED_BASE * my_d["spd"]

	_opp_hp      = opp_d["hp"]; _opp_hp_max = opp_d["hp"]

	_refresh_hp()

	_attack_btn.pressed.connect(_on_attack)
	_defend_btn.pressed.connect(_on_defend)
	_special_btn.pressed.connect(_on_special)
	_return_btn.pressed.connect(_on_return)

	_minigame.completed.connect(_on_minigame_done)

	DuelNetwork.opponent_action_received.connect(_on_opp_action)
	DuelNetwork.opponent_disconnected.connect(_on_opp_dc)

	if Globals.duel_my_role == "p1":
		_start_my_turn()
	else:
		_set_state(DuelState.OPPONENT_TURN)

func _setup_atbar() -> void:
	_atb_bar = ProgressBar.new()
	_atb_bar.min_value = 0.0
	_atb_bar.max_value = ATB_MAX
	_atb_bar.value     = 0.0
	_atb_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_atbar_slot.add_child(_atb_bar)

func _process(delta: float) -> void:
	if not _atb_active:
		return
	_atb_value = min(_atb_value + _atb_speed * 60.0 * delta, ATB_MAX)
	_atb_bar.value = _atb_value
	if _atb_value >= ATB_MAX:
		_atb_active = false
		_set_state(DuelState.MY_TURN_ACTION)

func _setup_hero(hero_name: String, sprite: AnimatedSprite2D, flip: bool) -> void:
	if not HEROES.has(hero_name):
		return
	var d:   Dictionary  = HEROES[hero_name]
	var tex: Texture2D   = null
	if ResourceLoader.exists(d["tex"]):
		tex = load(d["tex"])
	else:
		push_warning("DuelBattle: lipsește " + d["tex"])
		return

	var fw:  int = d["fw"];  var fh: int = d["fh"]
	var frames := SpriteFrames.new()

	_add_duel_anim(frames, "idle",   tex, fw, fh, d["idle"][0],  d["idle"][1],  true,  8.0)
	_add_duel_anim(frames, "attack", tex, fw, fh, d["atk"][0],   d["atk"][1],   false, 12.0)
	_add_duel_anim(frames, "death",  tex, fw, fh, d["death"][0], d["death"][1], false,  8.0)

	sprite.sprite_frames = frames
	sprite.flip_h        = flip
	sprite.animation_finished.connect(_on_sprite_anim_finished.bind(sprite))
	sprite.play("idle")

	if sprite == _player_sprite:
		_player_name.text = hero_name
		_player_hp_bar.max_value = HEROES[hero_name]["hp"]
	else:
		_opp_name.text = hero_name
		_opp_hp_bar.max_value = HEROES[hero_name]["hp"]

func _add_duel_anim(frames: SpriteFrames, anim: String, tex: Texture2D,
		fw: int, fh: int, s: int, e: int, loop: bool, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	frames.set_animation_speed(anim, fps)
	for i in range(s, e + 1):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(anim, a)

func _on_sprite_anim_finished(sprite: AnimatedSprite2D) -> void:
	if sprite.animation == "attack":
		sprite.play("idle")

func _refresh_hp() -> void:
	_player_hp_bar.value = _my_hp
	_player_hp_lbl.text  = "%d / %d" % [_my_hp, _my_hp_max]
	_opp_hp_bar.value    = _opp_hp
	_opp_hp_lbl.text     = "%d / %d" % [_opp_hp, _opp_hp_max]

	_def_lbl.text     = "🛡 %d" % _my_def  if _my_def > 0  else ""
	_opp_def_lbl.text = "🛡 %d" % _opp_def if _opp_def > 0 else ""

	if _my_shield:
		_def_lbl.text = "🛡 SHIELD"
	if _opp_shield:
		_opp_def_lbl.text = "🛡 SHIELD"

func _set_state(new_state: DuelState) -> void:
	_state = new_state
	_action_panel.visible = false

	match new_state:
		DuelState.MY_TURN_FILL:
			_turn_lbl.text  = "ATB se încarcă…"
			_atb_value      = 0.0
			_atb_bar.value  = 0.0
			_atb_active     = true

		DuelState.MY_TURN_ACTION:
			_turn_lbl.text        = "Rândul tău! Alege acțiunea:"
			_action_panel.visible = true
			_special_btn.text     = _special_label()

		DuelState.MY_TURN_MINI:
			_turn_lbl.text = "Minijoc de atac!"

		DuelState.OPPONENT_TURN:
			_atb_active    = false
			_atb_bar.value = 0.0
			_turn_lbl.text = "Rândul adversarului… așteptare"

		DuelState.GAME_OVER:
			_atb_active = false

func _start_my_turn() -> void:
	_set_state(DuelState.MY_TURN_FILL)

func _special_label() -> String:
	match _my_hero:
		"Magnus":  return "✦ Shield"
		"Tris":    return "✦ Blitz ×2"
		"Anna":    return "✦ Heal +30"
		"Shingen": return "✦ Nova ×3"
		_:         return "✦ Special"

func _on_attack() -> void:
	if _state != DuelState.MY_TURN_ACTION:
		return
	_set_state(DuelState.MY_TURN_MINI)
	_action_panel.visible = false
	_player_sprite.play("attack")
	_minigame.show()
	_minigame.start()

func _on_defend() -> void:
	if _state != DuelState.MY_TURN_ACTION:
		return
	_action_panel.visible = false

	var pts: int = 6
	_my_def += pts
	_refresh_hp()
	DuelNetwork.send_defend_result(pts)
	_end_my_turn()

func _on_special() -> void:
	if _state != DuelState.MY_TURN_ACTION:
		return
	_action_panel.visible = false
	_player_sprite.play("attack")

	match _my_hero:
		"Magnus":
			_my_shield = true
			_refresh_hp()
			DuelNetwork.send_action("special", {"effect": "shield"})
			_end_my_turn()

		"Tris":
			var dmg: int = roundi(_my_str * 2.0)
			_apply_damage_to_opponent(dmg)
			DuelNetwork.send_action("action", {"action_type": "attack", "damage": dmg, "piercing": true})
			_end_my_turn()

		"Anna":
			_my_hp = min(_my_hp + 30, _my_hp_max)
			_refresh_hp()
			DuelNetwork.send_action("special", {"effect": "heal", "amount": 30})
			_end_my_turn()

		"Shingen":
			var dmg: int = roundi(_my_str * 3.0)
			_apply_damage_to_opponent(dmg)
			DuelNetwork.send_action("action", {"action_type": "attack", "damage": dmg})
			_end_my_turn()

func _on_minigame_done(multiplier: float) -> void:
	_minigame.hide()

	var dmg: int = roundi(_my_str * multiplier)
	dmg = max(dmg, 1)

	_apply_damage_to_opponent(dmg)

	var def_gain: int = 0
	if _my_hero == "Magnus":
		def_gain = 1
		_my_def += def_gain
		_refresh_hp()

	DuelNetwork.send_action("attack", {"damage": dmg, "defend_gain": def_gain})
	_end_my_turn()

func _apply_damage_to_opponent(dmg: int) -> void:
	_opp_sprite.play("attack")

	if _opp_shield:
		_opp_shield = false
		_refresh_hp()
		return

	if _opp_def > 0:
		var absorbed: int = min(_opp_def, dmg)
		_opp_def -= absorbed
		dmg      -= absorbed

	_opp_hp = max(_opp_hp - dmg, 0)
	_refresh_hp()

	if _opp_hp <= 0:
		_finish_game(true)

func _end_my_turn() -> void:
	await get_tree().create_timer(0.5, false).timeout
	if _state == DuelState.GAME_OVER:
		return
	_set_state(DuelState.OPPONENT_TURN)

func _on_opp_action(data: Dictionary) -> void:
	if _state == DuelState.GAME_OVER:
		return

	var action_type: String = data.get("action_type", data.get("type", ""))

	match action_type:
		"attack":
			_receive_opp_attack(data)

		"defend_result":
			var pts: int = data.get("points", 0)
			_opp_def += pts
			_refresh_hp()
			await get_tree().create_timer(0.3, false).timeout
			_start_my_turn()

		"special":
			_receive_opp_special(data)

		"action":
			var at: String = data.get("action_type", "")
			if at == "attack":
				_receive_opp_attack(data)

func _receive_opp_attack(data: Dictionary) -> void:
	_opp_sprite.play("attack")
	var dmg: int     = data.get("damage", 0)
	var piercing: bool = data.get("piercing", false)
	var def_gain: int = data.get("defend_gain", 0)

	if def_gain > 0:
		_opp_def += def_gain
		_refresh_hp()

	await get_tree().create_timer(0.4, false).timeout

	if _my_shield:
		_my_shield = false
		_refresh_hp()
		await get_tree().create_timer(0.3, false).timeout
		_start_my_turn()
		return

	if _my_def > 0 and not piercing:
		var absorbed: int = min(_my_def, dmg)
		_my_def -= absorbed
		dmg     -= absorbed

	_my_hp = max(_my_hp - dmg, 0)
	_refresh_hp()

	if _my_hp <= 0:
		_finish_game(false)
		return

	await get_tree().create_timer(0.3, false).timeout
	_start_my_turn()

func _receive_opp_special(data: Dictionary) -> void:
	match data.get("effect", ""):
		"shield":
			_opp_shield = true
			_refresh_hp()
			await get_tree().create_timer(0.3, false).timeout
			_start_my_turn()

		"heal":
			_refresh_hp()
			await get_tree().create_timer(0.3, false).timeout
			_start_my_turn()

		_:
			_start_my_turn()

func _on_opp_dc() -> void:
	if _state == DuelState.GAME_OVER:
		return
	_result_lbl.text = "Adversarul s-a\ndeconectat.\n\nVICTORIE (WO)"
	_set_state(DuelState.GAME_OVER)
	_result_panel.visible = true

func _finish_game(i_won: bool) -> void:
	_set_state(DuelState.GAME_OVER)
	DuelNetwork.disconnect_clean()

	if i_won:
		_player_sprite.play("idle")
		_opp_sprite.play("death")
		_result_lbl.text = "Victory	!"
		_result_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	else:
		_player_sprite.play("death")
		_opp_sprite.play("idle")
		_result_lbl.text = "💀 ÎNFRÂNGERE"
		_result_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))

	await get_tree().create_timer(0.8, false).timeout
	_result_panel.visible = true

func _on_return() -> void:
	DuelNetwork.disconnect_clean()
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
