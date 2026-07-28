extends Node

const  GAME_SIZE: Vector2 = Vector2(1280 , 720)

var selected_language: String = "en"

var language_level: String = "beginner"

var text_input_active: bool = false

var is_duel: bool = false

var duel_my_hero:       String = "Magnus"
var duel_opponent_hero: String = "Magnus"
var duel_my_role:       String = "p1"

const LANGUAGE_CODES: Dictionary = {
	"english": "en",
	"german":  "de",
	"russian": "ru",
}

func _ready() -> void:
	randomize()
