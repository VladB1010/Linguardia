extends Node

const SERVER_URL: String = "ws://localhost:8765"

signal connected()
signal disconnected()
signal waiting_for_opponent()
signal matched(room_id: String)
signal party_action_received(data: Dictionary)
signal opponent_action_received(data: Dictionary)
signal opponent_disconnected()
signal network_error(msg: String)

var _ws:           WebSocketPeer = WebSocketPeer.new()
var _is_connected: bool          = false
var room_id:       String        = ""
var _pending_actions: Array      = []

func _ready() -> void:
	set_process(false)

func connect_and_queue() -> void:
	var err := _ws.connect_to_url(SERVER_URL)
	if err != OK:
		network_error.emit("Nu pot conecta la server (%s)" % SERVER_URL)
		return
	set_process(true)

func disconnect_clean() -> void:
	if _ws.get_ready_state() in [WebSocketPeer.STATE_OPEN, WebSocketPeer.STATE_CONNECTING]:
		_ws.close()
	_is_connected = false
	room_id       = ""
	set_process(false)

func _process(_delta: float) -> void:
	_ws.poll()

	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				connected.emit()
				_send({
					"type":     "join_queue",
					"language": Globals.selected_language,
					"level":    Globals.language_level,
				})

			while _ws.get_available_packet_count() > 0:
				var raw  := _ws.get_packet()
				var text := raw.get_string_from_utf8()
				var data: Variant = JSON.parse_string(text)
				if data is Dictionary:
					_dispatch(data)

		WebSocketPeer.STATE_CLOSED:
			if _is_connected:
				_is_connected = false
				disconnected.emit()
				set_process(false)

		WebSocketPeer.STATE_CONNECTING:
			pass

		WebSocketPeer.STATE_CLOSING:
			pass

func _dispatch(data: Dictionary) -> void:
	match data.get("type", ""):
		"waiting":
			waiting_for_opponent.emit()

		"matched":
			room_id = data.get("room_id", "")
			matched.emit(room_id)

		"party_action":
			if party_action_received.get_connections().is_empty():
				_pending_actions.append(data)
			else:
				party_action_received.emit(data)

		"opponent_disconnected":
			opponent_disconnected.emit()

		"action", "defend_result", "special", "special_result", "attack":
			opponent_action_received.emit(data)

func drain_pending_actions() -> Array:
	var actions := _pending_actions.duplicate()
	_pending_actions.clear()
	return actions

func send_party_action(actor_index: int, action: String, target_type: String,
		target_index: int, multiplier: float = 1.0, defend_points: int = 0) -> void:
	_send({
		"type":          "party_action",
		"actor_index":   actor_index,
		"action":        action,
		"target_type":   target_type,
		"target_index":  target_index,
		"multiplier":    multiplier,
		"defend_points": defend_points,
	})

func send_action(action_type: String, details: Dictionary) -> void:
	var payload := {
		"type": action_type,
	}
	for key in details.keys():
		payload[key] = details[key]
	_send(payload)

func prepare_duel_data() -> void:
	Globals.is_duel = true

	for p: BattleActor in Data.party:
		p.hp     = p.hp_max
		p.defend = 0
		p.mp     = 0.0

	var mirror: Dictionary = {}
	for hero_name in Data.players.keys():
		var src: BattleActor   = Data.players[hero_name]
		var clone: BattleActor = BattleActor.new(src.hp_max, src.strength)
		clone.name     = hero_name.strip_edges()
		clone.friendly = false
		mirror[hero_name] = clone

	Data.enemies = mirror

func _send(data: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))
