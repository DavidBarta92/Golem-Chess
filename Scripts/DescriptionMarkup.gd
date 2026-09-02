extends RefCounted
class_name DescriptionMarkup

static func to_bbcode(raw_text: String, icon_size: int = 16) -> String:
	var bbcode_text: String = raw_text
	bbcode_text = bbcode_text.replace("<b>", "[b]").replace("</b>", "[/b]")
	bbcode_text = bbcode_text.replace("<i>", "[i]").replace("</i>", "[/i]")
	return _replace_icon_tags(bbcode_text, icon_size)

static func _replace_icon_tags(text: String, icon_size: int) -> String:
	var result: String = text
	var icon_height: int = maxi(icon_size, 1)
	for effect_type: String in StampEffect.EFFECT_ICON_STANDALONE_TEXTURES.keys():
		var open_tag: String = "<%s>" % effect_type
		if !result.contains(open_tag):
			continue
		var icon_texture: Texture2D = StampEffect.EFFECT_ICON_STANDALONE_TEXTURES[effect_type]
		var icon_path: String = icon_texture.resource_path
		if icon_path.is_empty():
			continue
		var icon_texture_size: Vector2 = icon_texture.get_size()
		var aspect_ratio: float = icon_texture_size.x / icon_texture_size.y if icon_texture_size.y > 0.0 else 1.0
		var icon_width: int = maxi(int(round(icon_height * aspect_ratio)), 1)
		result = result.replace(open_tag, "[img=%dx%d]%s[/img]" % [icon_width, icon_height, icon_path])
	return result
