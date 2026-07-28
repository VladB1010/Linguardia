class_name BossMinigame extends Control
signal completed(success: bool)

const ANSWER_TIME:    float = 6.0
const FALL_DURATION:  float = 0.65
const FALL_TARGET_Y:  float = 210.0

@onready var _word_label: Label  = $VBoxContainer/NinePatchRect/Label
@onready var _timer:      Timer  = $Timer
@onready var _panels: Array = [
	$NinePatchRect2,
	$NinePatchRect3,
	$NinePatchRect4,
]

var _questions:  Array  = []
var _start_y:    Array  = []
var _correct:    String = ""
var _finished:   bool   = false

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_timer.one_shot  = true
	_timer.wait_time = ANSWER_TIME
	_timer.timeout.connect(_on_timer_timeout)

	for panel in _panels:
		_start_y.append(panel.position.y)
		var btn: Button = panel.get_node("Button")
		btn.focus_mode = Control.FOCUS_NONE
		if not btn.pressed.is_connected(_on_btn_pressed.bind(_panels.find(panel))):
			btn.pressed.connect(_on_btn_pressed.bind(_panels.find(panel)))

	_load_questions()

func _load_questions() -> void:
	var path: String = "res://data/list_attack_" + Globals.language_level + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("BossMinigame: nu pot citi " + path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed and parsed.has("attack")):
		return
	if parsed["attack"] is Array:
		_questions = parsed["attack"]
	else:
		_questions = Util.get_localized_list(parsed["attack"], Globals.selected_language)

func start() -> void:
	if _questions.is_empty():
		completed.emit(true)
		return

	_finished = false

	var pool: Array = _questions.duplicate()
	pool.shuffle()
	var q: Dictionary = pool[0]
	_correct          = q["correct"]
	_word_label.text  = q["word"]

	var all_opts: Array = q["options"].duplicate()
	all_opts.shuffle()
	if not all_opts.has(_correct):
		all_opts[0] = _correct
	while all_opts.size() > 3:
		var idx_to_remove: int = randi() % all_opts.size()
		if all_opts[idx_to_remove] != _correct:
			all_opts.remove_at(idx_to_remove)
	all_opts.shuffle()

	var labels: Array = ["A.  ", "B.  ", "C.  "]
	for i in _panels.size():
		var btn: Button = _panels[i].get_node("Button")
		btn.text     = labels[i] + all_opts[i]
		btn.disabled = false
		_panels[i].position.y = _start_y[i]
		_panels[i].modulate   = Color.WHITE

	show()

	for i in _panels.size():
		var tw: Tween = create_tween()
		tw.tween_interval(i * 0.14)
		tw.tween_property(_panels[i], "position:y", FALL_TARGET_Y, FALL_DURATION) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var total: float = FALL_DURATION + (_panels.size() - 1) * 0.14 + 0.05
	await get_tree().create_timer(total, false).timeout
	_timer.start()

func _on_btn_pressed(idx: int) -> void:
	if _finished:
		return
	var btn: Button   = _panels[idx].get_node("Button")
	var raw: String   = btn.text
	var dot: int      = raw.find(".  ")
	var answer: String = raw.substr(dot + 3).strip_edges() if dot != -1 else raw.strip_edges()
	_finish(answer == _correct)

func _on_timer_timeout() -> void:
	if not _finished:
		_finish(false)

func _finish(success: bool) -> void:
	if _finished:
		return
	_finished = true
	_timer.stop()

	for panel in _panels:
		panel.get_node("Button").disabled = true

	var col: Color = Color(0.2, 0.9, 0.2) if success else Color(0.9, 0.2, 0.2)
	for panel in _panels:
		var tw: Tween = create_tween()
		tw.tween_property(panel, "modulate", col,         0.12)
		tw.tween_property(panel, "modulate", Color.WHITE, 0.12)

	await get_tree().create_timer(0.3, false).timeout

	for i in _panels.size():
		var tw: Tween = create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(_panels[i], "position:y", _start_y[i], 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.48, false).timeout
	hide()
	completed.emit(success)
