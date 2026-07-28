class_name EnemyAI

enum Difficulty { EASY = 1, MEDIUM = 2, HARD = 3 }

const ROLE_SCORE: Dictionary = {
	"Anna":    1.0,
	"Shingen": 0.8,
	"Tris":    0.6,
	"Magnus":  0.2,
}

const BOSS_MULT: Dictionary = {
	"Zamolxes":         1.5,
	"Strigoi":          1.3,
	"Elite Varcolac":   1.15,
	"Elite Varcolac ":  1.15,
	"Elite Spiridus":   1.1,
	"Elite Spiridus ":  1.1,
	"Elite Spiridus  ": 1.1,
}

const PASSIVE_ENEMIES: Array[String] = ["Iele"]

static func decide(enemy: BattleActor, all_players: Array, difficulty: int) -> Array:
	var name_clean: String = enemy.name.strip_edges()

	if name_clean in PASSIVE_ENEMIES:
		return []

	var alive: Array = all_players.filter(func(p: BattleActor) -> bool: return p.has_hp())
	if alive.is_empty():
		return []

	var target: BattleActor
	var mult: float = _attack_multiplier(enemy, difficulty)
	match difficulty:
		Difficulty.EASY:
			target = _random(alive)
		Difficulty.MEDIUM:
			target = _medium(alive)
		Difficulty.HARD:
			target = _hard_utility(enemy, alive, mult)
		_:
			target = _random(alive)

	return [enemy, target, 0, mult]

static func _random(alive: Array) -> BattleActor:
	return alive.pick_random()

static func _medium(alive: Array) -> BattleActor:
	var wounded: Array = alive.filter(func(p: BattleActor) -> bool: return p.hp < p.hp_max)
	if wounded.is_empty():
		return _random(alive)
	wounded.sort_custom(func(a: BattleActor, b: BattleActor) -> bool: return a.hp < b.hp)
	return wounded[0]

static func _hard_utility(enemy: BattleActor, alive: Array, mult: float) -> BattleActor:
	var w_hp:   float = 0.20
	var w_role: float = 0.30
	var w_str:  float = 0.20
	var w_sp:   float = 0.20
	var w_def:  float = 0.30

	var self_hp_ratio: float = 1.0
	if enemy.hp_max > 0:
		self_hp_ratio = float(enemy.hp) / float(enemy.hp_max)

	if self_hp_ratio < 0.4:
		w_hp   = 0.45
		w_role = 0.20
		w_str  = 0.15
		w_sp   = 0.10
		w_def  = 0.10

	var max_str: float = 1.0
	for p in alive:
		if p.strength > max_str:
			max_str = float(p.strength)

	var potential_dmg: int = roundi(enemy.strength * mult)

	var best:       BattleActor = alive[0]
	var best_score: float       = -9999.0

	for p in alive:
		var u_hp: float = 1.0 - (float(p.hp) / float(p.hp_max)) if p.hp_max > 0 else 0.0

		var u_role: float = ROLE_SCORE.get(p.name.strip_edges(), 0.3)

		var u_str: float = float(p.strength) / max_str

		var u_sp: float = clampf(float(p.mp) / 5.0, 0.0, 1.0)

		var defense_penalty: float = clampf(float(p.defend) / 12.0, 0.0, 1.0)

		var score: float = (
			w_hp   * u_hp +
			w_role * u_role +
			w_str  * u_str +
			w_sp   * u_sp -
			w_def  * defense_penalty
		)

		var real_dmg: int = clampi(potential_dmg - p.defend, 0, p.hp)
		if real_dmg >= p.hp and p.hp > 0:
			score += 3.0

		score += randf_range(0.0, 0.02)

		if score > best_score:
			best_score = score
			best       = p

	return best

static func _attack_multiplier(enemy: BattleActor, difficulty: int) -> float:
	if difficulty < Difficulty.HARD:
		return 1.0
	return BOSS_MULT.get(enemy.name, 1.0)
