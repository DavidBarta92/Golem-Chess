extends "res://Scripts/TopBar/QuestRibbon.gd"

## A notice rather than a quest: a buyer has picked from one of the player's
## lots on the Bourse (BourseStore), and the price waits to be collected.
## Drawn by the ribbon rules of Docs/TopBar/design: the cut tells the type - a
## notice's foot is rounded (TopBarStyle.TAIL_DEPTH["sale"]) - and the colour
## and the icon the reward, coins, as on any gold ribbon. The stitching runs
## solid all the way down: all of it is done. Like a done quest it sways until
## it is collected, but it does not hang lower, so its foot stays level with
## the other ribbons'.

var lot_id: String = ""

func _init() -> void:
	kind = "sale"
	reward = "coin"
	show_seam = true
	progress_ratio = 1.0

## Takes a sold lot from BourseStore; item_id is the top bar's id for it.
func configure_sale(lot: Dictionary, item_id: String) -> void:
	quest_id = item_id
	lot_id = str(lot.get("lot_id", ""))
	queue_redraw()
	_refresh_length()
	_refresh_sway()

func _waits_to_be_claimed() -> bool:
	return true
