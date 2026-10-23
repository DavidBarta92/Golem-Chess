extends VBoxContainer
class_name DeckChoicePanel

## The codex choice a single-player match opens on: the player's playable
## codexes in a list, a Start button and a countdown. Start, or the countdown
## running out, settles it - on whatever the list shows, which is the codex
## already selected unless the player picked another.
##
## It sits on the empty table where the board is about to be drawn. All it does
## is settle the choice; what happens next is up to whoever put it there
## (MatchIntroController).

signal chosen(deck_id: String)

const COUNTDOWN_SECONDS: float = 20.0
const TITLE_FONT_SIZE: int = 22
const COUNTDOWN_FONT_SIZE: int = 32
const ROW_SEPARATION: int = 10
const COLUMN_SEPARATION: int = 14
const LIST_MIN_WIDTH: float = 240.0

var _deck_ids: Array[String] = []
var _list: OptionButton
var _start: Button
var _countdown: Label
var _remaining: float = COUNTDOWN_SECONDS
var _settled: bool = false

## Whether there is anything to choose between: two or more codexes that can
## be played. With one the match simply uses it.
static func has_choice() -> bool:
	return PlayerDeckStore.list_playable_decks().size() >= 2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", COLUMN_SEPARATION)
	_build()
	_fill_list()
	_show_remaining()
	set_process(false)

## Starts the countdown.
func begin() -> void:
	if !_settled:
		set_process(true)

func _process(delta: float) -> void:
	_remaining = maxf(_remaining - delta, 0.0)
	_show_remaining()
	if _remaining <= 0.0:
		_settle()

func _build() -> void:
	var title := Label.new()
	title.text = tr("MATCH_DECK_CHOICE_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	add_child(title)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", ROW_SEPARATION)
	add_child(row)

	_list = OptionButton.new()
	_list.custom_minimum_size.x = LIST_MIN_WIDTH
	_list.focus_mode = Control.FOCUS_NONE
	row.add_child(_list)

	_start = Button.new()
	_start.text = tr("MATCH_DECK_CHOICE_START")
	_start.focus_mode = Control.FOCUS_NONE
	_start.pressed.connect(_settle)
	row.add_child(_start)

	_countdown = Label.new()
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.add_theme_font_size_override("font_size", COUNTDOWN_FONT_SIZE)
	add_child(_countdown)

func _fill_list() -> void:
	var current_deck_id: String = GameConfig.get_selected_deck_id()
	var selected_index: int = 0
	for deck in PlayerDeckStore.list_playable_decks():
		if !(deck is Dictionary):
			continue
		_deck_ids.append(str(deck.get("deck_id", "")))
		_list.add_item(str(deck.get("name", tr("Unnamed codex"))))
		if _deck_ids[-1] == current_deck_id:
			selected_index = _deck_ids.size() - 1
	if !_deck_ids.is_empty():
		_list.select(selected_index)

func _show_remaining() -> void:
	_countdown.text = str(ceili(_remaining))

func _settle() -> void:
	if _settled:
		return
	_settled = true
	set_process(false)
	_list.disabled = true
	_start.disabled = true
	var index: int = _list.selected
	var deck_id: String = _deck_ids[index] if index >= 0 and index < _deck_ids.size() else GameConfig.get_selected_deck_id()
	chosen.emit(deck_id)
