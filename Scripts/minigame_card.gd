class_name MinigameCard extends Control
signal completed(success: bool)

const ANSWER_TIME:   float = 10.0
const FALL_DURATION: float = 0.65
const FALL_START_Y:  float = -400.0

const CARD_TO_FACE: Dictionary = {
	"K":     "king",
	"Q":     "queen",
	"J":     "jalet",
	"Joker": "joker",
}
const ALL_FACES: Array[String] = ["king", "queen", "jalet", "joker"]

@onready var _word_label: Label = $VBoxContainer/NinePatchRect/Label
@onready var _timer:      Timer = $Timer
@onready var _buttons: Array = [
	$Button2,
	$Button3,
	$Button4,
]

var _sprites:      Array  = []
var _target_y:     Array  = []
var _shown_faces:  Array  = []
var _riddles:      Array  = []
var _correct_face: String = ""
var _finished:     bool   = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_timer.one_shot  = true
	_timer.wait_time = ANSWER_TIME
	_timer.timeout.connect(_on_timer_timeout)

	for i in _buttons.size():
		var btn: Button = _buttons[i]
		_target_y.append(btn.position.y)
		_sprites.append(btn.get_node("AnimatedSprite2D"))
		btn.focus_mode = Control.FOCUS_NONE
		if not btn.pressed.is_connected(_on_btn_pressed.bind(i)):
			btn.pressed.connect(_on_btn_pressed.bind(i))

	_load_riddles()

func _load_riddles() -> void:
	var file := FileAccess.open("res://data/riddle.json", FileAccess.READ)
	if not file:
		push_error("MinigameCard: nu pot citi res://data/riddle.json")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed and parsed.has("riddle")):
		push_error("MinigameCard: riddle.json invalid sau lipsă cheia 'riddle'")
		return

	var lang: String = Globals.selected_language
	if parsed["riddle"].has(lang):
		_riddles = parsed["riddle"][lang]
	else:
		_riddles = parsed["riddle"].get("en", [])

func start() -> void:
	if _riddles.is_empty():
		completed.emit(true)
		return

	_finished = false

	var pool: Array = _riddles.duplicate()
	pool.shuffle()
	var r: Dictionary = pool[0]
	_correct_face     = CARD_TO_FACE.get(r["card"], "king")
	_word_label.text  = r["sentence"]

	var wrong_faces: Array = ALL_FACES.duplicate()
	wrong_faces.erase(_correct_face)
	wrong_faces.shuffle()
	_shown_faces = [_correct_face, wrong_faces[0], wrong_faces[1]]
	_shown_faces.shuffle()

	for i in _buttons.size():
		var btn: Button = _buttons[i]
		btn.disabled          = true
		btn.position.y        = FALL_START_Y
		btn.modulate          = Color.WHITE
		_sprites[i].animation = "card"

	show()

	for i in _buttons.size():
		var tw: Tween = create_tween()
		tw.tween_interval(i * 0.14)
		tw.tween_property(_buttons[i], "position:y", _target_y[i], FALL_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fall_total: float = FALL_DURATION + (_buttons.size() - 1) * 0.14 + 0.05
	await get_tree().create_timer(fall_total, false).timeout

	for i in _sprites.size():
		_sprites[i].animation = _shown_faces[i]
	for btn in _buttons:
		btn.disabled = false

	_timer.start()

func _on_btn_pressed(idx: int) -> void:
	if _finished:
		return
	_finish(_shown_faces[idx] == _correct_face)

func _on_timer_timeout() -> void:
	if not _finished:
		_finish(false)

func _finish(success: bool) -> void:
	if _finished:
		return
	_finished = true
	_timer.stop()

	for btn in _buttons:
		btn.disabled = true

	var col: Color = Color(0.2, 0.9, 0.2) if success else Color(0.9, 0.2, 0.2)
	for btn in _buttons:
		var tw: Tween = create_tween()
		tw.tween_property(btn, "modulate", col,         0.12)
		tw.tween_property(btn, "modulate", Color.WHITE, 0.12)

	await get_tree().create_timer(0.3, false).timeout

	for i in _buttons.size():
		var tw: Tween = create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(_buttons[i], "position:y", FALL_START_Y, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.48, false).timeout
	hide()
	completed.emit(success)
