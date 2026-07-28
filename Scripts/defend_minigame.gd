class_name DefendMinigame extends Control

signal completed(defend_points: int)

const TIMER_DURATION: float    = 10.0

const POINTS_PERFECT: int    = 6
const POINTS_ACCEPTABLE: int = 3
const POINTS_NONE: int       = 0

var _words: Array              = []
var _current_entry: Dictionary = {}
var _timed_out: bool           = false

@onready var _word_label:   Label            = $NinePatchRect/VBoxContainer/WordLabel
@onready var _prompt_label: Label            = $NinePatchRect/VBoxContainer/PromptLabel
@onready var _input:        LineEdit         = $NinePatchRect/VBoxContainer/LineEdit
@onready var _timer_label:  Label            = $NinePatchRect/VBoxContainer/TimerLabel
@onready var _timer_bar:    AnimatedSprite2D = $AnimatedSprite2D
@onready var _timer:        Timer            = $Timer

func _ready() -> void:
	_timer.wait_time = TIMER_DURATION
	_timer.one_shot  = true
	_timer.timeout.connect(_on_timer_timeout)
	_input.text_submitted.connect(_on_text_submitted)
	_load_words()
	hide()

func _load_words() -> void:
	if CustomWordList.custom_defend.size() > 0:
		_words = CustomWordList.custom_defend
		print("[DefendMinigame] Loaded custom defend words: ", _words.size())
		return

	var path: String = "res://data/list_defend_" + Globals.language_level + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("DefendMinigame: cannot read " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed and parsed.has("defend"):
		_words = Util.get_localized_list(parsed["defend"], Globals.selected_language)

func start() -> void:
	if _words.is_empty():
		completed.emit(POINTS_NONE)
		return

	_timed_out = false
	_input.text = ""

	_current_entry = _words[randi() % _words.size()]
	_word_label.text   = _current_entry["word"].to_upper()
	_prompt_label.text = "Tradu:"
	_timer_label.text  = str(int(TIMER_DURATION))

	_timer.start()
	if _timer_bar:
		_timer_bar.frame = 0
		_timer_bar.play("default")

	show()
	set_process(true)
	Globals.text_input_active = true
	await get_tree().process_frame
	_input.grab_focus()

func _process(_delta: float) -> void:
	if _timer.is_stopped():
		_timer_label.text = "0"
	else:
		_timer_label.text = str(ceili(_timer.time_left))

func _on_text_submitted(text: String) -> void:
	if _timed_out:
		return
	_finish(_score_answer(text.strip_edges().to_lower()))

func _score_answer(answer: String) -> int:
	if answer == _current_entry["correct"].to_lower():
		return POINTS_PERFECT
	var acceptable: Array = _current_entry["acceptable"]
	for acc in acceptable:
		if answer == (acc as String).to_lower():
			return POINTS_ACCEPTABLE
	return POINTS_NONE

func _on_timer_timeout() -> void:
	_timed_out = true
	_finish(POINTS_NONE)

func _show_result(success: bool) -> void:
	var panel := $NinePatchRect

	var col := Color(0.2, 0.9, 0.2) if success else Color(0.9, 0.2, 0.2)

	var tw := create_tween()
	tw.tween_property(panel, "modulate", col, 0.12)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.12)

	await tw.finished
	await get_tree().create_timer(0.25).timeout

func _finish(points: int) -> void:
	set_process(false)
	Globals.text_input_active = false
	_timer.stop()

	if _timer_bar:
		_timer_bar.stop()

	await _show_result(points > 0)

	hide()
	get_viewport().gui_release_focus()
	completed.emit(points)
