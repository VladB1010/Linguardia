class_name ShingenSpecial extends Node2D

signal completed(damage_multiplier: float)

const ENEMY_RARITY: Dictionary = {
	"Spiridus":       1,
	"Elite Spiridus": 2,
	"Varcolac":       2,
	"Elite Varcolac": 2,
	"Iele":           2,
	"Strigoi":        3,
	"Zamolxes":       3,
}

const THROW_FRAMES:   int   = 10
const THROW_FPS:      float = 9.0
const THROW_DURATION: float = THROW_FRAMES / THROW_FPS

const INTRO_PAUSE:    float = 0.55
const RESULT_PAUSE:   float = 0.45
const COUNT_STEP:     float = 0.08
const FINAL_PAUSE:    float = 0.65

@onready var _die_left:        AnimatedSprite2D = $AnimatedSprite2D2
@onready var _die_right:       AnimatedSprite2D = $AnimatedSprite2D
@onready var _sum_label:       Label            = $VBoxContainer2/NinePatchRect/Label
@onready var _threshold_label: Label            = $VBoxContainer/NinePatchRect/Label

var _shingen:   BattleActor = null
var _target:    BattleActor = null
var _result1:   int         = 0
var _result2:   int         = 0
var _threshold: int         = 0
var _running:   bool        = false

func _ready() -> void:
	visible = false

func start(shingen: BattleActor, target: BattleActor) -> void:
	if _running:
		return
	_running  = true
	_shingen  = shingen
	_target   = target

	_threshold = _compute_threshold(shingen, target)

	_sum_label.text        = "0"
	_threshold_label.text  = str(_threshold)
	_sum_label.modulate    = Color.WHITE
	_threshold_label.modulate = Color.WHITE

	visible = true

	_die_left.play(str(randi_range(1, 6)))
	_die_right.play(str(randi_range(1, 6)))

	await get_tree().create_timer(INTRO_PAUSE, false).timeout

	_result1 = randi_range(1, 6)
	_result2 = randi_range(1, 6)

	_die_left.play("throw")
	_die_right.play("throw")

	await get_tree().create_timer(THROW_DURATION, false).timeout

	_die_left.stop()
	_die_right.stop()
	_die_left.play(str(_result1))
	_die_right.play(str(_result2))

	_shake(_die_left)
	_shake(_die_right)

	await get_tree().create_timer(RESULT_PAUSE, false).timeout

	await _animate_sum(_result1 + _result2)

	await get_tree().create_timer(FINAL_PAUSE, false).timeout

	_finish()

func _animate_sum(total: int) -> void:
	for i in range(1, total + 1):
		_sum_label.text = str(i)

		var tw: Tween = create_tween()
		tw.tween_property(_sum_label, "scale",    Vector2(1.3, 1.3), 0.04)
		tw.parallel().tween_property(_sum_label, "modulate", Color(1.6, 1.4, 0.2), 0.04)
		tw.tween_property(_sum_label, "scale",    Vector2(1.0, 1.0), 0.04)
		tw.parallel().tween_property(_sum_label, "modulate", Color.WHITE, 0.04)

		await get_tree().create_timer(COUNT_STEP, false).timeout

func _shake(sprite: AnimatedSprite2D) -> void:
	var origin: Vector2 = sprite.position
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "position", origin + Vector2(8, -12), 0.06).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "position", origin + Vector2(-6, 8),  0.06).set_trans(Tween.TRANS_CIRC)
	tw.tween_property(sprite, "position", origin,                   0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _compute_threshold(shingen: BattleActor, target: BattleActor) -> int:
	var name_key: String = target.name.strip_edges().rstrip(" 0123456789")
	var rarity:   int    = ENEMY_RARITY.get(name_key, 1)

	var base: float = rarity * 1.5

	var hp_factor: float = 0.0
	if target.hp_max > 0:
		hp_factor = (float(target.hp) / float(target.hp_max)) * 2.5

	var shingen_pen: float = 0.0
	if shingen.hp_max > 0:
		shingen_pen = (1.0 - float(shingen.hp) / float(shingen.hp_max)) * 1.5

	return clampi(roundi(base + hp_factor - shingen_pen), 2, 10)

func _finish() -> void:
	var sum:     int   = _result1 + _result2
	var success: bool  = (sum >= _threshold)
	var mult:    float = 4.0 if success else 0.0

	var hit_col:  Color = Color(0.15, 1.0,  0.25) if success else Color(1.0, 0.15, 0.15)
	var miss_col: Color = Color(1.0,  0.15, 0.15)

	for lbl: Label in [_sum_label, _threshold_label]:
		var tw: Tween = create_tween()
		tw.tween_property(lbl, "modulate", hit_col,    0.14)
		tw.tween_property(lbl, "modulate", Color.WHITE, 0.14)
		tw.tween_property(lbl, "modulate", hit_col,    0.14)
		tw.tween_property(lbl, "modulate", Color.WHITE, 0.14)

	await get_tree().create_timer(0.65, false).timeout

	visible  = false
	_running = false
	completed.emit(mult)
