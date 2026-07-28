class_name Minigame extends Control

signal completed(multiplier: float)

const TIMER_DURATION: float    = 10.0
const TIMER_FRAMES: int        = 30
const TIMER_FPS: float         = TIMER_FRAMES / TIMER_DURATION

var _questions: Array = []
var _current_questions: Array = []
var _current_index: int = 0
var _correct_count: int = 0
var _timed_out: bool = false

@onready var _word_label: Label        = $VBoxContainer/NinePatchRect/Label
@onready var _btn1: Button             = $VBoxContainer/NinePatchRect2/BoxContainer/Button
@onready var _btn2: Button             = $VBoxContainer/NinePatchRect2/BoxContainer/Button2
@onready var _btn3: Button             = $VBoxContainer/NinePatchRect2/BoxContainer/Button3
@onready var _btn4: Button             = $VBoxContainer/NinePatchRect2/BoxContainer/Button4
@onready var _timer: Timer             = $Timer
@onready var _anim_timer: AnimatedSprite2D = $AnimatedSprite2D

var _buttons: Array = []

func _ready() -> void:
	_buttons = [_btn1, _btn2, _btn3, _btn4]
	for btn in _buttons:
		btn.pressed.connect(_on_button_pressed.bind(btn))

	_timer.wait_time   = TIMER_DURATION
	_timer.one_shot    = true
	_timer.timeout.connect(_on_timer_timeout)

	_anim_timer.speed_scale = 5
	_anim_timer.sprite_frames

	_load_questions()
	hide()

func _load_questions() -> void:
	if CustomWordList.custom_attack.size() > 0:
		_questions = CustomWordList.custom_attack
		print("[Minigame] Loaded custom attack questions: ", _questions.size())
		return

	var path: String = "res://data/list_attack_" + Globals.language_level + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Minigame: nu pot citi " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed and parsed.has("attack"):
		_questions = Util.get_localized_list(parsed["attack"], Globals.selected_language)

func start() -> void:
	if _questions.is_empty():
		completed.emit(1.0)
		return

	_current_index = 0
	_correct_count = 0
	_timed_out     = false

	var pool: Array = _questions.duplicate()
	pool.shuffle()
	_current_questions = [pool[0], pool[1]]

	_timer.start()
	_anim_timer.frame = 0
	_anim_timer.play("default")

	show()
	_show_question(_current_questions[0])

func _show_question(q: Dictionary) -> void:
	_word_label.text = q["word"]

	var options: Array = q["options"].duplicate()
	options.shuffle()

	var labels: Array = ["A", "B", "C", "D"]
	for i in _buttons.size():
		_buttons[i].text = labels[i] + ". " + options[i]
		_buttons[i].set_meta("option_value", options[i])

	await get_tree().process_frame
	_buttons[0].grab_focus()

func _on_button_pressed(btn: Button) -> void:
	if _timed_out:
		return

	var q: Dictionary = _current_questions[_current_index]
	if btn.get_meta("option_value") == q["correct"]:
		_correct_count += 1

	_current_index += 1

	if _current_index < _current_questions.size():
		_show_question(_current_questions[_current_index])
	else:
		_finish()

func _on_timer_timeout() -> void:
	_timed_out = true
	_finish()

func _finish() -> void:
	_timer.stop()
	_anim_timer.stop()

	hide()
	get_viewport().gui_release_focus()

	var multiplier: float
	if _timed_out:
		multiplier = 0.0
	else:
		match _correct_count:
			2: multiplier = 1.0
			1: multiplier = 0.5
			_: multiplier = 0.0

	completed.emit(multiplier)
