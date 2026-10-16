extends RefCounted

const DIALOGUE_PANEL = preload("res://Scenes/DialoguePanel.tscn")

var canvas_layer: CanvasLayer
var tween_owner: Node

var turn_timer_limit_seconds: int = 300
var turn_timer_counter_key: int = 0
var turn_timer_opponent_counter_key: int = 2
var _last_knocked_turn_color: int = 0
var clock_frame_texture: Texture2D
var clock_button_texture: Texture2D
var clock_back_texture: Texture2D
## Hands back the match background, for the pieces of interface that live
## inside it rather than in the HUD's own layer.
var match_background_provider: Callable

var turn_timer_gap: float = 8.0
var turn_timer_z_index: int = 961
var deck_counter_size: Vector2 = Vector2(82, 42)
## Where the two tabs stand on the 1920x1080 canvas the room is drawn on, so
## they stay under the board's near corners whatever shape the window is. The
## Turn Page tab's twin is set on the node in main.tscn.
const END_TURN_TAB_CANVAS_X: float = 1125.0

var player_name_label_size: Vector2 = Vector2(180, 28)
var player_name_label_gap: float = 8.0
var player_portrait_size: Vector2 = Vector2(224, 89)
var player_portrait_margin: float = 22.0
var player_portrait_top_position: Vector2 = Vector2(70, 4)
var player_portrait_z_index: int = 928

var create_digit_counter_callback: Callable
var set_digit_counter_value_callback: Callable
var end_turn_pressed_callback: Callable
var game_over_provider: Callable
var can_control_current_turn_provider: Callable
var tutorial_end_turn_allowed_provider: Callable
var show_first_turn_end_provider: Callable
var can_end_first_turn_provider: Callable
var can_switch_action_provider: Callable
var can_affix_action_provider: Callable
var can_move_action_provider: Callable
var current_turn_color_provider: Callable
var player_id_for_color_provider: Callable
var turn_timer_timeout_callback: Callable
var deck_visual_provider: Callable
var local_view_color_provider: Callable
var own_color_provider: Callable
var visible_viewport_size_provider: Callable
var board_screen_size_provider: Callable
var game_result_context_provider: Callable

var end_turn_button: Button
var turn_timer_counter_container: Control
var player_clock_seconds: Dictionary = {0: 300.0, 1: 300.0}
var result_overlay: ColorRect
var result_label: Label
var player_name_labels: Dictionary = {}
var player_portrait_views: Dictionary = {}
## Set by BossDialogueDirector while it is showing a line in the opponent panel.
## The colour behind the opponent's face: plain white, where the mentor and
## the comics use a warm card.
const OPPONENT_PORTRAIT_BACKGROUND: Color = Color(1.0, 1.0, 1.0, 1.0)

## Drops the opponent's panel so its words land below the drawn window rather
## than across its lower frame. Only this panel: the comics and the tutorial
## use the same scene and want it where it is.
const OPPONENT_PANEL_DROP: float = 44.0

var opponent_panel: DialoguePanel
var opponent_panel_managed_by_hud: bool = false
## Owns when the opponent is on screen and for how long. Null for a panel the
## HUD did not build - the tutorial brings its own and drives it itself.
var opponent_speech: OpponentSpeechPanel
var current_player_names: Dictionary = {
	0: tr("Player"),
	1: tr("Opponent"),
}
var current_player_portraits: Dictionary = {
	0: PortraitLibrary.get_default_portrait_for_player_id(0),
	1: PortraitLibrary.get_default_portrait_for_player_id(1),
}

func configure(config: Dictionary) -> void:
	canvas_layer = config.get("canvas_layer", canvas_layer)
	tween_owner = config.get("tween_owner", tween_owner)
	turn_timer_limit_seconds = int(config.get("turn_timer_limit_seconds", turn_timer_limit_seconds))
	turn_timer_counter_key = int(config.get("turn_timer_counter_key", turn_timer_counter_key))
	turn_timer_opponent_counter_key = int(config.get("turn_timer_opponent_counter_key", turn_timer_opponent_counter_key))
	clock_frame_texture = config.get("clock_frame_texture", clock_frame_texture)
	clock_button_texture = config.get("clock_button_texture", clock_button_texture)
	clock_back_texture = config.get("clock_back_texture", clock_back_texture)
	match_background_provider = config.get("match_background_provider", match_background_provider)
	turn_timer_gap = float(config.get("turn_timer_gap", turn_timer_gap))
	turn_timer_z_index = int(config.get("turn_timer_z_index", turn_timer_z_index))
	deck_counter_size = config.get("deck_counter_size", deck_counter_size)
	player_name_label_size = config.get("player_name_label_size", player_name_label_size)
	player_name_label_gap = float(config.get("player_name_label_gap", player_name_label_gap))
	player_portrait_size = config.get("player_portrait_size", player_portrait_size)
	player_portrait_margin = float(config.get("player_portrait_margin", player_portrait_margin))
	player_portrait_top_position = config.get("player_portrait_top_position", player_portrait_top_position)
	player_portrait_z_index = int(config.get("player_portrait_z_index", player_portrait_z_index))
	current_player_names = config.get("current_player_names", current_player_names)
	current_player_portraits = config.get("current_player_portraits", current_player_portraits)

	create_digit_counter_callback = config.get("create_digit_counter_callback", create_digit_counter_callback)
	set_digit_counter_value_callback = config.get("set_digit_counter_value_callback", set_digit_counter_value_callback)
	end_turn_pressed_callback = config.get("end_turn_pressed_callback", end_turn_pressed_callback)
	game_over_provider = config.get("game_over_provider", game_over_provider)
	can_control_current_turn_provider = config.get("can_control_current_turn_provider", can_control_current_turn_provider)
	tutorial_end_turn_allowed_provider = config.get("tutorial_end_turn_allowed_provider", tutorial_end_turn_allowed_provider)
	show_first_turn_end_provider = config.get("show_first_turn_end_provider", show_first_turn_end_provider)
	can_end_first_turn_provider = config.get("can_end_first_turn_provider", can_end_first_turn_provider)
	can_switch_action_provider = config.get("can_switch_action_provider", can_switch_action_provider)
	can_affix_action_provider = config.get("can_affix_action_provider", can_affix_action_provider)
	can_move_action_provider = config.get("can_move_action_provider", can_move_action_provider)
	current_turn_color_provider = config.get("current_turn_color_provider", current_turn_color_provider)
	player_id_for_color_provider = config.get("player_id_for_color_provider", player_id_for_color_provider)
	turn_timer_timeout_callback = config.get("turn_timer_timeout_callback", turn_timer_timeout_callback)
	deck_visual_provider = config.get("deck_visual_provider", deck_visual_provider)
	local_view_color_provider = config.get("local_view_color_provider", local_view_color_provider)
	own_color_provider = config.get("own_color_provider", own_color_provider)
	visible_viewport_size_provider = config.get("visible_viewport_size_provider", visible_viewport_size_provider)
	board_screen_size_provider = config.get("board_screen_size_provider", board_screen_size_provider)
	game_result_context_provider = config.get("game_result_context_provider", game_result_context_provider)

func create_end_turn_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	# A tab under the right-hand end of the board: up when the turn can be
	# ended, gone below the edge when it cannot.
	var tab := MatchTabButton.new()
	tab.canvas_centre_x = END_TURN_TAB_CANVAS_X
	end_turn_button = tab
	canvas_layer.add_child(end_turn_button)
	end_turn_button.name = "EndTurnTab"
	end_turn_button.text = tr("END_TURN")
	end_turn_button.z_index = 960

	# Parented to the tab rather than placed beside it, so it rides along as
	# the tab slides instead of being re-measured on every move.
	if end_turn_pressed_callback.is_valid():
		end_turn_button.pressed.connect(func(): end_turn_pressed_callback.call())
	update_end_turn_button()

## Two clocks in one drawn frame: the opponent above, the player below. Each
## is a four digit counter with no frame and no colon of its own, because the
## drawing supplies both and is laid over the top.
func create_turn_timer_ui() -> void:
	if !create_digit_counter_callback.is_valid() or canvas_layer == null:
		return

	var clock := MatchClock.new()
	turn_timer_counter_container = clock
	canvas_layer.add_child(clock)
	clock.name = "ChessClock"
	clock.z_index = turn_timer_z_index
	clock.modulate = MatchBackgroundController.PAPER_TINT
	clock.build(
		clock_back_texture,
		clock_frame_texture,
		clock_button_texture,
		Callable(self, "_make_clock_counter"),
		deck_counter_size.y,
		turn_timer_opponent_counter_key,
		turn_timer_counter_key
	)

	reset_turn_timer()
	arrange_turn_timer_ui()
	update_turn_timer_visibility()

## A four digit counter for one of the clock's faces: no frame and no colon of
## its own, because the drawn tag carries both. It works out its own colon gap
## from the width it is told to fill, since only it knows how wide a digit is.
func _make_clock_counter(counter_name: String, counter_key: int, span: float) -> Control:
	return create_digit_counter_callback.call(counter_name, counter_key, 4, true, {
		"show_frame": false,
		"separator_glyph": false,
		"span_width": span,
		"content_inset_x": 0.0,
	}) as Control

## Shows or hides one piece of the match interface by name.
##
## A match has all of it up from the first frame. The tutorial brings it in one
## piece at a time, as it teaches what each is for, so it needs to address them
## singly - and by something steadier than a node path, since several of these
## are built at runtime and live in different parts of the tree.
##
## Known names: codex, opponent_codex, page_counter, turn_page, end_turn,
## clock, opponent_panel.
func set_hud_element_visible(element: StringName, shown: bool) -> void:
	var node: CanvasItem = _find_hud_element(element)
	if node != null:
		node.visible = shown

func _find_hud_element(element: StringName) -> CanvasItem:
	match element:
		&"end_turn":
			return end_turn_button
		&"clock":
			return turn_timer_counter_container
		&"opponent_panel":
			return opponent_panel
		&"codex":
			return canvas_layer.get_node_or_null("Codex") as CanvasItem if canvas_layer != null else null
		&"opponent_codex":
			if match_background_provider.is_valid():
				var background = match_background_provider.call()
				if background != null:
					return background.get_node_or_null("OpponentCodexSlot/Codex") as CanvasItem
			return null
		&"page_counter", &"turn_page":
			var panel: Node = canvas_layer.get_node_or_null("CodexPanel") if canvas_layer != null else null
			if panel == null:
				return null
			var child_name: String = "CountsRow" if element == &"page_counter" else "TurnPageButton"
			return panel.get_node_or_null(child_name) as CanvasItem
	push_warning("Unknown HUD element: %s" % element)
	return null

func create_result_ui() -> void:
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	result_overlay = ColorRect.new()
	canvas_layer.add_child(result_overlay)
	result_overlay.visible = false
	result_overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay.anchor_right = 1.0
	result_overlay.anchor_bottom = 1.0
	result_overlay.offset_left = 0.0
	result_overlay.offset_top = 0.0
	result_overlay.offset_right = 0.0
	result_overlay.offset_bottom = 0.0
	result_overlay.z_index = 2000

	result_label = Label.new()
	result_overlay.add_child(result_label)
	result_label.anchor_right = 1.0
	result_label.anchor_bottom = 1.0
	result_label.offset_left = 0.0
	result_label.offset_top = 0.0
	result_label.offset_right = 0.0
	result_label.offset_bottom = 0.0
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label_settings := LabelSettings.new()
	label_settings.font_size = 72
	label_settings.font_color = Color(1.0, 1.0, 1.0)
	label_settings.outline_size = 8
	label_settings.outline_color = Color(0.0, 0.0, 0.0)
	result_label.label_settings = label_settings

func show_result_message(winner_color: int) -> void:
	if result_label == null or result_overlay == null:
		return

	var context: Dictionary = get_game_result_context()
	if bool(context.get("is_ai_vs_ai_batch", false)):
		result_label.text = tr("%s WINS!\nMATCH %d / %d") % [
			tr("WHITE") if winner_color == 1 else tr("BLACK"),
			int(context.get("ai_matches_played", 0)) + 1,
			int(context.get("ai_match_count", 0)),
		]
	elif bool(context.get("side_is_null", false)):
		result_label.text = tr("WHITE WINS!") if winner_color == 1 else tr("BLACK WINS!")
	else:
		var won: bool = winner_color == get_own_color()
		result_label.text = tr("YOU WON!") if won else tr("YOU LOST!")
		SFXManager.play("win" if won else "lose")
	result_overlay.visible = true

func initialize_player_portraits() -> void:
	current_player_portraits = {
		0: PortraitLibrary.get_default_portrait_for_player_id(0),
		1: PortraitLibrary.get_default_portrait_for_player_id(1),
	}

func create_player_portrait_ui() -> void:
	ensure_opponent_panel()
	update_opponent_panel()

func create_player_name_ui() -> void:
	ensure_opponent_panel()
	update_opponent_panel()

func ensure_opponent_panel() -> void:
	if opponent_panel != null and is_instance_valid(opponent_panel):
		return
	if canvas_layer == null or !is_instance_valid(canvas_layer):
		return

	var existing_panel := canvas_layer.get_node_or_null("DialoguePanel") as DialoguePanel
	if existing_panel != null:
		opponent_panel = existing_panel
		opponent_panel_managed_by_hud = false
		# A panel the scene brought itself - the tutorial's mentor - still has
		# to be printed on the room's paper, or its whites come out colder
		# than everything around it.
		opponent_panel.modulate = MatchBackgroundController.PAPER_TINT
		return

	opponent_panel = DIALOGUE_PANEL.instantiate() as DialoguePanel
	opponent_panel.name = "OpponentPanel"
	opponent_panel.z_index = player_portrait_z_index
	canvas_layer.add_child(opponent_panel)
	opponent_panel_managed_by_hud = true
	opponent_panel.set_portrait_background_color(OPPONENT_PORTRAIT_BACKGROUND)
	# Printed on the same paper as the room, or its whites come out colder
	# than everything around them.
	opponent_panel.modulate = MatchBackgroundController.PAPER_TINT
	opponent_panel.set_vertical_nudge(OPPONENT_PANEL_DROP)

	opponent_speech = OpponentSpeechPanel.new()
	opponent_speech.name = "OpponentSpeech"
	opponent_panel.add_child(opponent_speech)
	opponent_speech.setup(opponent_panel)

func update_player_name_labels() -> void:
	update_opponent_panel()

func update_player_portrait_views() -> void:
	update_opponent_panel()

## The opponent is not a standing part of a match's interface: they appear
## because they have something to say and leave once it has been read, which is
## `opponent_speech`'s business. All that is left here is keeping the face lit
## for whoever's turn it is, for a line that happens to be up.
func update_opponent_panel() -> void:
	ensure_opponent_panel()
	if opponent_panel == null or !is_instance_valid(opponent_panel) or !opponent_panel_managed_by_hud:
		return

	for owner_color in [1, -1]:
		if !is_stamp_hand_top(owner_color):
			continue
		opponent_panel.set_turn_focus(owner_color == get_current_turn_color())
		return

func get_portrait_config_for_player(player_id: int) -> PortraitConfig:
	if current_player_portraits.has(player_id):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[player_id], player_id)

	var string_key: String = str(player_id)
	if current_player_portraits.has(string_key):
		return PortraitLibrary.config_from_data_or_default(current_player_portraits[string_key], player_id)

	return PortraitLibrary.get_default_portrait_for_player_id(player_id)

func get_display_name_for_player(player_id: int) -> String:
	if current_player_names.has(player_id):
		return str(current_player_names[player_id])
	var string_key: String = str(player_id)
	if current_player_names.has(string_key):
		return str(current_player_names[string_key])
	return tr("Player")

func update_end_turn_button() -> void:
	if end_turn_button == null:
		return
	end_turn_button.visible = !is_game_over() and get_bool(show_first_turn_end_provider, false)
	end_turn_button.disabled = !can_control_current_turn() or !get_bool(can_end_first_turn_provider, false) or !is_tutorial_end_turn_allowed()

func reset_turn_timer() -> void:
	player_clock_seconds = {0: float(turn_timer_limit_seconds), 1: float(turn_timer_limit_seconds)}
	update_turn_timer_label()
	update_turn_timer_visibility()

func sync_player_clocks(clock_state: Dictionary) -> void:
	if clock_state.is_empty():
		return
	for player_id in [0, 1]:
		var value = clock_state.get(player_id, clock_state.get(str(player_id), turn_timer_limit_seconds))
		player_clock_seconds[player_id] = maxf(float(value), 0.0)
	update_turn_timer_label()

func update_turn_timer(delta: float) -> void:
	if turn_timer_counter_container == null:
		return
	if is_game_over():
		turn_timer_counter_container.visible = false
		return

	update_turn_timer_visibility()
	_handle_turn_change()
	if !should_run_turn_timer():
		return
	# Only the player on the move loses time. The host does the same sum and
	# its figures arrive with every state sync; this is here so the digits move
	# smoothly between those.
	var active_player_id: int = get_player_id_for_color(get_current_turn_color())
	player_clock_seconds[active_player_id] = maxf(
		float(player_clock_seconds.get(active_player_id, turn_timer_limit_seconds)) - maxf(delta, 0.0), 0.0)
	update_turn_timer_label()

## Everything that happens when the turn passes: the hanging clocks take a push
## and the rocker is thrown - and the rocker is what makes the sound, so there
## is nothing to play from here. Read from the turn colour rather than hooked to
## a signal, because this already runs every frame and there is no signal that
## fires on exactly this.
func _handle_turn_change() -> void:
	var turn_color: int = get_current_turn_color()
	if turn_color == _last_knocked_turn_color:
		return
	var had_previous: bool = _last_knocked_turn_color != 0
	_last_knocked_turn_color = turn_color

	var clock: MatchClock = turn_timer_counter_container as MatchClock
	if clock != null:
		clock.set_player_to_move(turn_color == get_own_color())
		if had_previous:
			clock.nudge(float(turn_color))

func update_turn_timer_label(animate: bool = true) -> void:
	var own_player_id: int = get_player_id_for_color(get_own_color())
	_set_clock_digits(turn_timer_counter_key, own_player_id, animate)
	_set_clock_digits(turn_timer_opponent_counter_key, 1 - own_player_id, animate)

func _set_clock_digits(counter_key: int, player_id: int, animate: bool) -> void:
	var total_seconds: int = maxi(ceili(float(player_clock_seconds.get(player_id, turn_timer_limit_seconds))), 0)
	var timer_digits: int = floori(float(total_seconds) / 60.0) * 100 + total_seconds % 60
	set_digit_counter_value(counter_key, timer_digits, animate)

func update_turn_timer_visibility() -> void:
	if turn_timer_counter_container == null:
		return
	turn_timer_counter_container.visible = !is_game_over() and should_show_turn_timer()

func clear_turn_timer_timeout_pending() -> void:
	pass

## Shown in a single player match as well as a networked one. Whoever is on
## the move loses time, an AI included: its clock runs while it thinks, the same
## as the host's own clock does (NetworkGameHost.process). A batch of
## AI-against-AI games has nobody to time, so that one still hides it, and so
## does a story boss met before the clock is introduced (BossDefinition.show_clock).
func should_show_turn_timer() -> bool:
	return !GameConfig.is_ai_vs_ai_batch and StoryManager.should_show_match_clock()

## Both clocks are on show, so this is no longer about whose turn it is - that
## is decided per clock in update_turn_timer. It only asks whether the match is
## running at all.
func should_run_turn_timer() -> bool:
	return should_show_turn_timer() and !is_game_over()

func is_current_turn_human_controlled() -> bool:
	var player_id: int = get_player_id_for_color(get_current_turn_color())
	if GameConfig.is_singleplayer:
		return GameConfig.get_player_controller(player_id) == GameConfig.CONTROLLER_HUMAN
	return true

func arrange_turn_timer_ui() -> void:
	if turn_timer_counter_container == null:
		return

	# Set down on the table beside the board, which is the only clear surface
	# left. Placed from the canvas so it keeps its place on that table at any
	# window shape.
	var viewport_size: Vector2 = turn_timer_counter_container.get_viewport_rect().size
	var centre: Vector2 = BoardCanvas.to_viewport(BoardCanvas.TABLE_RIGHT, viewport_size)
	# The clock drifts sideways on its own; its place is worked out here, so
	# the drift is added here rather than written into the node by the clock.
	var clock: MatchClock = turn_timer_counter_container as MatchClock
	if clock == null:
		return
	centre.x += clock.sway_offset
	var box: Vector2 = turn_timer_counter_container.size
	if box.x <= 0.0 or box.y <= 0.0:
		box = turn_timer_counter_container.get_combined_minimum_size()
	var top_left: Vector2 = centre - clock.face_offset()
	turn_timer_counter_container.anchor_left = 0.0
	turn_timer_counter_container.anchor_right = 0.0
	turn_timer_counter_container.anchor_top = 0.0
	turn_timer_counter_container.anchor_bottom = 0.0
	turn_timer_counter_container.offset_left = top_left.x
	turn_timer_counter_container.offset_right = top_left.x + box.x
	turn_timer_counter_container.offset_top = top_left.y
	turn_timer_counter_container.offset_bottom = top_left.y + box.y
func set_digit_counter_value(owner_key: int, count: int, animate: bool) -> void:
	if set_digit_counter_value_callback.is_valid():
		set_digit_counter_value_callback.call(owner_key, count, animate)

func is_game_over() -> bool:
	return get_bool(game_over_provider, false)

func can_control_current_turn() -> bool:
	return get_bool(can_control_current_turn_provider, false)

func is_tutorial_end_turn_allowed() -> bool:
	return get_bool(tutorial_end_turn_allowed_provider, true)

func get_current_turn_color() -> int:
	return get_int(current_turn_color_provider, 1)

func get_player_id_for_color(owner_color: int) -> int:
	if player_id_for_color_provider.is_valid():
		return int(player_id_for_color_provider.call(owner_color))
	return 0

func get_deck_visual(owner_color: int) -> StampVisual:
	if deck_visual_provider.is_valid():
		return deck_visual_provider.call(owner_color) as StampVisual
	return null

func is_stamp_hand_top(owner_color: int) -> bool:
	return owner_color != get_local_view_color()

func get_local_view_color() -> int:
	return get_int(local_view_color_provider, 1)

func get_own_color() -> int:
	return get_int(own_color_provider, 1)

func get_visible_viewport_size() -> Vector2:
	if visible_viewport_size_provider.is_valid():
		return visible_viewport_size_provider.call()
	if canvas_layer != null and is_instance_valid(canvas_layer):
		return canvas_layer.get_viewport().get_visible_rect().size
	return Vector2.ZERO

func get_board_screen_size() -> float:
	if board_screen_size_provider.is_valid():
		return float(board_screen_size_provider.call())
	return 0.0

func get_game_result_context() -> Dictionary:
	if game_result_context_provider.is_valid():
		return game_result_context_provider.call()
	return {}

func get_bool(provider: Callable, fallback: bool) -> bool:
	if provider.is_valid():
		return bool(provider.call())
	return fallback

func get_int(provider: Callable, fallback: int) -> int:
	if provider.is_valid():
		return int(provider.call())
	return fallback
