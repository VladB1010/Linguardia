class_name BattleActorButton extends TextureButton

const RECOIL: int = 8
const HIT_TEXT: PackedScene = preload("res://scene/hit_text.tscn")
const IDLE_DURATION: float = 1.2

const SHIELD_PATH: String = "res://assets/broken_shield.png"
const SHIELD_FW:   int    = 40
const SHIELD_FH:   int    = 40
const SHIELD_FC:   int    = 6

var data:           BattleActor       = null
var tween:          Tween             = null
var _idle_tween:    Tween             = null
var _shield_sprite: AnimatedSprite2D  = null
var _had_defend:    bool              = false

@onready var start_pos:         Vector2          = position
@onready var recoil_direction:  int              = 1 if global_position.x > Globals.GAME_SIZE.x * 0.5 else -1
@onready var _anim_sprite:      AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready() -> void:
	texture_normal   = null
	texture_pressed  = null
	texture_hover    = null
	texture_disabled = null
	if _anim_sprite:
		_anim_sprite.play("idle")

func _start_idle() -> void:
	pass

func _stop_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null

func set_data(_data: BattleActor) -> void:
	data = _data
	data.hp_changed.connect(_on_data_hp_changed)
	data.defeated.connect(_on_data_defeated)
	data.acting.connect(_on_data_acting)
	data.defend_absorbed.connect(_on_data_defend_absorbed)

	if data.friendly or Globals.is_duel:
		data.defend_changed.connect(_on_defend_changed)
		_setup_shield_indicator()

func _setup_shield_indicator() -> void:
	if not ResourceLoader.exists(SHIELD_PATH):
		push_warning("BattleActorButton: lipsește " + SHIELD_PATH)
		return

	var tex: Texture2D = load(SHIELD_PATH)
	var frames := SpriteFrames.new()

	frames.add_animation("shield")
	frames.set_animation_loop("shield", true)
	frames.set_animation_speed("shield", 6.0)

	for i in range(4):
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(i * SHIELD_FW, 0, SHIELD_FW, SHIELD_FH)
		frames.add_frame("shield", a)

	frames.add_animation("break")
	frames.set_animation_loop("break", false)
	frames.set_animation_speed("break", 10.0)

	for i in range(4, 9):
		var a := AtlasTexture.new()
		a.atlas = tex
		a.region = Rect2(i * SHIELD_FW, 0, SHIELD_FW, SHIELD_FH)
		frames.add_frame("break", a)

	_shield_sprite = AnimatedSprite2D.new()
	_shield_sprite.sprite_frames = frames
	_shield_sprite.z_index = 10
	_shield_sprite.visible = false

	var base_pos: Vector2 = _anim_sprite.position if _anim_sprite else Vector2(96, 100)
	_shield_sprite.position = base_pos + Vector2(55, -55)

	_shield_sprite.animation_finished.connect(_on_shield_anim_finished)

	add_child(_shield_sprite)

func _on_defend_changed(new_defend: int) -> void:
	if _shield_sprite == null:
		return

	if new_defend > 0:
		_had_defend = true
		_shield_sprite.visible = true

		if _shield_sprite.animation != "shield" or not _shield_sprite.is_playing():
			_shield_sprite.play("shield")

	elif _had_defend:
		_had_defend = false
		_shield_sprite.visible = true
		_shield_sprite.play("break")

func _on_shield_anim_finished() -> void:
	if _shield_sprite and _shield_sprite.animation == "break":
		_shield_sprite.visible = false

func _spawn_hit_text(value: int, color: Color, is_defend: bool = false) -> void:
	var hit_text: Label = HIT_TEXT.instantiate()
	hit_text.text = str(abs(value))
	hit_text.set_color(color)
	add_child(hit_text)
	if is_defend:
		hit_text.add_theme_font_size_override("font_size", 18)
		hit_text.position = Vector2(-10, -10)
	else:
		hit_text.position = Vector2(size.x * 0.7, -10)

func _on_data_hp_changed(hp: int, change: int) -> void:
	if change == 0:
		return
	var color: Color = Color.RED if change < 0 else Color.GREEN
	_spawn_hit_text(change, color)
	if sign(change) == -1:
		recoil()

func _on_data_defend_absorbed(amount: int) -> void:
	_spawn_hit_text(amount, Color.DODGER_BLUE, true)
	_stop_idle()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.WHITE, 0.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func action_slide() -> void:
	_stop_idle()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction * -1), 0.5).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func recoil() -> void:
	_stop_idle()
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position:x", start_pos.x + (RECOIL * recoil_direction), 0.25).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.RED, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", start_pos.x, 0.1).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "self_modulate", Color.WHITE, 0.1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _on_data_defeated() -> void:
	_stop_idle()

func _on_data_acting() -> void:
	action_slide()
