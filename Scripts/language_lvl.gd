extends TextureButton

@onready var sprite = $AnimatedSprite2D

var languages = ["english", "german", "russian"]
var current_language = 0

func _ready():
	var saved_code: String = Globals.selected_language
	for i in languages.size():
		if Globals.LANGUAGE_CODES.get(languages[i], "") == saved_code:
			current_language = i
			break

	pressed.connect(_on_pressed)

	sprite.play(languages[current_language])
	_push_to_globals()

func _on_pressed():
	current_language += 1

	if current_language >= languages.size():
		current_language = 0

	sprite.play(languages[current_language])
	_push_to_globals()

func _push_to_globals() -> void:
	var lang_name: String = languages[current_language]
	Globals.selected_language = Globals.LANGUAGE_CODES.get(lang_name, "en")
