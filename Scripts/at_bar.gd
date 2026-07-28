class_name ATBar extends ProgressBar

@onready var _anim: AnimationPlayer = $AnimationPlayer

signal filled()
const SPEED_BASE: float  = 0.15

var speed_mult: float = 1.0

func _ready() -> void:
	_anim.play("RESET")
	value = randf_range(min_value, max_value * 0.75)

func stop() -> void:
	set_process(false)

func reset(restart: bool = true) -> void:
	modulate = Color.WHITE
	value = min_value
	if restart:
		set_process(true)

func _process(_delta: float) -> void:
	value += SPEED_BASE * speed_mult

	if  is_equal_approx(value, max_value):
		modulate = Color("ff0009")
		stop()
		filled.emit()
