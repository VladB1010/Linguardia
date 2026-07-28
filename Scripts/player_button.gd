class_name PlayerButton extends BattleActorButton

const FRAME_W: int = 400
const FRAME_H: int = 188

const HERO_DATA: Array = [
	{
		"texture": "res://assets/Heroes/Magnus.png",
		"idle_start": 0, "idle_end": 6,
		"attack_start": 7, "attack_end": 14,
		"death_start": 15, "death_end": 28,
		"total_frames": 29
	},
	{
		"texture": "res://assets/Heroes/Tris.png",
		"idle_start": 0, "idle_end": 6,
		"attack_start": 7, "attack_end": 14,
		"death_start": 15, "death_end": 28,
		"total_frames": 29
	},

	{
		"texture": "res://assets/Heroes/Shingen.png",
		"idle_start": 0, "idle_end": 6,
		"attack_start": 7, "attack_end": 20,
		"death_start": 21, "death_end": 32,
		"total_frames": 33
	},
	{
		"texture": "res://assets/Heroes/anna.png",
		"idle_start": 0, "idle_end": 9,
		"attack_start": 10, "attack_end": 21,
		"death_start": 22, "death_end": 33,
		"total_frames": 34
	},
]

const SPECIAL_SCENES: Array = [
	"res://assets/Heroes/Magnus_special.png",
	"res://assets/Heroes/Shingen_special.png",
	"res://assets/Heroes/Tris_special.png",
	"res://Asset/Heroes/anna_special.png",
]

var _hero_index: int = 0
var _is_dead: bool = false

func _ready() -> void:
	_hero_index = get_index()
	set_data(Data.party[_hero_index])
	_setup_animation(_hero_index)
	super._ready()

func _setup_animation(hero_index: int) -> void:
	if not _anim_sprite:
		return
	if hero_index >= HERO_DATA.size():
		return

	var hd: Dictionary = HERO_DATA[hero_index]
	var texture: Texture2D = load(hd["texture"])
	if not texture:
		push_error("PlayerButton: cannot load " + hd["texture"])
		return

	var frames := SpriteFrames.new()

	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 8.0)
	for i in range(hd["idle_start"], hd["idle_end"] + 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("idle", atlas)

	frames.add_animation("attack")
	frames.set_animation_loop("attack", false)
	frames.set_animation_speed("attack", 10.0)
	for i in range(hd["attack_start"], hd["attack_end"] + 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("attack", atlas)

	frames.add_animation("death")
	frames.set_animation_loop("death", false)
	frames.set_animation_speed("death", 10.0)
	for i in range(hd["death_start"], hd["death_end"] + 1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
		frames.add_frame("death", atlas)

	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation_finished.connect(_on_anim_sprite_finished)
	_anim_sprite.play("idle")

func _on_anim_sprite_finished() -> void:
	if _is_dead:
		return
	if _anim_sprite and _anim_sprite.animation == "attack":
		_anim_sprite.play("idle")

func play_attack() -> void:
	if _is_dead or not _anim_sprite:
		return
	_anim_sprite.play("attack")

func _on_data_acting() -> void:
	play_attack()
	action_slide()

func _on_data_defeated() -> void:
	_is_dead = true
	_stop_idle()
	if _anim_sprite:
		_anim_sprite.play("death")
	self_modulate = Color(1.0, 1.0, 1.0, 1.0)
	await get_tree().create_timer(1.5, false).timeout
	self_modulate = Color(1.0, 1.0, 1.0, 0.4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_focus_mode(Control.FOCUS_NONE)
