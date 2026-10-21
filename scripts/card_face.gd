class_name NichirinCardFace
extends Button
const DB := preload("res://scripts/card_database.gd")
const BODY := preload("res://assets/template/fonts/ui_medium.tres")
const DISPLAY := preload("res://assets/template/fonts/display/card_name.tres")
var data: Dictionary = {}
var full_art := false
var compact := false
var face_size := Vector2(200,292)
static var texture_cache := {}

func setup(card: Dictionary, artwork: bool, dimensions: Vector2, small: bool = false) -> void:
	data = card
	full_art = artwork
	compact = small
	face_size = dimensions
	custom_minimum_size = dimensions
	size = dimensions
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var border := DB.color_for(str(data.get("color","White")))
	if bool(data.get("surge",false)):
		border = Color("#e4bd72")
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#111c2b")
		style.border_color = border.lightened(0.2) if state == "hover" else border.darkened(0.3)
		style.set_border_width_all(2 if state == "normal" else 3)
		style.set_corner_radius_all(9)
		style.shadow_color = Color(0,0,0,0.4)
		style.shadow_size = 6
		add_theme_stylebox_override(state,style)
	var w := dimensions.x
	var h := dimensions.y
	var s := w/200.0
	var art_path: String = "res://assets/support/"+str(data.art)+".png" if data.kind == "Support" else "res://assets/fighters/"+str(data.art)+( "_full" if full_art and bool(data.get("alternate",false)) else "")+".png"
	var image := TextureRect.new()
	image.texture = texture(art_path)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.position = Vector2(4,4 if full_art else 48*s)
	image.size = Vector2(w-8,h-8 if full_art else h*0.48)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	var header := ColorRect.new()
	header.color = Color(0.025,0.045,0.075,0.85)
	header.position = Vector2(4,4)
	header.size = Vector2(w-8,44*s)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	var short_name: String = str(data.name).split(" ")[0]
	if short_name == "Kyojuro": short_name = "Rengoku"
	label_at(short_name+(" SURGE" if data.surge else ""),Vector2(10,7)*s,Vector2(155,22)*s,17*s,Color("#f5ead6"),DISPLAY)
	label_at(str(data.get("hp",0))+" HP" if data.kind != "Support" else "SUPPORT",Vector2(10,29)*s,Vector2(176,16)*s,10*s,border)
	var bottom := ColorRect.new()
	bottom.color = Color(0.025,0.045,0.075,0.9 if full_art else 1.0)
	bottom.position = Vector2(4,h*0.65)
	bottom.size = Vector2(w-8,h*0.35-4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	label_at(str(data.form).to_upper(),Vector2(10,h*0.66),Vector2(w-20,16*s),9*s,border)
	if data.kind == "Fighter":
		var attacks: Array = data.attacks
		for i in range(attacks.size()):
			var a: Dictionary = attacks[i]
			label_at(str(a.name),Vector2(10,h*0.73+i*22*s),Vector2(w-46,19*s),10.5*s,Color("#f7eedf"))
			label_at(str(a.damage),Vector2(w-38,h*0.73+i*22*s),Vector2(30,19)*s,12*s,Color("#e7c57c"))
	else:
		label_at(str(data.text),Vector2(10,h*0.73),Vector2(w-20,h*0.17),10*s,Color("#e7decf"),BODY,true)
	label_at("%03d  /  162" % int(data.number),Vector2(10,h-19*s),Vector2(w*0.52,16*s),8.5*s,Color("#93a1b6"))
	label_at(str(data.rarity).to_upper(),Vector2(w*0.52,h-19*s),Vector2(w*0.46,16*s),8.5*s,Color("#d5ba81"))

static func texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		texture_cache[path] = tex
		return tex
	return null

func label_at(value: String, pos: Vector2, dims: Vector2, font_size: float, tint: Color, font: Font = BODY, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = dims
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",maxi(8,int(font_size)))
	label.add_theme_color_override("font_color",tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = not wrap
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(label)
	return label
