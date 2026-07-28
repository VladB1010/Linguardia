extends Node

var enemies: Dictionary = {}

var players: Dictionary = {
	"Magnus":  BattleActor.new(100, 30),
	"Tris":    BattleActor.new( 90, 30),
	"Shingen": BattleActor.new( 70, 30),
	"Anna":    BattleActor.new( 80, 30),
}
var party: Array = players.values()

func _init() -> void:
	players["Magnus"].mp_max  = 6
	players["Magnus"].sp_gain = 2.0

	players["Shingen"].mp_max  = 4
	players["Shingen"].sp_gain = 1.0

	players["Anna"].mp_max  = 3
	players["Anna"].sp_gain = 1.0

	players["Tris"].mp_max  = 4
	players["Tris"].sp_gain = 1.0

	for p: BattleActor in party:
		p.friendly = true
	Util.set_keys_to_names(players)
