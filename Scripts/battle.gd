extends Control

enum States {
	OPTIONS,
	TARGETS,
	MINIGAME,
	SPECIAL_MINIGAME,
	DEFEND_MINIGAME,
	BOSS_MINIGAME,
	CARD_MINIGAME,
	VICTORY,
	GAMEOVER
}

enum Actions {
	ATTACK,
	DEFEND,
	SPECIAL,
	ANNA_HEAL,
	MAGNUS_SPECIAL,
}

enum {
	ACTOR,
	TARGET,
	ACTION
}

var state: States            = States.OPTIONS
var players_atb_queue: Array = []
var event_queue: Array       = []
var event_runing: bool       = false
var action: Actions          = Actions.ATTACK
var player: BattleActor      = null
var _pending_event: Array    = []

var _duel_enemy_actors: Array = []

var _stat_words_correct: int  = 0
var _stat_words_total: int    = 0
var _stat_specials_used: int  = 0
var _stat_typing_chars: int   = 0
var _stat_typing_time: float  = 0.0

const ANNA_INDEX: int = 3

const BOSS_NAMES: Array[String]     = ["Zamolxes", "Strigoi"]
const BOSS_MINI_MIN:  float         = 20.0
const BOSS_MINI_MAX:  float         = 45.0
const BOSS_MINI_DAMAGE: int         = 5
var _boss_mini_timer:  float        = 0.0
var _boss_mini_next:   float        = 0.0
var _boss_mini_active: bool         = false

const CARD_MINI_MIN:  float         = 20.0
const CARD_MINI_MAX:  float         = 45.0
const CARD_MINI_DAMAGE: int         = 3
var _card_mini_timer:  float        = 0.0
var _card_mini_next:   float        = 0.0
var _card_mini_active: bool         = false

const BAT_SPAWN_THRESHOLD: int      = 60
const BAT_HP:              int      = 5
const BAT_STRENGTH:        int      = 2
const BAT_SCENE: PackedScene        = preload("res://scene/enemy_button.tscn")
var _strigoi_last_hp:      int      = -1
var _bat_spawn_counter:    int      = 0

@onready var _gui: Control                      = $GUIMargin
@onready var _options: WindowDef                = $Options
@onready var _options_menu: Menu                = $Options/Options
@onready var _enemies_menu: Menu                = $Enemies
@onready var _players_menu: Menu                = $Players
@onready var _players_infos: Array              = $GUIMargin/Bottom/Players/MarginContainer/PlayerInfos.get_children()
@onready var _cursor: MenuCursor                = $MenuCursor
@onready var _down_cursor: TextureRect          = $DownCursor
@onready var _minigame: Minigame                = $Minigame
@onready var _special_minigame: SpecialMinigame = $SpecialMinigame
@onready var _defend_minigame: DefendMinigame   = $DefendMinigame
@onready var _bliz: ShingenSpecial              = $Bliz
@onready var _heal_cursor: TextureRect          = $HealCursor
@onready var _enemies_labels: Array = _resolve_children("GUIMargin/Bottom/Enemies/MarginContainer/VBoxContainer")
@onready var _enemy_infos: Array    = _resolve_children("GUIMargin/Bottom/Enemies/MarginContainer/PlayerInfos")
@onready var _boss_minigame: BossMinigame       = $Bossminigame
@onready var _card_minigame: MinigameCard       = $MinigameCard

func _resolve_children(path: String) -> Array:
	if has_node(path):
		return get_node(path).get_children()
	return []

func _ready() -> void:
	_options.hide()
	_down_cursor.hide()
	_heal_cursor.hide()
	_bliz.hide()

	if Globals.is_duel:
		DuelNetwork.party_action_received.connect(_on_duel_party_action)
		DuelNetwork.opponent_disconnected.connect(_on_duel_opponent_disconnected)
		for pending: Dictionary in DuelNetwork.drain_pending_actions():
			_on_duel_party_action(pending)

	var data: BattleActor = null
	for player_info in _players_infos:
		data = player_info.data
		player_info.atb_ready.connect(_on_player_atb_ready.bind(player_info))
		data.defeated.connect(_on_battle_actor_defeated.bind(data))

	var enemy_buttons: Array = _enemies_menu.get_buttons()

	if Globals.is_duel:
		for eb0 in enemy_buttons:
			_duel_enemy_actors.append(eb0.data)

	for i in enemy_buttons.size():
		var eb: EnemyButton = enemy_buttons[i]

		if eb.data == null:
			if i < _enemies_labels.size():
				_enemies_labels[i].text = ""
			continue

		data = eb.data
		eb.atb_ready.connect(_on_enemies_atb_ready.bind(data))
		data.defeated.connect(_on_battle_actor_defeated.bind(data))
		if i < _enemies_labels.size():
			_enemies_labels[i].text = data.name + "  HP  " + str(data.hp)
		data.hp_changed.connect(_on_enemy_hp_changed.bind(i, data))
		data.defeated.connect(_on_enemy_defeated_label.bind(i))

		if i < _enemy_infos.size():
			_enemy_infos[i].setup(data)

	_minigame.completed.connect(_on_minigame_completed)
	_special_minigame.completed.connect(_on_special_minigame_completed)
	_bliz.completed.connect(_on_shingen_special_completed)
	_defend_minigame.completed.connect(_on_defend_minigame_completed)
	_boss_minigame.completed.connect(_on_boss_minigame_completed)
	_card_minigame.completed.connect(_on_card_minigame_completed)

	for pinfo in _players_infos:
		pinfo.data.mp_changed.connect(_on_player_sp_changed.bind(pinfo.data))

	_update_special_button()

	_boss_mini_next = randf_range(BOSS_MINI_MIN, BOSS_MINI_MAX)
	_card_mini_next = randf_range(CARD_MINI_MIN, CARD_MINI_MAX)

	for btn in _enemies_menu.get_buttons():
		if btn.data != null and btn.data.name.strip_edges() == "Strigoi":
			_strigoi_last_hp  = btn.data.hp
			_bat_spawn_counter = 0
			btn.data.hp_changed.connect(_on_strigoi_hp_changed.bind(btn.data))
			break

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match state:
			States.OPTIONS:
				pass
			States.TARGETS:
				state = States.OPTIONS
				_heal_cursor.hide()
				_cursor.show()
				_options_menu.button_focus()

func _process(delta: float) -> void:
	if state >= States.VICTORY:
		return

	var minigame_active: bool = state in [States.MINIGAME, States.SPECIAL_MINIGAME,
			States.DEFEND_MINIGAME, States.BOSS_MINIGAME, States.CARD_MINIGAME]

	if not _boss_mini_active and not minigame_active:
		var boss_alive: bool = false
		for btn in _enemies_menu.get_buttons():
			if btn.data != null and btn.data.has_hp() \
					and btn.data.name.strip_edges() in BOSS_NAMES:
				boss_alive = true
				break

		if boss_alive:
			_boss_mini_timer += delta
			if _boss_mini_timer >= _boss_mini_next:
				_boss_mini_timer = 0.0
				_boss_mini_next  = randf_range(BOSS_MINI_MIN, BOSS_MINI_MAX)
				_trigger_boss_minigame()
		else:
			_boss_mini_timer = 0.0

	if not _card_mini_active and not minigame_active:
		_card_mini_timer += delta
		if _card_mini_timer >= _card_mini_next:
			_card_mini_timer = 0.0
			_card_mini_next  = randf_range(CARD_MINI_MIN, CARD_MINI_MAX)
			_trigger_card_minigame()

func _trigger_boss_minigame() -> void:
	if state in [States.MINIGAME, States.SPECIAL_MINIGAME,
				 States.DEFEND_MINIGAME, States.BOSS_MINIGAME, States.CARD_MINIGAME]:
		return

	_boss_mini_active = true
	state = States.BOSS_MINIGAME

	_options.hide()
	_cursor.hide()
	_down_cursor.hide()
	_heal_cursor.hide()
	get_viewport().gui_release_focus()

	_boss_minigame.start()

func _on_boss_minigame_completed(success: bool) -> void:
	_boss_mini_active = false

	if not success:
		for p in Data.party:
			if p.has_hp():
				p.healhurt(-BOSS_MINI_DAMAGE)

	_card_mini_timer = 0.0
	_card_mini_next  = randf_range(CARD_MINI_MIN, CARD_MINI_MAX)

	if state < States.VICTORY:
		state = States.OPTIONS
		advance_atb_queue(false)

func _trigger_card_minigame() -> void:
	if state in [States.MINIGAME, States.SPECIAL_MINIGAME,
				 States.DEFEND_MINIGAME, States.BOSS_MINIGAME, States.CARD_MINIGAME]:
		return

	_card_mini_active = true
	state = States.CARD_MINIGAME

	_options.hide()
	_cursor.hide()
	_down_cursor.hide()
	_heal_cursor.hide()
	get_viewport().gui_release_focus()

	_card_minigame.start()

func _on_card_minigame_completed(success: bool) -> void:
	_card_mini_active = false

	if not success:
		for p in Data.party:
			if p.has_hp():
				p.healhurt(-CARD_MINI_DAMAGE)

	_boss_mini_timer = 0.0
	_boss_mini_next  = randf_range(BOSS_MINI_MIN, BOSS_MINI_MAX)

	if state < States.VICTORY:
		state = States.OPTIONS
		advance_atb_queue(false)

func find_valid_target(target: BattleActor) -> BattleActor:
	if target.has_hp():
		return target
	var friendly: bool = target.friendly
	var btns: Array    = _players_menu.get_buttons() if friendly else _enemies_menu.get_buttons()
	target = null
	btns.shuffle()
	for btn: BattleActorButton in btns:
		if btn.data != null and btn.data.has_hp():
			target = btn.data
			break
	if target == null:
		state = States.GAMEOVER if friendly else States.VICTORY
	return target

func end() -> void:
	event_queue.clear()
	players_atb_queue.clear()
	_cursor.hide()
	_options.hide()
	_down_cursor.hide()
	_heal_cursor.hide()
	await get_tree().create_timer(0.5, false).timeout
	_gui.hide()
	for pi in _players_infos:
		pi.highlight(false)
		pi.reset()
		pi.stop()

	if Globals.is_duel:
		_end_duel()
		return

	match state:
		States.GAMEOVER:
			await get_tree().create_timer(1.0, false).timeout
			WaveManager.reset(WaveManager.difficulty)
			get_tree().change_scene_to_file("res://scene/main_menu.tscn")

		States.VICTORY:
			print("[battle.gd] Val curent terminat (val index=", WaveManager.current_wave, ")")
			if WaveManager.advance_wave():
				print("[battle.gd] Trec la următorul val, arăt statisticile...")
				await _show_wave_stats(WaveManager.get_wave_label())
				get_tree().reload_current_scene()
			else:
				print("[battle.gd] VICTORIE FINALĂ — ai terminat jocul!")
				await _show_wave_stats("VICTORIE! Ai terminat jocul!")
				await _show_wave_transition("VICTORIE!\nAi învins-o pe Zamolxes!", 2.5)
				WaveManager.reset(WaveManager.difficulty)
				get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _end_duel() -> void:
	DuelNetwork.disconnect_clean()
	var won: bool = state == States.VICTORY
	Globals.is_duel = false

	await _show_wave_transition(
		"VICTORIE!\nAi învins adversarul!" if won else "ÎNFRÂNGERE\nAdversarul te-a învins.",
		2.0
	)
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _show_wave_transition(text: String, duration: float) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.modulate = Color(1, 1, 1, 0)
	layer.add_child(label)

	get_tree().root.add_child(layer)

	var tween: Tween = create_tween()
	tween.tween_property(bg, "color:a", 0.85, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(duration)
	tween.tween_property(bg, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished

	layer.queue_free()

func _show_wave_stats(next_wave_label: String) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100

	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.12, 0.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)

	var panel: PanelContainer = PanelContainer.new()
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color            = Color(0.08, 0.11, 0.22, 0.95)
	panel_style.border_color        = Color(0.55, 0.75, 1.0, 0.7)
	panel_style.border_width_left   = 2
	panel_style.border_width_right  = 2
	panel_style.border_width_top    = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left     = 16
	panel_style.corner_radius_top_right    = 16
	panel_style.corner_radius_bottom_left  = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 380)
	panel.position = Vector2(-280, -190)
	layer.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_theme_constant_override("margin_top",    30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var inner: VBoxContainer = VBoxContainer.new()
	inner.add_theme_constant_override("separation", 18)
	margin.add_child(inner)

	var title: Label = Label.new()
	title.text = " Statistici "
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
	inner.add_child(title)

	var sep: HSeparator = HSeparator.new()
	var sep_style: StyleBoxFlat = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.4, 0.6, 1.0, 0.35)
	sep_style.content_margin_top    = 4
	sep_style.content_margin_bottom = 4
	sep.add_theme_stylebox_override("separator", sep_style)
	inner.add_child(sep)

	var _make_stat_row: Callable = func(icon: String, label_text: String, value_text: String, color: Color) -> HBoxContainer:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var lbl: Label = Label.new()
		lbl.text = icon + "  " + label_text
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.85, 0.95))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var val_lbl: Label = Label.new()
		val_lbl.text = value_text
		val_lbl.add_theme_font_size_override("font_size", 20)
		val_lbl.add_theme_color_override("font_color", color)
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(lbl)
		row.add_child(val_lbl)
		return row

	var words_pct: int = 0
	if _stat_words_total > 0:
		words_pct = int(float(_stat_words_correct) / float(_stat_words_total) * 100.0)
	var correct_str: String = str(_stat_words_correct) + " / " + str(_stat_words_total) + " (" + str(words_pct) + "%)"

	var speed_str: String = "—"
	if _stat_typing_time > 0.01:
		var cps: float = float(_stat_typing_chars) / _stat_typing_time
		speed_str = "%.1f" % cps + " car/s"

	var specials_str: String = str(_stat_specials_used)

	var word_color: Color
	if words_pct >= 70:
		word_color = Color(0.3, 1.0, 0.5)
	elif words_pct >= 40:
		word_color = Color(1.0, 0.85, 0.2)
	else:
		word_color = Color(1.0, 0.35, 0.35)

	inner.add_child(_make_stat_row.call("📖", "Cuvinte ghicite corect", correct_str, word_color))
	inner.add_child(_make_stat_row.call("⌨",  "Viteză medie scriere",   speed_str,   Color(0.4, 0.85, 1.0)))
	inner.add_child(_make_stat_row.call("⚡",  "Special attacks folosite", specials_str, Color(1.0, 0.75, 0.2)))

	var sep2: HSeparator = HSeparator.new()
	sep2.add_theme_stylebox_override("separator", sep_style)
	inner.add_child(sep2)

	var next_lbl: Label = Label.new()
	next_lbl.text = "Următor: " + next_wave_label
	next_lbl.add_theme_font_size_override("font_size", 22)
	next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	inner.add_child(next_lbl)

	get_tree().root.add_child(layer)

	panel.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(bg, "color:a", 0.9, 0.5)
	tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.5)
	tween.tween_interval(3.5)
	tween.tween_property(bg, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished

	layer.queue_free()

func advance_atb_queue(remove_front: bool = true) -> void:
	if state >= States.VICTORY:
		return
	state = States.OPTIONS
	if players_atb_queue.is_empty():
		return
	if remove_front:
		var cur: PlayerInfoBar = players_atb_queue.pop_front()
		cur.highlight(false)
	if players_atb_queue.is_empty():
		get_viewport().gui_release_focus()
		_options.hide()
		_cursor.hide()
		_down_cursor.hide()
		_heal_cursor.hide()
	else:
		var nxt: PlayerInfoBar = players_atb_queue.front()
		var idx: int           = nxt.get_index()
		nxt.highlight()
		player = Data.party[idx]
		_options.show()
		_options_menu.button_focus(0)
		_down_cursor.show()
		_down_cursor.global_position = _players_menu.get_buttons()[idx].global_position - Vector2(-40, 60)
		_update_special_button()

func run_event() -> void:
	event_runing = true
	await get_tree().create_timer(0.3, false).timeout
	if event_queue.is_empty():
		event_runing = false
		return
	if state >= States.VICTORY:
		return

	var event: Array        = event_queue.pop_front()
	var actor: BattleActor  = event[ACTOR]
	var target: BattleActor = event[TARGET]

	if !actor.can_act():
		run_event()
		return

	target = find_valid_target(target)
	if target == null:
		end()
		return

	actor.act()
	await get_tree().create_timer(0.25, false).timeout

	match event[ACTION]:
		Actions.ATTACK:
			var mult: float = event[3] if event.size() > 3 else 1.0
			target.healhurt(roundi(-actor.strength * mult))
			if (actor.friendly or Globals.is_duel) and mult > 0.0:
				actor.gain_sp()

		Actions.DEFEND:
			var dp: int = int(event[3]) if event.size() > 3 else 4
			actor.gain_defend(dp)
			if actor.friendly or Globals.is_duel:
				actor.gain_sp()

		Actions.SPECIAL:
			var mult: float = event[3] if event.size() > 3 else 2.0
			target.healhurt(roundi(-actor.strength * mult))
			if actor.friendly or Globals.is_duel:
				actor.consume_sp()

		Actions.ANNA_HEAL:
			target.healhurt(20)
			if actor.friendly or Globals.is_duel:
				actor.consume_sp()

		Actions.MAGNUS_SPECIAL:
			var team: Array = []
			if actor.friendly:
				team = Data.party
			else:
				for btn in _enemies_menu.get_buttons():
					if btn.data != null:
						team.append(btn.data)
			for ally: BattleActor in team:
				if ally.has_hp():
					ally.gain_defend(4)
			if actor.friendly or Globals.is_duel:
				actor.consume_sp()

	await get_tree().create_timer(0.2, false).timeout

	if actor.friendly:
		var pi_idx: int = Data.party.find(actor)
		if pi_idx != -1 and actor.has_hp():
			_players_infos[pi_idx].reset()
	else:
		for eb in _enemies_menu.get_children():
			if eb.data == actor:
				eb.reset(true)
				break

	run_event()

func add_event(event: Array) -> void:
	event_queue.append(event)
	if !event_runing:
		run_event()

func _update_special_button() -> void:
	for btn in _options_menu.get_buttons():
		if btn.text == "Special":
			btn.disabled = not (player != null and player.can_special())
			return

func _on_player_sp_changed(_sp: float, _actor: BattleActor) -> void:
	if player == _actor:
		_update_special_button()

func _start_player_minigame(actor: BattleActor, target: BattleActor, chosen: Actions) -> void:
	state = States.MINIGAME
	_options.hide()
	_cursor.hide()
	_down_cursor.hide()
	get_viewport().gui_release_focus()
	var idx: int = Data.party.find(actor)
	if idx != -1:
		_players_infos[idx].stop()
	_pending_event = [actor, target, chosen]
	_minigame.start()

func _on_minigame_completed(multiplier: float) -> void:
	var actor: BattleActor = _pending_event[ACTOR]
	var target: BattleActor = _pending_event[TARGET]
	var idx: int = Data.party.find(actor)
	if idx != -1 and actor.has_hp():
		_players_infos[idx].reset()
	var ev: Array = _pending_event.duplicate()
	ev.append(multiplier)
	_pending_event.clear()
	_stat_words_total += 2
	if multiplier >= 1.0:
		_stat_words_correct += 2
	elif multiplier >= 0.5:
		_stat_words_correct += 1
	add_event(ev)
	_duel_send(actor, "attack", target, multiplier)
	advance_atb_queue()

func _start_special_minigame(actor: BattleActor, target: BattleActor, resolved_action: Actions) -> void:
	state = States.SPECIAL_MINIGAME
	_options.hide()
	_cursor.hide()
	_down_cursor.hide()
	_heal_cursor.hide()
	get_viewport().gui_release_focus()
	var idx: int = Data.party.find(actor)
	if idx != -1:
		_players_infos[idx].stop()
	_pending_event = [actor, target, resolved_action]
	if actor.name.strip_edges() == "Shingen":
		_bliz.start(actor, target)
	else:
		_special_minigame.start()

func _on_special_minigame_completed(success: bool) -> void:
	var actor: BattleActor = _pending_event[ACTOR]
	var target: BattleActor = _pending_event[TARGET]
	var resolved_action: Actions = _pending_event[ACTION]
	var idx: int = Data.party.find(actor)
	if idx != -1 and actor.has_hp():
		_players_infos[idx].reset()
	if success:
		_stat_specials_used += 1
		_stat_typing_chars += _special_minigame.last_chars_typed
		_stat_typing_time  += _special_minigame.last_time_taken
		add_event(_pending_event.duplicate())
		_duel_broadcast_special(actor, target, resolved_action)
	else:
		actor.consume_sp()
	_pending_event.clear()
	advance_atb_queue()

func _on_shingen_special_completed(multiplier: float) -> void:
	var actor: BattleActor = _pending_event[ACTOR]
	var target: BattleActor = _pending_event[TARGET]
	var resolved_action: Actions = _pending_event[ACTION]
	var idx: int = Data.party.find(actor)
	if idx != -1 and actor.has_hp():
		_players_infos[idx].reset()
	if multiplier > 0.0:
		_stat_specials_used += 1
		var ev = _pending_event.duplicate()
		ev.append(multiplier)
		add_event(ev)
		_duel_broadcast_special(actor, target, resolved_action)
	else:
		actor.consume_sp()
	_pending_event.clear()
	advance_atb_queue()

func _start_defend_minigame(actor: BattleActor) -> void:
	state = States.DEFEND_MINIGAME
	_options.hide()
	_cursor.hide()
	_down_cursor.hide()
	get_viewport().gui_release_focus()
	var idx: int = Data.party.find(actor)
	if idx != -1:
		_players_infos[idx].stop()
	_pending_event = [actor, actor, Actions.DEFEND]
	_defend_minigame.start()

func _on_defend_minigame_completed(defend_points: int) -> void:
	var actor: BattleActor = _pending_event[ACTOR]
	var idx: int = Data.party.find(actor)
	if idx != -1 and actor.has_hp():
		_players_infos[idx].reset()
	if defend_points > 0:
		actor.gain_defend(defend_points)
		if actor.friendly:
			actor.gain_sp()
		_duel_send(actor, "defend", actor, 1.0, defend_points)
		_stat_words_total   += 1
		_stat_words_correct += 1
	_pending_event.clear()
	advance_atb_queue()

func _start_anna_heal_targeting() -> void:
	_cursor.disabled = true
	_cursor.hide()
	_down_cursor.hide()
	_heal_cursor.show()

	var btns: Array = _players_menu.get_buttons()
	for i in btns.size():
		if i == ANNA_INDEX:
			continue
		var btn: PlayerButton = btns[i]
		if btn.data.has_hp():
			btn.grab_focus()
			_heal_cursor.global_position = btn.global_position + Vector2(btn.size.x * 0.5 - _heal_cursor.size.x * 0.5, btn.size.y * 0.6)
			break

	_cursor.hide()
	get_viewport().gui_focus_changed.connect(_on_heal_target_focus_changed)

func _stop_anna_heal_targeting() -> void:
	_cursor.disabled = false
	_cursor.show()
	if get_viewport().gui_focus_changed.is_connected(_on_heal_target_focus_changed):
		get_viewport().gui_focus_changed.disconnect(_on_heal_target_focus_changed)
	_heal_cursor.hide()

func _on_heal_target_focus_changed(node: Control) -> void:
	if not node is PlayerButton:
		return
	var btn: PlayerButton = node as PlayerButton
	if btn.get_index() == ANNA_INDEX:
		var btns: Array = _players_menu.get_buttons()
		for i in btns.size():
			if i == ANNA_INDEX:
				continue
			var candidate: PlayerButton = btns[i]
			if candidate.data.has_hp():
				candidate.grab_focus()
				return
		return
	_heal_cursor.global_position = btn.global_position + Vector2(
		btn.size.x * 0.5 - _heal_cursor.size.x * 0.5 - 10,
		btn.size.y * 0.6 - 150)

func _on_options_button_pressed(button: BaseButton) -> void:
	match button.text:
		"Attack":
			action = Actions.ATTACK
			state  = States.TARGETS
			_enemies_menu.button_focus()
		"Defend":
			_start_defend_minigame(player)
		"Special":
			if not (player and player.can_special()):
				return
			var pname: String = player.name.strip_edges()
			match pname:
				"Anna":
					action = Actions.ANNA_HEAL
					state  = States.TARGETS
					_players_menu.button_focus()
					_start_anna_heal_targeting()
				"Magnus":
					_start_special_minigame(player, player, Actions.MAGNUS_SPECIAL)
				_:
					action = Actions.SPECIAL
					state  = States.TARGETS
					_enemies_menu.button_focus()

func _on_player_atb_ready(player_info: PlayerInfoBar) -> void:
	players_atb_queue.append(player_info)
	if players_atb_queue.size() == 1:
		advance_atb_queue(false)

func _on_enemies_button_pressed(button: EnemyButton) -> void:
	var target: BattleActor = button.data
	if action == Actions.SPECIAL:
		_start_special_minigame(player, target, Actions.SPECIAL)
	else:
		_start_player_minigame(player, target, action)

func _on_players_button_pressed(button: PlayerButton) -> void:
	var target: BattleActor = button.data
	if action == Actions.ANNA_HEAL and button.get_index() == ANNA_INDEX:
		return
	_stop_anna_heal_targeting()
	if action == Actions.ANNA_HEAL:
		_start_special_minigame(player, target, Actions.ANNA_HEAL)
	else:
		add_event([player, target, action, 1.0])
		advance_atb_queue()

func _on_enemies_atb_ready(enemy: BattleActor) -> void:
	if Globals.is_duel:
		for eb in _enemies_menu.get_children():
			if eb is EnemyButton and eb.data == enemy:
				eb.reset(true)
				break
		return
	var event: Array = EnemyAI.decide(enemy, Data.party, WaveManager.difficulty)
	if event.is_empty():
		return
	event[ACTION] = Actions.ATTACK
	add_event(event)

func _on_enemy_hp_changed(_hp: int, _change: int, index: int, actor: BattleActor) -> void:
	if index < 0 or index >= _enemies_labels.size():
		return
	if _enemies_labels[index].text == "":
		return
	_enemies_labels[index].text = actor.name + "  HP  " + str(_hp)

func _on_enemy_defeated_label(index: int) -> void:
	if index < 0 or index >= _enemies_labels.size():
		return
	_enemies_labels[index].text = ""

func _on_battle_actor_defeated(data: BattleActor) -> void:
	if not find_valid_target(data):
		end()
		return
	var pi_idx: int = Data.party.find(data)
	if pi_idx != -1:
		var pinfo: PlayerInfoBar = _players_infos[pi_idx]
		pinfo.highlight(false)
		pinfo.stop()
		players_atb_queue.erase(pinfo)
		if players_atb_queue.is_empty():
			get_viewport().gui_release_focus()
			_options.hide()
			_cursor.hide()
			_down_cursor.hide()
			_heal_cursor.hide()

func _on_strigoi_hp_changed(new_hp: int, change: int, strigoi: BattleActor) -> void:
	if change >= 0 or _strigoi_last_hp == -1:
		return
	var lost: int = _strigoi_last_hp - new_hp
	_strigoi_last_hp = new_hp
	_bat_spawn_counter += lost
	if _bat_spawn_counter >= BAT_SPAWN_THRESHOLD:
		_bat_spawn_counter -= BAT_SPAWN_THRESHOLD
		_spawn_bats(strigoi)

func _spawn_bats(strigoi: BattleActor) -> void:
	if state >= States.VICTORY:
		return

	var strigoi_btn: EnemyButton = null
	var strigoi_idx: int = -1
	var children: Array = _enemies_menu.get_children()
	for i in children.size():
		var c = children[i]
		if c is EnemyButton and c.data == strigoi:
			strigoi_btn = c
			strigoi_idx = i
			break
	if strigoi_btn == null:
		return

	var bat_id: int = Time.get_ticks_msec()

	var bat_positions: Array[Vector2] = [
		Vector2(50, 280),
		Vector2(310, 260),
	]

	var free_label_slots: Array[int] = [1, 3]

	for side in [0, 1]:
		var bat_actor: BattleActor = BattleActor.new(BAT_HP, BAT_STRENGTH)
		bat_actor.friendly = false
		bat_actor.name     = "Liliac " + str(bat_id + side)

		var btn: EnemyButton = BAT_SCENE.instantiate()
		_enemies_menu.add_child(btn)

		btn.position = bat_positions[side]
		btn.size     = Vector2(120, 170)

		btn.force_spawn(bat_actor)

		btn.pressed.connect(_enemies_menu._on_Button_pressed.bind(btn))
		btn.focus_entered.connect(_enemies_menu._on_Button_focused.bind(btn))
		btn.focus_exited.connect(_enemies_menu._on_Button_focus_exited.bind(btn))
		btn.tree_exiting.connect(_enemies_menu._on_Button_tree_exiting.bind(btn))

		btn.atb_ready.connect(_on_enemies_atb_ready.bind(bat_actor))
		bat_actor.defeated.connect(_on_battle_actor_defeated.bind(bat_actor))

		var label_idx: int = free_label_slots[side]
		if label_idx < _enemies_labels.size():
			_enemies_labels[label_idx].text = bat_actor.name + "  HP  " + str(bat_actor.hp)
			bat_actor.hp_changed.connect(_on_enemy_hp_changed.bind(label_idx, bat_actor))
			bat_actor.defeated.connect(_on_enemy_defeated_label.bind(label_idx))

	print("[battle.gd] Strigoi a spawnat 2 lilieci (HP ramas: ", strigoi.hp, ")")

func _duel_send(actor: BattleActor, action: String, target: BattleActor,
		multiplier: float = 1.0, defend_points: int = 0) -> void:
	if not Globals.is_duel or not actor.friendly:
		return

	var actor_idx: int = Data.party.find(actor)
	if actor_idx == -1:
		return

	var target_type: String
	var target_idx:  int = -1

	if target == actor:
		target_type = "self"
	else:
		var ally_idx: int = Data.party.find(target)
		if ally_idx != -1:
			target_type = "ally"
			target_idx  = ally_idx
		else:
			target_type = "enemy"
			target_idx  = _duel_enemy_actors.find(target)

	DuelNetwork.send_party_action(actor_idx, action, target_type, target_idx,
			multiplier, defend_points)

func _duel_broadcast_special(actor: BattleActor, target: BattleActor,
		resolved_action: Actions) -> void:
	var action_str: String = ""
	match resolved_action:
		Actions.SPECIAL:        action_str = "special"
		Actions.ANNA_HEAL:      action_str = "anna_heal"
		Actions.MAGNUS_SPECIAL: action_str = "magnus_special"
		_:
			return
	_duel_send(actor, action_str, target)

func _on_duel_party_action(data: Dictionary) -> void:
	if not Globals.is_duel or state >= States.VICTORY:
		return

	var actor_idx: int = data.get("actor_index", -1)
	if actor_idx < 0 or actor_idx >= _duel_enemy_actors.size():
		return

	var actor: BattleActor = _duel_enemy_actors[actor_idx]
	if actor == null or not actor.can_act():
		return

	var action_str:  String = data.get("action", "")
	var target_type: String = data.get("target_type", "self")
	var target_idx:  int    = data.get("target_index", -1)

	var target: BattleActor = actor
	match target_type:
		"enemy":
			if target_idx >= 0 and target_idx < Data.party.size():
				target = Data.party[target_idx]
		"ally":
			if target_idx >= 0 and target_idx < _duel_enemy_actors.size():
				target = _duel_enemy_actors[target_idx]
		_:
			target = actor

	if target == null:
		return

	match action_str:
		"attack":
			add_event([actor, target, Actions.ATTACK, float(data.get("multiplier", 1.0))])
		"defend":
			var dp: int = int(data.get("defend_points", 4))
			add_event([actor, actor, Actions.DEFEND, float(dp)])
		"special":
			add_event([actor, target, Actions.SPECIAL])
		"anna_heal":
			add_event([actor, target, Actions.ANNA_HEAL])
		"magnus_special":
			add_event([actor, actor, Actions.MAGNUS_SPECIAL])

func _on_duel_opponent_disconnected() -> void:
	if not Globals.is_duel or state >= States.VICTORY:
		return
	state = States.VICTORY
	end()
