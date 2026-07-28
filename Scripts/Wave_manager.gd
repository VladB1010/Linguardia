extends Node

enum Difficulty {
	EASY   = 1,
	MEDIUM = 2,
	HARD   = 3,
}

var difficulty: int = Difficulty.EASY

var current_wave: int = 0
const MAX_WAVES:  int = 5

func _ready() -> void:
	setup_current_wave()

func setup_current_wave() -> void:
	Data.enemies = _build_wave(current_wave)
	for e: BattleActor in Data.enemies.values():
		e.friendly = false
	Util.set_keys_to_names(Data.enemies)

func advance_wave() -> bool:
	current_wave += 1
	if current_wave >= MAX_WAVES:
		return false
	setup_current_wave()
	return true

func has_more_waves() -> bool:
	return current_wave < MAX_WAVES - 1

func reset(new_difficulty: int = Difficulty.EASY) -> void:
	current_wave = 0
	difficulty   = new_difficulty
	setup_current_wave()

func get_wave_label() -> String:
	match current_wave:
		0: return "Val 1 — Forest Entrance"
		1: return "Val 2 — Whispering Trail"
		2: return "Val 3 — Shadow Thicket"
		3: return "Val 4 — Ancient Grove"
		4: return "Val 5 — Heart of the Forest "
		_: return "Val " + str(current_wave + 1)

func _build_wave(wave: int) -> Dictionary:
	match wave:

		0:
			return {
				"Iele":    BattleActor.new( 65, 3),
				"Spiridus":          BattleActor.new( 50,  5),
				"Elite Spiridus":  BattleActor.new( 65, 7),
				"Elite Spiridus 2":  BattleActor.new( 65, 7),
}
		1:
			return {
				"Iele":    BattleActor.new( 65, 3),
				"Spiridus":          BattleActor.new( 50,  5),
				"Elite Spiridus":  BattleActor.new( 65, 7),
				"Elite Spiridus 2":  BattleActor.new( 65, 7),

			}
		2:
			return {
				"Varcolac":          BattleActor.new(100, 8),
				"Elite Varcolac":    BattleActor.new(130, 10),
				"Varcolac 2":        BattleActor.new(100, 8),
				"Elite Varcolac 2":  BattleActor.new(130, 10),
			}

		3:
			return {
				"Strigoi": BattleActor.new(250, 12),
			}

		4:
			return {
				"Zamolxes": BattleActor.new(480, 16),
			}

		_:
			push_error("WaveManager: val necunoscut " + str(wave))
			return {}
