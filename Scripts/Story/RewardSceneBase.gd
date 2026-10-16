extends Control
class_name RewardSceneBase

## Shared skeleton for the "you unlocked something" beat after a boss fight.
##
## Every reward is its own scene - make an inherited scene of
## Scenes/Reward/RewardScene.tscn under Scenes/Reward/ and build whatever that
## particular reward needs into RightColumn. This base only handles the parts
## that are the same every time:
##
##   * the left column: a preset image with a character talking underneath it
##   * paying the reward out exactly once, no matter how often the scene is
##     re-entered (a crash, an alt-f4, a retried fight)
##   * unlocking menu features, which is what makes the FeatureHint arrows in
##     the main menu appear
##   * completing the story node when the player clicks past the last line

const DEFAULT_SPEAKER_NAME: String = "Mentor"

@export_group("Identity")
## Guards the payout. Must be unique and must never change once a build has
## shipped, or players will be paid twice.
@export var reward_id: String = ""

@export_group("Presentation")
## The big preset image at the top of the left column.
@export var reward_image: Texture2D
## Who is explaining this. Plain text or a translation key.
@export var speaker_name: String = DEFAULT_SPEAKER_NAME
## Leave empty to use the tutorial mentor's face.
@export var speaker_portrait: PortraitConfig
## One dialogue box per entry. Passed through tr(), so these can be keys.
@export var dialogue_lines: Array[String] = []

@export_group("Payout")
## Menu features unlocked by this reward, e.g. StoryFeatures.COLLECTION.
@export var unlocks_features: Array[String] = []
@export var grant_points: int = 0
## One entry per pack handed out; repeat an id to give several.
@export var grant_pack_ids: Array[String] = []
@export var grant_stamps: Array[Stamp] = []
## Played once when the payout actually happens (not on a re-entry).
@export var sfx_on_reward: String = ""

## Left column, top: the preset image for this reward.
@onready var reward_image_rect: TextureRect = $RewardImage
## Left column, bottom: the character explaining what just happened.
@onready var dialogue_panel: DialoguePanel = $DialoguePanel
## Right half of the screen - empty on purpose. Concrete reward scenes build
## their own visuals in here (the stamp that was won, a coin counter, the
## menu button that just appeared).
@onready var right_column: Control = $RightColumn

## Everything to be said on this screen, in order: the beaten boss gets the
## first word when they had one, then the reward's own speaker. Each entry is
## { speaker, text, portrait }.
var _queued_lines: Array[Dictionary] = []
var _line_index: int = -1
var _is_finishing: bool = false
var _granted_now: bool = false
## The animated centrepiece in RightColumn, if the scene has one. The scene
## leaves only when both the dialogue and the presentation are done.
var _presenter: RewardPresenter
var _dialogue_done: bool = false
var _presentation_done: bool = true

func _ready() -> void:
	if reward_image_rect != null:
		reward_image_rect.texture = reward_image
		reward_image_rect.visible = reward_image != null

	_granted_now = _grant_rewards()
	_apply_feature_unlocks()
	_on_reward_ready(_granted_now)
	_start_presenter()

	_build_line_queue()
	if dialogue_panel != null and !dialogue_panel.continue_requested.is_connected(_on_continue_requested):
		dialogue_panel.continue_requested.connect(_on_continue_requested)
	_show_next_line()

## Hook for concrete reward scenes: build the right-hand visuals here.
## The argument is false when the player has seen this reward before, which is
## the moment to skip a celebratory animation and just show the end state.
func _on_reward_ready(_granted_now: bool) -> void:
	pass

## The cards a CardFlipPresenter deals out. Defaults to the payout; a scene
## that hands over something it does not grant through grant_stamps (the
## Grandpa deck) overrides this.
func get_presented_stamps() -> Array[Stamp]:
	var stamps: Array[Stamp] = []
	for stamp in grant_stamps:
		if stamp != null:
			stamps.append(stamp)
	return stamps

## Hook for concrete reward scenes that need to run something before the story
## moves on. Called once both the dialogue and the presentation are done. Call
## finish_reward() yourself if you override and do not call super.
func _on_reward_finished() -> void:
	finish_reward()

func _start_presenter() -> void:
	_presenter = _find_presenter(right_column)
	if _presenter == null:
		return
	_presentation_done = false
	_presenter.presentation_finished.connect(_on_presentation_finished)
	_presenter.begin(self, _granted_now)

func _find_presenter(root: Node) -> RewardPresenter:
	if root == null:
		return null
	for child in root.get_children():
		if child is RewardPresenter:
			return child
		var nested: RewardPresenter = _find_presenter(child)
		if nested != null:
			return nested
	return null

func _on_presentation_finished() -> void:
	_presentation_done = true
	_try_finish()

func _try_finish() -> void:
	if _dialogue_done and _presentation_done:
		_on_reward_finished()

func finish_reward() -> void:
	if _is_finishing:
		return
	_is_finishing = true
	StoryManager.finish_current_node()

func _on_continue_requested() -> void:
	if dialogue_panel != null and dialogue_panel.is_typing:
		dialogue_panel.finish_line()
		return
	_show_next_line()

func _show_next_line() -> void:
	_line_index += 1
	if dialogue_panel == null or _line_index >= _queued_lines.size():
		_dialogue_done = true
		if !_presentation_done and dialogue_panel != null:
			# Nothing more to say, but the centrepiece is still playing: keep
			# the last line up and stop offering Continue until it is done.
			dialogue_panel.set_interactive(false)
		_try_finish()
		return

	var line: Dictionary = _queued_lines[_line_index]
	dialogue_panel.show_line(
		str(line.get("speaker", "")),
		str(line.get("text", "")),
		line.get("portrait", null)
	)

## The boss line comes in already localized (the boss decides whether its text
## goes through the language files), so it is not translated a second time.
func _build_line_queue() -> void:
	_queued_lines.clear()

	var boss_line: Dictionary = StoryManager.consume_pending_boss_line()
	if !boss_line.is_empty():
		_queued_lines.append({
			"speaker": str(boss_line.get("speaker_name", "")),
			"text": str(boss_line.get("text", "")),
			"portrait": PortraitLibrary.config_from_data_or_default(boss_line.get("portrait_data", {}), 1),
		})

	var speaker: String = tr(speaker_name)
	var portrait: PortraitConfig = _get_speaker_portrait()
	for line_text in dialogue_lines:
		var cleaned_text: String = str(line_text).strip_edges()
		if cleaned_text.is_empty():
			continue
		_queued_lines.append({
			"speaker": speaker,
			"text": tr(cleaned_text),
			"portrait": portrait,
		})

func _get_speaker_portrait() -> PortraitConfig:
	if speaker_portrait != null:
		return speaker_portrait
	return PortraitLibrary.get_tutorial_portrait()

## Returns true when this call is what actually paid the reward out.
func _grant_rewards() -> bool:
	var guard_id: String = reward_id.strip_edges()
	if guard_id.is_empty():
		push_error("RewardScene '%s' has no reward_id; refusing to pay out an unguarded reward." % scene_file_path)
		return false
	if !StoryProgressStore.mark_reward_granted(guard_id):
		return false

	if grant_points > 0:
		PlayerProgressStore.add_points(grant_points)
	for pack_id in grant_pack_ids:
		var cleaned_pack_id: String = str(pack_id).strip_edges()
		if !cleaned_pack_id.is_empty():
			PlayerProgressStore.add_unopened_packs(1, cleaned_pack_id)
	for stamp in grant_stamps:
		if stamp != null:
			PlayerCollectionStore.add_local_stamp_copy(stamp.stamp_name)

	if !sfx_on_reward.strip_edges().is_empty():
		SFXManager.play(sfx_on_reward.strip_edges())
	return true

## Unlocks run every time rather than behind the payout guard: a feature must
## end up unlocked even if the payout was already recorded on an earlier run.
func _apply_feature_unlocks() -> void:
	for feature_id in unlocks_features:
		var cleaned_feature_id: String = str(feature_id).strip_edges()
		if !cleaned_feature_id.is_empty():
			StoryProgressStore.unlock_feature(cleaned_feature_id)
