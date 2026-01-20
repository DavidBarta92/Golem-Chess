# card.gd
extends Resource
class_name Card

@export var card_name: String = "New Card"
@export var card_code: String = "New Card"
@export var duration: int = 2
@export var texture: Texture2D
@export var description: String = ""
@export var is_owned: bool = true
@export var movement_pattern: Array[Array] = [
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0]
]

func get_directions() -> Array:
	var directions := []
	var rows := movement_pattern.size()
	if rows == 0:
		return directions

	var cols: int = movement_pattern[0].size()
	var center_x := int(rows / 2)
	var center_y := int(cols / 2)

	for x in range(rows):
		for y in range(cols):
			if x == center_x and y == center_y:
				continue
			if movement_pattern[x][y] == 1:
				var offset := Vector2(center_x - x, y - center_y)
				directions.append(offset)

	return directions
