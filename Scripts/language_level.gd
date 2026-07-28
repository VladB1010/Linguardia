extends TextureButton

@onready var label: Label = $Label

var levels: Array = ["beginner", "intermediate", "advanced"]
var level_labels: Array = ["Beginner", "Intermediate", "Advanced"]
var current_level: int = 0

func _ready() -> void:
	var idx: int = levels.find(Globals.language_level)
	current_level = idx if idx != -1 else 0

	pressed.connect(_on_pressed)

	label.text = level_labels[current_level]
	_push_to_globals()

func _on_pressed() -> void:
	current_level += 1
	if current_level >= levels.size():
		current_level = 0

	label.text = level_labels[current_level]
	_push_to_globals()

func _push_to_globals() -> void:
	Globals.language_level = levels[current_level]
