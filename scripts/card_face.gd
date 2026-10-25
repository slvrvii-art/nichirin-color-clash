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
static var texture_cache: Dictionary = {}
static var _texture_lru: Array[String] = []
static var _pending_textures: Dictionary = {}
static var _texture_waiters: Dictionary = {}
static var _failed_textures: Dictionary = {}
static var _ui_node_pools: Dictionary = {}
static var _ui_node_pool_ids: Dictionary = {}
static var _pooled_ui_node_ids: Dictionary = {}
static var _pooled_ui_node_count := 0
static var _reported_stale_pool_kinds: Dictionary = {}
const MAX_CACHED_TEXTURES := 24
const MAX_POOLED_UI_NODES := 512

static func acquire_ui_node(kind: String, script_resource: Script = null) -> Control:
	var node: Control
	var pool: Array = _ui_node_pools.get(kind, [])
	var pool_ids: Array = _ui_node_pool_ids.get(kind, [])
	while not pool.is_empty():
		var instance_id: int = int(pool_ids.pop_back()) if not pool_ids.is_empty() else -1
		var pooled_value: Variant = pool.pop_back()
		_pooled_ui_node_count = maxi(0, _pooled_ui_node_count - 1)
		if instance_id >= 0:
			_pooled_ui_node_ids.erase(instance_id)
		if not is_instance_valid(pooled_value):
			if not _reported_stale_pool_kinds.has(kind):
				push_warning("Discarding stale freed UI node %d from the %s pool." % [instance_id,kind])
				_reported_stale_pool_kinds[kind] = true
			continue
		var pooled_node := pooled_value as Control
		if pooled_node == null or pooled_node.get_parent() != null:
			if not _reported_stale_pool_kinds.has(kind):
				push_warning("Discarding an attached or invalid UI node from the %s pool." % kind)
				_reported_stale_pool_kinds[kind] = true
			continue
		node = pooled_node
		break
	_ui_node_pools[kind] = pool
	_ui_node_pool_ids[kind] = pool_ids
	if node == null:
		match kind:
			"Control": node = Control.new()
			"ColorRect": node = ColorRect.new()
			"LineEdit": node = LineEdit.new()
			"ScrollContainer": node = ScrollContainer.new()
			"VBoxContainer": node = VBoxContainer.new()
			"Button": node = Button.new()
			"Panel": node = Panel.new()
			"Label": node = Label.new()
			"TextureRect": node = TextureRect.new()
			"OptionButton": node = OptionButton.new()
			"CardFace":
				if script_resource == null:
					push_error("CardFace pool requires its script resource.")
					return null
				node = script_resource.new() as Control
			_:
				push_error("Unsupported pooled UI node type: %s" % kind)
				return null
	_reset_control(node)
	return node

static func recycle_children(parent: Control) -> void:
	while parent.get_child_count() > 0:
		var child := parent.get_child(0)
		parent.remove_child(child)
		if child is Control:
			recycle_tree(child as Control)
		else:
			child.queue_free()

static func recycle_tree(control: Control) -> void:
	if control.get_parent() != null:
		control.get_parent().remove_child(control)
	recycle_children(control)
	_reset_control(control)
	var kind := _pool_kind(control)
	var instance_id: int = control.get_instance_id()
	if _pooled_ui_node_ids.has(instance_id):
		var duplicate_key := "duplicate:%s" % kind
		if not _reported_stale_pool_kinds.has(duplicate_key):
			push_warning("Ignoring duplicate recycle of UI node %d in the %s pool." % [instance_id,kind])
			_reported_stale_pool_kinds[duplicate_key] = true
		return
	if _pooled_ui_node_count >= MAX_POOLED_UI_NODES:
		control.free()
		return
	var pool: Array = _ui_node_pools.get(kind, [])
	var pool_ids: Array = _ui_node_pool_ids.get(kind, [])
	pool.append(control)
	pool_ids.append(instance_id)
	_ui_node_pools[kind] = pool
	_ui_node_pool_ids[kind] = pool_ids
	_pooled_ui_node_ids[instance_id] = kind
	_pooled_ui_node_count += 1

static func clear_runtime_caches() -> void:
	for pool_value in _ui_node_pools.values():
		for pooled_value in pool_value:
			var pooled_node := pooled_value as Control
			if is_instance_valid(pooled_node) and pooled_node.get_parent() == null:
				pooled_node.free()
	_ui_node_pools.clear()
	_ui_node_pool_ids.clear()
	_pooled_ui_node_ids.clear()
	_pooled_ui_node_count = 0
	_reported_stale_pool_kinds.clear()
	texture_cache.clear()
	_texture_lru.clear()
	_pending_textures.clear()
	_texture_waiters.clear()
	_failed_textures.clear()

static func _pool_kind(control: Control) -> String:
	var script_resource := control.get_script() as Script
	if script_resource != null and script_resource.resource_path == "res://scripts/card_face.gd":
		return "CardFace"
	return control.get_class()

static func _reset_control(control: Control) -> void:
	if control is LineEdit:
		_disconnect_signal(control, &"text_changed")
		_disconnect_signal(control, &"text_submitted")
	elif control is OptionButton:
		_disconnect_signal(control, &"item_selected")
	elif control is Button:
		_disconnect_signal(control, &"pressed")
	control.position = Vector2.ZERO
	control.size = Vector2.ZERO
	control.custom_minimum_size = Vector2.ZERO
	control.pivot_offset = Vector2.ZERO
	control.scale = Vector2.ONE
	control.rotation = 0.0
	control.modulate = Color.WHITE
	control.self_modulate = Color.WHITE
	control.visible = true
	control.z_index = 0
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.mouse_default_cursor_shape = Control.CURSOR_ARROW
	control.focus_mode = Control.FOCUS_NONE
	control.clip_contents = control is ScrollContainer
	control.tooltip_text = ""
	control.material = null
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	for style_name in ["normal", "hover", "pressed", "disabled", "focus", "panel"]:
		control.remove_theme_stylebox_override(style_name)
	for color_name in ["font_color", "font_disabled_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_outline_color", "font_shadow_color"]:
		control.remove_theme_color_override(color_name)
	control.remove_theme_font_override("font")
	control.remove_theme_font_size_override("font_size")
	for constant_name in ["outline_size", "shadow_offset_x", "shadow_offset_y", "separation"]:
		control.remove_theme_constant_override(constant_name)
	if control is OptionButton:
		var option := control as OptionButton
		option.clear()
		option.select(-1)
	elif control is Button:
		var button := control as Button
		button.text = ""
		button.disabled = false
		button.toggle_mode = false
		button.set_pressed_no_signal(false)
	elif control is Label:
		var label := control as Label
		label.text = ""
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = false
	elif control is TextureRect:
		(control as TextureRect).texture = null
	elif control is LineEdit:
		var line_edit := control as LineEdit
		line_edit.clear()
		line_edit.placeholder_text = ""
		line_edit.editable = true
	elif control is ScrollContainer:
		var scroll := control as ScrollContainer
		scroll.scroll_horizontal = 0
		scroll.scroll_vertical = 0
	if control.has_meta("nichirin_texture_path"):
		control.remove_meta("nichirin_texture_path")
	if script_resource_is_card_face(control):
		control.set("data", {})
		control.set("full_art", false)
		control.set("compact", false)
		control.set("face_size", Vector2.ZERO)

static func _disconnect_signal(control: Control, signal_name: StringName) -> void:
	for connection in control.get_signal_connection_list(signal_name):
		var callback: Callable = connection.get("callable", Callable())
		if control.is_connected(signal_name, callback):
			control.disconnect(signal_name, callback)

static func script_resource_is_card_face(control: Control) -> bool:
	var script_resource := control.get_script() as Script
	return script_resource != null and script_resource.resource_path == "res://scripts/card_face.gd"

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
	if full_art:
		var image := acquire_ui_node("TextureRect") as TextureRect
		image.texture = texture(art_path,image)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.position = Vector2(3,3)
		image.size = Vector2(w-6,h-6)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(image)
	else:
		# Basic art fits entirely inside its window: a dimmed fill behind, the whole picture in front.
		var window_pos := Vector2(4,48*s)
		var window_size := Vector2(w-8,h*0.65-48*s)
		var backdrop := acquire_ui_node("TextureRect") as TextureRect
		backdrop.texture = texture(art_path,backdrop)
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.position = window_pos
		backdrop.size = window_size
		backdrop.modulate = Color(0.32,0.34,0.4)
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(backdrop)
		var image := acquire_ui_node("TextureRect") as TextureRect
		image.texture = texture(art_path,image)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.position = window_pos+Vector2(0,2*s)
		image.size = window_size-Vector2(0,4*s)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(image)
	# Full-art SURGE cards have no dark bands; their text carries an outline instead.
	if not full_art:
		var header := acquire_ui_node("ColorRect") as ColorRect
		header.color = Color(0.025,0.045,0.075,0.85)
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
	if not full_art:
		var bottom := acquire_ui_node("ColorRect") as ColorRect
		bottom.color = Color(0.025,0.045,0.075,1.0)
		bottom.position = Vector2(4,h*0.65)
		bottom.size = Vector2(w-8,h*0.35-4)
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bottom)
	var form_label: String = str(data.form).to_upper()
	if data.kind == "Fighter":
		if full_art: form_label = "BOOST" if str(data.get("boost_from",""))!="" else "STANDALONE"
		else: form_label = "NORMAL"
	label_at(form_label,Vector2(10,h*0.66),Vector2(w-20-30*s,16*s),9*s,border)
	if data.kind == "Fighter":
		# Retreat cost pips (colorless Energy) at the right of the form row.
		var pips: int = int(data.get("retreat_cost",2 if full_art else 1))
		var pip_d: float = maxf(5.0,7*s)
		for i in range(pips):
			var pip := acquire_ui_node("Panel") as Panel
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
		var attack_top: float = h*0.73
		if str(data.get("ability_id",""))!="":
			# Ability name row, shown on every card that has one.
			label_at("ABILITY  "+str(data.get("ability_name","")).to_upper(),Vector2(10,h*0.715),Vector2(w-20,15*s),8.5*s,Color("#f0c76a"),BODY)
			attack_top = h*0.715+16*s
		var row: float = 22*s if attacks.size()<2 or attack_top<=h*0.73 else 19*s
		for i in range(attacks.size()):
			var a: Dictionary = attacks[i]
			var attack_label: String = str(a.name)
			if str(a.get("status",""))!="" and w>=150: attack_label += " · "+str(a.status).to_upper()
			label_at(attack_label,Vector2(10,attack_top+i*row),Vector2(w-46,19*s),9.5*s,Color("#f7eedf"))
			label_at(str(a.damage),Vector2(w-38,attack_top+i*row),Vector2(30,19)*s,12*s,Color("#e7c57c"))
	else:
		# Large cards wrap the full effect; small hand/board cards show one line with an ellipsis.
		var effect_label := label_at(str(data.text),Vector2(10,h*0.73),Vector2(w-20,h*0.17 if w>=150 else 14*s),10*s,Color("#e7decf"),BODY,w>=150)
		if w < 150: effect_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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

static func texture(path: String, target: TextureRect = null) -> Texture2D:
	if path.is_empty():
		return null
	if target != null:
		target.set_meta("nichirin_texture_path",path)
	if texture_cache.has(path):
		_touch_texture(path)
		var cached := texture_cache[path] as Texture2D
		if target != null:
			target.texture = cached
		return cached
	if _failed_textures.has(path):
		return null
	if not ResourceLoader.exists(path):
		_failed_textures[path] = true
		push_warning("Card artwork is missing: %s" % path)
		return null
	if not _pending_textures.has(path):
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded := ResourceLoader.load_threaded_get(path) as Texture2D
			if loaded != null:
				_cache_texture(path,loaded)
				if target != null:
					target.texture = loaded
				return loaded
			_failed_textures[path] = true
			return null
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var request_error := ResourceLoader.load_threaded_request(path)
			if request_error != OK:
				status = ResourceLoader.load_threaded_get_status(path)
				if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS and status != ResourceLoader.THREAD_LOAD_LOADED:
					_failed_textures[path] = true
					push_warning("Could not start threaded card-art loading for %s (error %d)." % [path,request_error])
					return null
		_pending_textures[path] = true
	if target != null:
		var waiters: Dictionary = _texture_waiters.get(path,{})
		waiters[target.get_instance_id()] = weakref(target)
		_texture_waiters[path] = waiters
	return null

static func has_pending_textures() -> bool:
	return not _pending_textures.is_empty()

static func poll_pending_textures() -> bool:
	for path in _pending_textures.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var loaded := ResourceLoader.load_threaded_get(path) as Texture2D
			_pending_textures.erase(path)
			if loaded == null:
				_failed_textures[path] = true
				_texture_waiters.erase(path)
				push_warning("Threaded card-art loading returned no texture for %s." % path)
				continue
			_cache_texture(path,loaded)
			var waiters: Dictionary = _texture_waiters.get(path,{})
			for reference in waiters.values():
				var target := (reference as WeakRef).get_ref() as TextureRect
				if is_instance_valid(target) and target.has_meta("nichirin_texture_path") and str(target.get_meta("nichirin_texture_path")) == path:
					target.texture = loaded
			_texture_waiters.erase(path)
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_pending_textures.erase(path)
			_texture_waiters.erase(path)
			_failed_textures[path] = true
			push_warning("Threaded card-art loading failed for %s." % path)
	return has_pending_textures()

static func _cache_texture(path: String, loaded: Texture2D) -> void:
	texture_cache[path] = loaded
	_touch_texture(path)
	while texture_cache.size() > MAX_CACHED_TEXTURES and not _texture_lru.is_empty():
		var oldest: String = _texture_lru.pop_front()
		if oldest != path:
			texture_cache.erase(oldest)

static func _touch_texture(path: String) -> void:
	_texture_lru.erase(path)
	_texture_lru.append(path)

func label_at(value: String, pos: Vector2, dims: Vector2, font_size: float, tint: Color, font: Font = BODY, wrap: bool = false) -> Label:
	var label := acquire_ui_node("Label") as Label
	label.text = value
	label.position = pos
	label.add_theme_font_override("font",font)
	label.add_theme_font_size_override("font_size",maxi(8,int(font_size)))
	label.add_theme_color_override("font_color",tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = not wrap
	if full_art:
		label.add_theme_color_override("font_outline_color",Color(0.02,0.02,0.04,0.95))
		label.add_theme_constant_override("outline_size",maxi(2,int(font_size*0.3)))
		label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75))
		label.add_theme_constant_override("shadow_offset_x",1)
		label.add_theme_constant_override("shadow_offset_y",1)
	if wrap: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if wrap: label.custom_minimum_size = Vector2(dims.x,0)
	add_child(label)
	label.size = dims
	# Wrapped text re-measures once the card enters the tree; restore its box width then.
	if wrap: label.set_deferred("size",dims)
	return label
