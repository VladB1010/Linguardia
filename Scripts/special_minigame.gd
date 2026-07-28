class_name SpecialMinigame extends Control

signal completed(success: bool)

const TIMER_DURATION: float = 20.0

var _sentences: Array = []
var _target_sentence: String = ""
var _typed: String = ""
var _has_error: bool = false
var _timed_out: bool = false
var _start_time: float = 0.0

var last_chars_typed: int  = 0
var last_time_taken: float = 0.0

@onready var _phrase_display: RichTextLabel = $TypeContainer/PhraseDisplay
@onready var _timer_bar: AnimatedSprite2D   = $AnimatedSprite2D
@onready var _timer: Timer                  = $Timer

func _ready() -> void:
	_timer.wait_time = TIMER_DURATION
	_timer.one_shot  = true
	_timer.timeout.connect(_on_timer_timeout)
	_load_sentences()
	hide()

func _load_sentences() -> void:
	if CustomWordList.custom_special.size() > 0:
		_sentences = CustomWordList.custom_special
		print("[SpecialMinigame] Loaded custom sentences: ", _sentences.size())
		return

	var path: String = "res://data/list_special_" + Globals.language_level + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SpecialMinigame: cannot read " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed and parsed.has("special"):
		_sentences = Util.get_localized_list(parsed["special"], Globals.selected_language)

func start() -> void:
	if _sentences.is_empty():
		completed.emit(false)
		return

	_timed_out  = false
	_typed      = ""
	_has_error  = false
	last_chars_typed = 0
	last_time_taken  = 0.0

	var entry: Dictionary = _sentences[randi() % _sentences.size()]
	_target_sentence = entry["sentence"]

	_refresh_display()

	_timer.start()
	_start_time = Time.get_unix_time_from_system()
	if _timer_bar:
		_timer_bar.frame = 0
		_timer_bar.play("default")

	show()
	set_process_unhandled_key_input(true)
	Globals.text_input_active = true

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or _timed_out:
		return
	if not event is InputEventKey or not event.pressed:
		return

	var key := event as InputEventKey

	if key.keycode == KEY_BACKSPACE:
		if _typed.length() > 0:
			_typed = _typed.left(_typed.length() - 1)
			_has_error = (_typed != _target_sentence.left(_typed.length()))
			_refresh_display()
		get_viewport().set_input_as_handled()
		return

	if _has_error:
		get_viewport().set_input_as_handled()
		return

	if key.unicode == 0:
		return
	var ch: String = char(key.unicode)

	_typed += ch

	if _typed != _target_sentence.left(_typed.length()):
		_has_error = true

	_refresh_display()
	get_viewport().set_input_as_handled()

	if not _has_error and _typed == _target_sentence:
		_finish(true)

func _refresh_display() -> void:
	var bb: String = ""
	var total: int = _target_sentence.length()
	var typed_len: int = _typed.length()

	for i in total:
		var ch: String = _target_sentence[i]
		var safe_ch: String = ch.replace("[", "[lb]")

		if i < typed_len:
			if _has_error and i == typed_len - 1:
				bb += "[bgcolor=#5c0000][color=#ff4444]" + safe_ch + "[/color][/bgcolor]"
			else:
				bb += "[color=#ffffff]" + safe_ch + "[/color]"
		elif i == typed_len and not _has_error:
			bb += "[color=#aaaaaa][u]" + safe_ch + "[/u][/color]"
		else:
			bb += "[color=#555555]" + safe_ch + "[/color]"
	_phrase_display.parse_bbcode(bb)

func _on_timer_timeout() -> void:
	_timed_out = true
	_finish(false)

func _show_result(success: bool) -> void:
	var panel := $TypeContainer

	var col := Color(0.2, 0.9, 0.2) if success else Color(0.9, 0.2, 0.2)

	var tw := create_tween()
	tw.tween_property(panel, "modulate", col, 0.12)
	tw.tween_property(panel, "modulate", Color.WHITE, 0.12)

	await tw.finished
	await get_tree().create_timer(0.25).timeout

func _finish(success: bool) -> void:
	set_process_unhandled_key_input(false)
	Globals.text_input_active = false

	_timer.stop()

	if success:
		last_chars_typed = _typed.length()
		last_time_taken  = Time.get_unix_time_from_system() - _start_time

	if _timer_bar:
		_timer_bar.stop()

	await _show_result(success)

	hide()
	get_viewport().gui_release_focus()
	completed.emit(success)
