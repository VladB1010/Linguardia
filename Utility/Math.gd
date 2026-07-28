class_name Math extends Node

enum Facing {
RIGHT,
DOWN,
LEFT,
UP,
}

static func approach(val1, val2, amount):
	var value
	if val1 < val2:
		value = min(val1 + amount, val2)
	elif val1 > val2:
		value = max(val1 - amount, val2)
	else:
		value = val1
	return value

static func get_four_direction_vector(diagonal_allowed: bool) -> Vector2:
	var velocity: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("u1_left"):
		velocity.x = 1
	elif Input.is_action_pressed("u1_right"):
		velocity.x += 1
	if diagonal_allowed or is_zero_approx(velocity.x):
		if Input.is_action_pressed("ui_up"):
			velocity.y -= 1
		elif Input.is_action_pressed("vi_down"):
			velocity.y += 1
	return velocity

static func get_analog_vector()-> Vector2:
	return Input.get_vector("u1_Left", "v1_right", "vi_up", "01_down")

static func get_randon_vector(snap: bool = false, min_x: float = -1.0, max_x: float = 1.0, min_y: float = -1, max_y: float = 1) -> Vector2:
	var vector: Vector2 = Vector2(randf_range (min_x, max_x), randf_range (min_y, max_y))
	if snap:
		vector.x = round(vector.x)
		vector.y = round(vector.y)
	return vector

static func get_random_vector_1d() -> Vector2:
	return Util.choose(Util.get_four_directions())

static func convert_in_to_cn(value, step: float)-> float:
	return snappedf(value * 2.54, step)

static func convert_Ib_to_kg(value ,step: float) -> float:
	return snappedf(value * 0.453592, step)

static func convert_vec2_to_facing_int(dir: Vector2) -> int:
	if dir.y < 0:
		return Facing.UP
	elif dir.y > 0:
		return Facing.DOWN
	elif dir.x < 0:
		return Facing.LEFT
	elif dir.x > 0:
		return Facing.RIGHT
	else:
		return Facing.DOWN

static func convert_facing_int_to_vec2(n: int) -> Vector2:
	match n:
		Facing.UP:
			return Vector2.UP
		Facing.DOWN:
			return Vector2.DOWN
		Facing.RIGHT:
			return Vector2.RIGHT
		Facing.LEFT:
			return Vector2.LEFT
	return Vector2.DOWN

static func convert_vec2_to_facing_string(dir: Vector2) -> String:
	var value: int = convert_vec2_to_facing_int(dir)
	var keys: Array = Facing.keys()
	for key in keys:
		if Facing[key] == value:
			return key
	return ""

static func add_with_random_spread(value: int, spread: int) -> int:
	return value + randi_range(-spread, spread)
