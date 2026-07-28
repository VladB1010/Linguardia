extends TextureButton

@onready var _popup:      NinePatchRect =  $Label/NinePatchRect
@onready var _easy_btn:   TextureButton  = $Label/NinePatchRect/TextureButton
@onready var _medium_btn: TextureButton  = $Label/NinePatchRect/TextureButton2
@onready var _hard_btn:   TextureButton  = $Label/NinePatchRect/TextureButton3

const _DIM := Color(0.5, 0.5, 0.5, 1.0)

func _ready() -> void:
	_popup.visible = false

	pressed.connect(_on_header_pressed)
	_easy_btn.pressed.connect(_on_choice.bind(WaveManager.Difficulty.EASY))
	_medium_btn.pressed.connect(_on_choice.bind(WaveManager.Difficulty.MEDIUM))
	_hard_btn.pressed.connect(_on_choice.bind(WaveManager.Difficulty.HARD))
	_highlight_current()

func _on_header_pressed() -> void:
	_popup.visible = !_popup.visible

func _on_choice(difficulty: int) -> void:
	WaveManager.difficulty = difficulty
	_popup.visible = false
	_highlight_current()
	print("Ai Difficulty set to: ", difficulty)

func _highlight_current() -> void:
	var d: int = WaveManager.difficulty
	_easy_btn.modulate   = Color.WHITE if d == WaveManager.Difficulty.EASY   else _DIM
	_medium_btn.modulate = Color.WHITE if d == WaveManager.Difficulty.MEDIUM else _DIM
	_hard_btn.modulate   = Color.WHITE if d == WaveManager.Difficulty.HARD   else _DIM

func refresh_from_wave_manager() -> void:
	_highlight_current()
