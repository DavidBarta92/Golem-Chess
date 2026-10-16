@tool
extends Resource
class_name ComicDialogueLine

## One dialogue box on a comic panel.
##
## A panel can carry several in a row - two characters trading a line about
## the same drawing - and the page steps through them on the Continue button
## before moving on to the next panel.

## Who is speaking. A translation key unless `localize` is off.
@export var speaker: String = ""
## What they say. A translation key unless `localize` is off.
@export var text: String = ""
## Off treats both fields as literal text, which is handy while drafting.
@export var localize: bool = true

## Pulls the name and the text closer together for this one line. The default
## spacing suits a wide box; a line squeezed between two drawings often needs
## the tighter one. Negative leaves the panel's own spacing alone.
@export_range(-1.0, 40.0, 1.0) var speaker_gap: float = -1.0

func get_speaker() -> String:
	var value: String = speaker.strip_edges()
	if value.is_empty():
		return ""
	return tr(value) if localize else value

func get_text() -> String:
	var value: String = text.strip_edges()
	if value.is_empty():
		return ""
	return tr(value) if localize else value

func is_empty() -> bool:
	return text.strip_edges().is_empty()
