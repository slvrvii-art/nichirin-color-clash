class_name NichirinCardFace
extends Button
const DB := preload("res://scripts/card_database.gd")
const BODY := preload("res://assets/template/fonts/ui_medium.tres")
const DISPLAY := preload("res://assets/template/fonts/display/card_name.tres")
const SURGE_FONT := preload("res://assets/fonts/Bungee-Regular.ttf")
const SURGE_SHADER := preload("res://assets/interface/surge_gold.gdshader")
var data: Dictionary = {}
var full_art := false
var compact := false
var face_size := Vector2(200,292)
static var texture_cache := {}

# SURGE cards always use full art; Normal fighters and utility cards use basic art.
func setup(card: Dictionary, _artwork: bool, dimensions: Vector2, small: bool = false) -> void:
	data = card
	full_art = bool(data.get("surge",false))
	compact = small
	face_size = dimensions
	custom_minimum_size = dimensions
	size = dimensions
	clip_contents = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var border := DB.color_for(str(data.get("color","White")))
	if full_art:
		border = Color("#e4bd72")
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#111c2b")
		style.border_color = border.lightened(0.2) if state == "hover" else border.darkened(0.3)
		style.set_border_width_all((3 if full_art else 2) if state == "normal" else 3)
		style.set_corner_radius_all(9)
		style.shadow_color = Color(0,0,0,0.4)
		style.shadow_size = 6
		add_theme_stylebox_override(state,style)
	var w := dimensions.x
	var h := dimensions.y
	var s := w/200.0
	var art_path: String = "res://assets/support/"+str(data.art)+".png" if data.kind in ["Support","Item"] else "res://assets/fighters/"+str(data.get("art_file",data.art))+".png"
	var art_texture := texture(art_path)
	if full_art:
		var image := TextureRect.new()
		image.texture = art_texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.position = Vector2(4,4)
		image.size = Vector2(w-8,h-8)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(image)
	else:
		# Basic art fits entirely inside its window: a dimmed fill behind, the whole picture in front.
		var window_pos := Vector2(4,48*s)
		var window_size := Vector2(w-8,h*0.65-48*s)
		var backdrop := TextureRect.new()
		backdrop.texture = art_texture
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.position = window_pos
		backdrop.size = window_size
		backdrop.modulate = Color(0.32,0.34,0.4)
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		var image := TextureRect.new()
		image.texture = art_texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.position = window_pos+Vector2(0,2*s)
		image.size = window_size-Vector2(0,4*s)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(image)
	var header := ColorRect.new()
	header.color = Color(0.025,0.045,0.075,0.62 if full_art else 0.85)
	header.position = Vector2(4,4)
	header.size = Vector2(w-8,44*s)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	var short_name: String = str(data.get("short",str(data.name).split(" ")[0]))
	var name_size: float = 17*s
	var name_width: float = DISPLAY.get_string_size(short_name,HORIZONTAL_ALIGNMENT_LEFT,-1,int(name_size)).x
	var max_width: float = w-20
	if name_width > max_width: name_size = maxf(9.0,name_size*max_width/name_width)
	label_at(short_name,Vector2(10,7)*s,Vector2(w-16,22*s),name_size,Color("#f5ead6"),DISPLAY)
	label_at(str(data.get("hp",0))+" HP" if data.kind == "Fighter" else str(data.kind).to_upper(),Vector2(10,29)*s,Vector2(w*0.5,16*s),10*s,border)
	if full_art:
		surge_label(Vector2(w*0.5,27*s),Vector2(w*0.5-10*s,18*s),12.5*s)
	var bottom := ColorRect.new()
	bottom.color = Color(0.025,0.045,0.075,0.78 if full_art else 1.0)
	bottom.position = Vector2(4,h*0.65)
	bottom.size = Vector2(w-8,h*0.35-4)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	var form_label: String = str(data.form).to_upper()
	if data.kind == "Fighter":
		if full_art: form_label = "BOOST" if str(data.get("boost_from",""))!="" else "STANDALONE"
		else: form_label = "NORMAL"
	if str(data.get("ability_id",""))!="": form_label += "  •  ABILITY"
	label_at(form_label,Vector2(10,h*0.66),Vector2(w-20-30*s,16*s),9*s,border)
	if data.kind == "Fighter":
		# Retreat cost pips (colorless Energy) at the right of the form row.
		var pips: int = int(data.get("retreat_cost",2 if full_art else 1))
		var pip_d: float = maxf(5.0,7*s)
		for i in range(pips):
			var pip := Panel.new()
			var ps := StyleBoxFlat.new()
			ps.bg_color = Color("#d9dde6")
			ps.border_color = Color("#3a4559")
			ps.set_border_width_all(1)
			ps.set_corner_radius_all(int(pip_d))
			pip.add_theme_stylebox_override("panel",ps)
			pip.position = Vector2(w-10-(pips-i)*(pip_d+3*s),h*0.66+4*s)
			pip.size = Vector2(pip_d,pip_d)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pip.tooltip_text = "Retreat cost"
			add_child(pip)
		var attacks: Array = data.attacks
		for i in range(attacks.size()):
			var a: Dictionary = attacks[i]
			var attack_label: String = str(a.name)
			if str(a.get("status",""))!="" and w>=150: attack_label += " · "+str(a.status).to_upper()
			label_at(attack_label,Vector2(10,h*0.73+i*22*s),Vector2(w-46,19*s),9.5*s,Color("#f7eedf"))
			label_at(str(a.damage),Vector2(w-38,h*0.73+i*22*s),Vector2(30,19)*s,12*s,Color("#e7c57c"))
	else:
		label_at(str(data.text),Vector2(10,h*0.73),Vector2(w-20,h*0.17),10*s,Color("#e7decf"),BODY,true)
	label_at("%03d  /  %d" % [int(data.number),DB.TOTAL_CARDS],Vector2(10,h-19*s),Vector2(w*0.52,16*s),8.5*s,Color("#93a1b6"))
	if full_art:
		surge_label(Vector2(w*0.52,h-21*s),Vector2(w*0.46-6*s,17*s),10*s)
	else:
		label_at(str(data.rarity).to_upper(),Vector2(w*0.52,h-19*s),Vector2(w*0.46,16*s),8.5*s,Color("#d5ba81"))

# The SURGE wordmark: Bungee lettering filled with a gold metallic gradient and a dark outline.
func surge_label(pos: Vector2, dims: Vector2, font_size: float) -> Label:
	var label := label_at("SURGE",pos,dims,font_size,Color.WHITE,SURGE_FONT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color",Color("#2a1806"))
	label.add_theme_constant_override("outline_size",maxi(2,int(font_size*0.22)))
	var material := ShaderMaterial.new()
	material.shader = SURGE_SHADER
	material.set_shader_parameter("height",dims.y)
	label.material = material
	label.name = "SurgeWordmark"
	return label

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
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",maxi(8,int(font_size)))
	label.add_theme_color_override("font_color",tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = not wrap
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if wrap: label.custom_minimum_size = Vector2(dims.x,0)
	add_child(label)
	label.size = dims
	return label
