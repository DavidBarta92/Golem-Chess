extends Node

@onready var role_label = $"."

func _ready():
	if GameConfig.is_hosting:
		role_label.text = "HOST"
	else:
		role_label.text = "CLIENT"
