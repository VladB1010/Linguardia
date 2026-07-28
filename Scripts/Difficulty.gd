extends TextureButton

enum Mode { DIFFICULTY, LANGUAGE }
@export var mode: Mode = Mode.DIFFICULTY

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const DIFF_FRAMES := ["Easy", "Medium", "Hard"]
var current_diff: int = 0

const LANG_FRAMES := ["english", "german", "russian"]
var current_language: int = 0

func _ready() -> void:
	match mode:
		Mode.DIFFICULTY:
			current_diff = clampi(WaveManager.difficulty - 1, 0, DIFF_FRAMES.size() - 1)
			sprite.play(DIFF_FRAMES[current_diff])
			_push_diff()

		Mode.LANGUAGE:
			var saved: String = Globals.selected_language
			for i in LANG_FRAMES.size():
				if Globals.LANGUAGE_CODES.get(LANG_FRAMES[i], "") == saved:
					current_language = i
					break
			sprite.play(LANG_FRAMES[current_language])
			_push_language()

	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	match mode:
		Mode.DIFFICULTY:
			current_diff = (current_diff + 1) % DIFF_FRAMES.size()
			sprite.play(DIFF_FRAMES[current_diff])
			_push_diff()

		Mode.LANGUAGE:
			current_language = (current_language + 1) % LANG_FRAMES.size()
			sprite.play(LANG_FRAMES[current_language])
			_push_language()

func _push_diff() -> void:
	WaveManager.difficulty = current_diff + 1
	print("Difficulty:", WaveManager.difficulty)
func _push_language() -> void:
	Globals.selected_language = Globals.LANGUAGE_CODES.get(LANG_FRAMES[current_language], "en")

func refresh_from_wave_manager() -> void:
	if mode != Mode.DIFFICULTY:
		return
	current_diff = clampi(WaveManager.difficulty - 1, 0, DIFF_FRAMES.size() - 1)
	sprite.play(DIFF_FRAMES[current_diff])
