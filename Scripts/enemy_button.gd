class_name EnemyButton extends BattleActorButton

signal atb_ready()

@onready var _sfx: AudioStreamPlayer2D = $SFX

const DUEL_HERO_DATA: Array = [
	{
		"tex": "res://assets/Duel_Magnus.png",
		"fw": 400, "fh": 300,
		"idle": [0, 7], "atk": [8, 13], "death": [14, 20],
		"cursor_offset": Vector2(-150, 110),
	},
	{
		"tex": "res://assets/Duel_Tris.png",
		"fw": 400, "fh": 188,
		"idle": [0, 6], "atk": [7, 13], "death": [14, 22],
		"cursor_offset": Vector2(-120, 90),
	},
	{
		"tex": "res://assets/Duel-Shingen.png",
		"fw": 400, "fh": 188,
		"idle": [0, 7], "atk": [8, 14], "death": [15, 21],
		"cursor_offset": Vector2(-120, 95),
	},
	{
		"tex": "res://assets/Duel-Anna.png",
		"fw": 400, "fh": 250,
		"idle": [0, 7], "atk": [8, 19], "death": [20, 25],
		"cursor_offset": Vector2(-60, 110),
	},
]

const ENEMY_SFX_ATTACK := {
	"Spiridus": preload("res://Audio/attack_elite_spiridus.mp3"),
	"Elite Spiridus": preload("res://Audio/attack_spiridus.mp3"),

	"Varcolac": preload("res://Audio/attack_wolf.mp3"),
	"Elite Varcolac": preload("res://Audio/attack_wolf.mp3"),

	"Strigoi": preload("res://Audio/attack_strigoi.mp3"),

	"Zamolxes": preload("res://Audio/attack_boss.mp3"),
	"Iele": preload("res://Audio/heal.mp3"),
}

const ENEMY_TEXTURES: Dictionary = {
	"Spiridus":        "res://assets/Enemies/Spiridus.png",
	"Elite Spiridus":  "res://assets/Enemies/Elite_Spiridus.png",
	"Varcolac":        "res://assets/Enemies/Varcolac.png",
	"Elite Varcolac":  "res://assets/Enemies/Elite_Varcolac.png",
	"Strigoi":         "res://assets/Enemies/Strigoi.png",
	"Iele":            "res://assets/Enemies/Iele.png",
	"Liliac":             "res://assets/Enemies/bat.png",
	"Lycan1":          "res://assets/Enemies/Lycan1.png",
	"Lycan2":          "res://assets/Enemies/Lycan2.png",
}

const ENEMY_TEXTURE_PAGES: Dictionary = {
	"Zamolxes": [
		["res://assets/Enemies/Zamolxes_p1.png", 10],
		["res://assets/Enemies/Zamolxes_p2.png", 10],
		["res://assets/Enemies/Zamolxes_p3.png", 9],
	],
}

const ENEMY_FRAME_DATA: Dictionary = {
	"Spiridus": {
		"fw": 400, "fh": 188, "fc": 33,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  8, "atk_end":  19,
		"death_start": 20,
		"cursor_offset": Vector2(-40, 110),
	},
	"Elite Spiridus": {
		"fw": 400, "fh": 188, "fc": 26,
		"idle_start": 0, "idle_end": 6,
		"atk_start":  7, "atk_end":  13,
		"death_start": 14,
		"cursor_offset": Vector2(-40, 110),
	},
	"Varcolac": {
		"fw": 400, "fh": 250, "fc": 32,
		"idle_start": 0, "idle_end": 6,
		"atk_start":  7, "atk_end":  23,
		"death_start": 24,
		"cursor_offset": Vector2(-170, 100),
	},
	"Elite Varcolac": {
		"fw": 400, "fh": 250, "fc": 32,
		"idle_start": 0, "idle_end": 6,
		"atk_start":  7, "atk_end":  23,
		"death_start": 24,
		"cursor_offset": Vector2(-170, 100),
	},
	"Strigoi": {
		"fw": 300, "fh": 300, "fc": 28,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  8, "atk_end":  19,
		"death_start": 20,
		"cursor_offset": Vector2(-140, 100),
	},
	"Zamolxes": {
		"fw": 600, "fh": 600, "fc": 29,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  8, "atk_end":  18,
		"death_start": 19,
		"cursor_offset": Vector2(-150, 120),
	},
	"Iele": {
		"fw": 400, "fh": 250, "fc": 23,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  8, "atk_end":  15,
		"death_start": 16,
		"cursor_offset": Vector2(-150, 120),
	},
	"Liliac": {
		"fw": 166, "fh": 296, "fc": 16,
		"idle_start": 0, "idle_end": 6,
		"atk_start":  7, "atk_end":  11,
		"death_start": 12,
		"cursor_offset": Vector2(-30, 120),
		"no_flip": true,
	},
	"Lycan1": {
		"fw": 208, "fh": 188, "fc": 8,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  0, "atk_end":  7,
		"death_start": 0,
		"cursor_offset": Vector2(-70, 50),
	},
	"Lycan2": {
		"fw": 208, "fh": 188, "fc": 8,
		"idle_start": 0, "idle_end": 7,
		"atk_start":  0, "atk_end":  7,
		"death_start": 0,
		"cursor_offset": Vector2(-70, 50),
	},
}

@onready var _at_bar:     ATBar = $ATBar
@onready var _name_label: Label = $NameLabel

var _is_dead:   bool   = false
var _fd:        Dictionary = {}
var _is_healer: bool   = false

const HEALER_ENEMIES: Array[String] = ["Iele"]
const IELE_HEAL_AMOUNT: int = 3
const IELE_ATB_SPEED:   float = 0.5
const IELE_HEAL_EVERY:  int   = 3

var _heal_count: int = 0

func _ready() -> void:
	var enemy_names: Array = Data.enemies.keys()
	var my_idx: int        = get_index()

	if my_idx >= enemy_names.size():
		visible = false
		_at_bar.stop()
		return

	var my_name: String   = enemy_names[my_idx]
	set_data(Data.enemies[my_name].duplicate_custom())

	if _name_label:
		_name_label.text = data.name

	if Globals.is_duel:
		_setup_duel_animation(my_idx)
		_at_bar.reset(false)
		_at_bar.stop()
		super._ready()
		return

	var sprite_key: String = _get_sprite_key(data.name)
	_is_healer = sprite_key in HEALER_ENEMIES
	if _is_healer:
		_at_bar.speed_mult = IELE_ATB_SPEED

	_setup_animation(data.name)
	super._ready()

func force_spawn(actor: BattleActor) -> void:
	visible = true
	texture_normal  = null
	texture_pressed = null
	texture_hover   = null
	set_data(actor)
	if _name_label:
		_name_label.text = actor.name
	_setup_animation(actor.name)
	_at_bar.reset()
	start_pos = position

func play_enemy_sfx(sprite_key: String) -> void:
	if not ENEMY_SFX_ATTACK.has(sprite_key):
		return

	_sfx.stream = ENEMY_SFX_ATTACK[sprite_key]
	_sfx.pitch_scale = randf_range(0.95, 1.05)
	_sfx.play()
	await get_tree().create_timer(3.0).timeout
	_sfx.stop()

func _setup_animation(enemy_name: String) -> void:
	if not _anim_sprite:
		return

	var sprite_key: String = _get_sprite_key(enemy_name)

	if not (ENEMY_TEXTURES.has(sprite_key) or ENEMY_TEXTURE_PAGES.has(sprite_key)):
		push_warning("EnemyButton: nicio textură pentru '" + sprite_key + "'")
		return

	if not ENEMY_FRAME_DATA.has(sprite_key):
		push_warning("EnemyButton: nicio definiție cadre pentru '" + sprite_key + "'")
		return

	_fd = ENEMY_FRAME_DATA[sprite_key]

	var fw: int = _fd["fw"]
	var fh: int = _fd["fh"]
	var fc: int = _fd["fc"]

	var frames := SpriteFrames.new()

	_add_anim(sprite_key, frames, "idle", fw, fh,
		_fd["idle_start"], _fd["idle_end"], true, 8.0)

	_add_anim(sprite_key, frames, "attack", fw, fh,
		_fd["atk_start"], _fd["atk_end"], false, 12.0)

	var death_end: int = fc - 1
	_add_anim(sprite_key, frames, "death", fw, fh,
		_fd["death_start"], death_end, false, 8.0)

	_anim_sprite.flip_h       = not _fd.get("no_flip", false)
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation_finished.connect(_on_anim_finished)
	_anim_sprite.play("idle")

func _resolve_frame_source(sprite_key: String, global_frame: int) -> Array:
	if ENEMY_TEXTURE_PAGES.has(sprite_key):
		var offset: int = 0
		for page: Array in ENEMY_TEXTURE_PAGES[sprite_key]:
			var path: String  = page[0]
			var count: int    = page[1]
			if global_frame < offset + count:
				var tex: Texture2D = load(path)
				return [tex, global_frame - offset]
			offset += count
		push_error("EnemyButton: cadrul " + str(global_frame) + " nu există pentru '" + sprite_key + "' (total pagini: " + str(offset) + " cadre)")
		return [null, 0]

	var tex: Texture2D = load(ENEMY_TEXTURES[sprite_key])
	return [tex, global_frame]

func _add_anim(sprite_key: String, frames: SpriteFrames, anim_name: String,
		fw: int, fh: int, start: int, end_frame: int,
		loop: bool, speed: float) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for i in range(start, end_frame + 1):
		var resolved: Array     = _resolve_frame_source(sprite_key, i)
		var tex: Texture2D      = resolved[0]
		var local_index: int    = resolved[1]
		if tex == null:
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas  = tex
		atlas.region = Rect2(local_index * fw, 0, fw, fh)
		frames.add_frame(anim_name, atlas)

func _get_sprite_key(enemy_name: String) -> String:
	return enemy_name.strip_edges().rstrip(" 0123456789")

func _setup_duel_animation(hero_index: int) -> void:
	if not _anim_sprite:
		return
	if hero_index < 0 or hero_index >= DUEL_HERO_DATA.size():
		push_warning("EnemyButton: index erou duel invalid: " + str(hero_index))
		return

	var d: Dictionary = DUEL_HERO_DATA[hero_index]
	if not ResourceLoader.exists(d["tex"]):
		push_warning("EnemyButton: lipsește asset-ul de duel " + d["tex"])
		return

	var tex: Texture2D = load(d["tex"])
	var fw: int = d["fw"]
	var fh: int = d["fh"]
	var frames := SpriteFrames.new()

	_add_duel_anim(frames, "idle",   tex, fw, fh, d["idle"][0],  d["idle"][1],  true,   8.0)
	_add_duel_anim(frames, "attack", tex, fw, fh, d["atk"][0],   d["atk"][1],   false, 12.0)
	_add_duel_anim(frames, "death",  tex, fw, fh, d["death"][0], d["death"][1], false,  8.0)

	_anim_sprite.flip_h        = true
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation_finished.connect(_on_anim_finished)
	_anim_sprite.play("idle")

	_fd = {"cursor_offset": d.get("cursor_offset", Vector2(-70, 50))}

func _add_duel_anim(frames: SpriteFrames, anim_name: String, tex: Texture2D,
		fw: int, fh: int, start: int, end_frame: int, loop: bool, speed: float) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for i in range(start, end_frame + 1):
		var a := AtlasTexture.new()
		a.atlas  = tex
		a.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(anim_name, a)

func get_cursor_offset() -> Vector2:
	if _fd.has("cursor_offset"):
		return _fd["cursor_offset"]
	return Vector2(-70, 50)

func _on_anim_finished() -> void:
	if _is_dead:
		return
	if _anim_sprite and _anim_sprite.animation == "attack":
		_anim_sprite.play("idle")

func _on_data_acting() -> void:
	if _anim_sprite:
		_anim_sprite.play("attack")

	var sprite_key := _get_sprite_key(data.name)
	play_enemy_sfx(sprite_key)

	action_slide()

func reset(force: bool = false) -> void:
	if Globals.is_duel and not force:
		return
	_at_bar.reset()

func _on_at_bar_filled() -> void:
	if _is_healer:
		_do_heal()
	else:
		atb_ready.emit()

func _do_heal() -> void:
	_heal_count += 1

	if _heal_count < IELE_HEAL_EVERY:
		_at_bar.reset()
		return

	_heal_count = 0

	if _anim_sprite:
		_anim_sprite.play("attack")
	var sprite_key := "Iele"
	play_enemy_sfx(sprite_key)
	var alive_enemies: Array = []
	var enemies_menu: Node = get_parent()

	for child in enemies_menu.get_children():
		if child is EnemyButton and child.data != null and child.data.has_hp():
			alive_enemies.append(child.data)

	if not alive_enemies.is_empty():
		var target: BattleActor = alive_enemies.pick_random()
		target.healhurt(IELE_HEAL_AMOUNT)

	await get_tree().create_timer(0.6, false).timeout
	_at_bar.reset()

func _on_data_defeated() -> void:
	_is_dead = true
	_stop_idle()

	disabled = true
	focus_mode = Control.FOCUS_NONE

	if has_focus():
		release_focus()
		var parent_menu = get_parent()
		if parent_menu and parent_menu.has_method("button_focus"):
			parent_menu.button_focus(get_index())

	if _anim_sprite:
		if _anim_sprite.sprite_frames.has_animation("death"):
			_anim_sprite.play("death")
		else:
			_anim_sprite.stop()
	_at_bar.stop()
	await get_tree().create_timer(1.5, false).timeout
	queue_free()
