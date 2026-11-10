extends Resource
class_name PuzzleDefinition

## One puzzle: the letter it arrives in, what solving it pays, and the board
## it is played on. Save one per puzzle under res://Puzzles/; the Puzzles
## screen lists every enabled one it finds there (PuzzleLibrary).
## Docs/Puzzles/PUZZLES.md walks through making one.
##
## Every text field goes through the language files: write a key from
## Localization/translations.csv, or plain text, which shows as it is.

## Who writes it. Decides the envelope - British for Edmund, Hungarian for
## Grandpa, Czech for Jakub, American for Darnell - and the name under it.
enum Sender { GRANDPA, EDMUND, JAKUB, DARNELL }
## What solving it pays, which also decides the mark in the envelope's
## corner: the stamp itself, a postmark for coins, a wax seal for draw points.
enum RewardKind { STAMP, COINS, DRAW_POINTS }
enum EnvelopeStyle { BRITISH, HUNGARIAN, CZECH, AMERICAN }

const SENDER_STYLE: Dictionary = {
	Sender.GRANDPA: EnvelopeStyle.HUNGARIAN,
	Sender.EDMUND: EnvelopeStyle.BRITISH,
	Sender.JAKUB: EnvelopeStyle.CZECH,
	Sender.DARNELL: EnvelopeStyle.AMERICAN,
}
## The name under the envelope. Grandpa's is his boss name, translated; the
## others are names.
const SENDER_NAME: Dictionary = {
	Sender.GRANDPA: "BOSS_NAME_GRANDPA",
	Sender.EDMUND: "Edmund Whitmore",
	Sender.JAKUB: "Jakub Goldstein",
	Sender.DARNELL: "Darnell Brooks",
}
## How a letter of theirs is signed when `signature` is left empty.
const SENDER_SIGNATURE: Dictionary = {
	Sender.GRANDPA: "BOSS_NAME_GRANDPA",
	Sender.EDMUND: "Edmund",
	Sender.JAKUB: "Jakub",
	Sender.DARNELL: "Darnell",
}

## Unique among the puzzles; the save remembers progress under it. Never
## change it once the puzzle has shipped.
@export var puzzle_id: String = ""
## Where it sits on the Puzzles screen: lower first.
@export var order: int = 0
## Off leaves it out of the screen.
@export var enabled: bool = true

@export_group("Letter")
@export var sender: Sender = Sender.GRANDPA
## "Kedves Anna,"
@export var greeting: String = ""
## The letter itself. An empty line starts a new paragraph.
@export_multiline var body: String = ""
## "Szívélyes üdvözlettel,"
@export var closing: String = ""
## The handwritten name at the bottom. Empty: the sender's usual one.
@export var signature: String = ""
## The task in one line, under FELADVÁNY on the letter and on the board:
## "Nyerj két lépésből."
@export var task: String = ""

@export_group("Reward")
@export var reward_kind: RewardKind = RewardKind.COINS
## Coins or draw points; for a stamp, how many copies.
@export_range(1, 1000) var reward_amount: int = 10
## The stamp it pays, for RewardKind.STAMP. It is also what the envelope
## carries in its corner.
@export var reward_stamp: Stamp
## A particular print of it (a foil, a full art) instead of the standard one.
@export var reward_print: StampPrint

@export_group("Board")
## Every golem on the board. A square nobody is put on stays empty.
@export var pieces: Array[PuzzlePiece] = []
## The player's codex, page after page, three stamps to a page; the first
## page is the open one. Leave an entry empty for an empty slot.
@export var player_codex: Array[Stamp] = []
## The opponent's, the same way. Scripted turns can only affix stamps from
## its open page.
@export var opponent_codex: Array[Stamp] = []
## Where each crown meter stands. Full (GameConfig.crown_points_required)
## lets the player crown a golem on the first turn.
@export_range(0, 6) var player_crown_points: int = 0
@export_range(0, 6) var opponent_crown_points: int = 0

@export_group("Goal")
## All of them have to hold at once.
@export var goals: Array[PuzzleGoal] = []
## The player's turns to do it in. Each ends with a move, or with End Turn
## when no move is possible.
@export_range(1, 20) var turn_limit: int = 2

@export_group("Opponent")
## Before each scripted turn, the opponent wins if it can, or else captures a
## golem of the player's if it can - a crowned one first. Off: it only ever
## does what its script says.
@export var opponent_takes_chances: bool = true
## Its turns, in order. Once they run out it passes.
@export var opponent_turns: Array[PuzzleOpponentTurn] = []

func get_envelope_style() -> EnvelopeStyle:
	return SENDER_STYLE.get(sender, EnvelopeStyle.HUNGARIAN)

func get_sender_name() -> String:
	return TranslationServer.translate(str(SENDER_NAME.get(sender, "")))

func get_signature() -> String:
	var text: String = signature.strip_edges()
	if text.is_empty():
		text = str(SENDER_SIGNATURE.get(sender, ""))
	return TranslationServer.translate(text)

## The letter's paragraphs, translated, without the empty lines between them.
func get_body_paragraphs() -> Array[String]:
	var paragraphs: Array[String] = []
	var text: String = TranslationServer.translate(body).replace("\r\n", "\n")
	for paragraph in text.split("\n\n"):
		var cleaned: String = paragraph.strip_edges()
		if !cleaned.is_empty():
			paragraphs.append(cleaned)
	return paragraphs

## The stamp the reward is about, if it is one.
func get_reward_stamp() -> Stamp:
	if reward_kind != RewardKind.STAMP:
		return null
	if reward_stamp != null:
		return reward_stamp
	if reward_print != null:
		return StampPrintLibrary.get_stamp_for_print(reward_print)
	return null

## The print the reward pays out: the chosen one, or the stamp's standard.
func get_reward_print_id() -> String:
	if reward_print != null and !reward_print.print_id.is_empty():
		return reward_print.print_id
	var stamp: Stamp = get_reward_stamp()
	if stamp == null:
		return ""
	return StampPrintLibrary.get_default_print_id_for_stamp_code(stamp.stamp_code)

## The player's codex, page by page, as stamp names.
func get_player_pages() -> Array:
	return _pages_from(player_codex)

func get_opponent_pages() -> Array:
	return _pages_from(opponent_codex)

func _pages_from(stamps: Array[Stamp]) -> Array:
	var pages: Array = []
	for page_index in range(DeckManager.CODEX_PAGE_COUNT):
		var page: Array[String] = []
		for slot in range(DeckManager.CODEX_STAMPS_PER_PAGE):
			var index: int = page_index * DeckManager.CODEX_STAMPS_PER_PAGE + slot
			if index < stamps.size() and stamps[index] != null:
				page.append(stamps[index].stamp_name)
		pages.append(page)
	return pages

## What is wrong with it, for the editor and for the log; empty when it can
## be played.
func get_problems() -> Array[String]:
	var problems: Array[String] = []
	if puzzle_id.strip_edges().is_empty():
		problems.append("puzzle_id is empty")
	var taken: Dictionary = {}
	var crowns: Dictionary = {}
	for piece in pieces:
		if piece == null:
			continue
		if !PuzzleSquares.is_valid(piece.square):
			problems.append("piece on '%s': not a square" % piece.square)
			continue
		if taken.has(piece.square):
			problems.append("two pieces on %s" % piece.square)
		taken[piece.square] = true
		if piece.crowned:
			crowns[piece.side] = int(crowns.get(piece.side, 0)) + 1
	for side in crowns:
		if int(crowns[side]) > 1:
			problems.append("more than one crowned golem on one side")
	if goals.is_empty():
		problems.append("no goals")
	for goal in goals:
		if goal == null:
			continue
		if goal.kind in [PuzzleGoal.Kind.CAPTURE_PIECE, PuzzleGoal.Kind.REACH_SQUARE] and !PuzzleSquares.is_valid(goal.target_square):
			problems.append("%s: target_square '%s' is not a square" % [goal.resource_name, goal.target_square])
		if !goal.piece_square.is_empty() and !taken.has(goal.piece_square):
			problems.append("%s: no golem starts on %s" % [goal.resource_name, goal.piece_square])
	if reward_kind == RewardKind.STAMP and get_reward_stamp() == null:
		problems.append("reward is a stamp, but none is set")
	return problems
