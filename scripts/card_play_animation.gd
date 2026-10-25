extends CanvasLayer

## A field-bound, input-transparent card reveal used before resolving a card's effect.
## The parent owns the action lock and drives texture polling for the reused CardFace.

const CARD_FACE_SCRIPT := preload("res://scripts/card_face.gd")
const UI_FONT := preload("res://assets/template/fonts/ui_medium.tres")

const GOLD := Color("#edca79")
const RIVAL_RED := Color("#9e3944")
const INK := Color("#101a2b")
const CREAM := Color("#f4ead6")
const NOMINAL_CARD_SIZE := Vector2(260.0, 380.0)
const FULL_GROW_DURATION := 0.15
const FULL_HOLD_DURATION := 0.60
const FULL_FADE_DURATION := 0.18
const REDUCED_HOLD_DURATION := 0.25
const REDUCED_FADE_DURATION := 0.12

signal presentation_started(card_id: String)
signal presentation_finished(card_id: String)

var playing: bool = false
var last_card_id: String = ""

var _field_rect := Rect2()
var _serial := 0
var _active_tween: Tween
var _current_card: Dictionary = {}

var _root: Control
var _backdrop: ColorRect
var _visual: Control
var _caption_panel: Panel
var _caption_accent: ColorRect
var _owner_caption: Label
var _context_caption: Label
var _glow: Panel
var _card_shell: Panel
var _face: Control


func _ready() -> void:
	_ensure_visuals()
	_layout_visuals()


## The parent passes its current mapped battlefield rectangle in canvas coordinates.
func configure_field(rect: Rect2) -> void:
	_field_rect = rect
	if is_node_ready():
		_ensure_visuals()
		_layout_visuals()
		if playing and not _current_card.is_empty():
			_prepare_face(_current_card)


## Presents one card. Await the returned bool: true means it reached its natural end;
## false means cancel() or a newer play() superseded it.
func play(card: Dictionary, owner_label: String, context_label: String, reduced_motion: bool) -> bool:
	if not is_node_ready():
		await ready
	_ensure_visuals()
	cancel()

	var token := _serial
	last_card_id = _card_id(card)
	_current_card = card
	_layout_visuals()
	_prepare_face(card)
	_set_caption(owner_label, context_label)
	_root.visible = true
	_visual.modulate = Color.WHITE
	_card_shell.scale = Vector2.ONE if reduced_motion else Vector2(0.78, 0.78)
	_card_shell.pivot_offset = _card_shell.size * 0.5
	_caption_panel.modulate = Color.WHITE
	_glow.modulate = Color.WHITE
	playing = true
	presentation_started.emit(last_card_id)

	var hold_duration := REDUCED_HOLD_DURATION if reduced_motion else FULL_HOLD_DURATION
	var fade_duration := REDUCED_FADE_DURATION if reduced_motion else FULL_FADE_DURATION
	var total_duration := hold_duration + fade_duration
	_active_tween = create_tween()
	if not reduced_motion:
		total_duration += FULL_GROW_DURATION
		_active_tween.tween_property(_card_shell, "scale", Vector2.ONE, FULL_GROW_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(hold_duration)
	_active_tween.tween_property(_visual, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.parallel().tween_property(_card_shell, "scale", Vector2(0.88, 0.88), fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Never await Tween.finished here: kill() intentionally does not emit it.
	var completed := await _wait_for_duration(token, total_duration)
	if not completed or token != _serial:
		return false

	_active_tween = null
	playing = false
	_root.visible = false
	_visual.modulate = Color.WHITE
	presentation_finished.emit(last_card_id)
	return true


## Immediately hides the presentation and causes any awaiting play() to return false.
func cancel() -> void:
	_serial += 1
	if _active_tween != null:
		_active_tween.kill()
		_active_tween = null
	playing = false
	if is_instance_valid(_root):
		_root.visible = false


func _ensure_visuals() -> void:
	if is_instance_valid(_root):
		return

	_root = Control.new()
	_root.name = "CardPlayOverlay"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.name = "FieldDim"
	_backdrop.color = Color(0.015, 0.028, 0.055, 0.52)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_backdrop)

	_visual = Control.new()
	_visual.name = "CardPresentation"
	_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_visual)

	_caption_panel = Panel.new()
	_caption_panel.name = "CaptionPanel"
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.add_theme_stylebox_override("panel", _caption_style())
	_visual.add_child(_caption_panel)

	_caption_accent = ColorRect.new()
	_caption_accent.color = RIVAL_RED
	_caption_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.add_child(_caption_accent)

	_owner_caption = _new_caption_label(RIVAL_RED)
	_owner_caption.name = "Owner"
	_caption_panel.add_child(_owner_caption)
	_context_caption = _new_caption_label(CREAM)
	_context_caption.name = "Context"
	_caption_panel.add_child(_context_caption)

	_glow = Panel.new()
	_glow.name = "GoldenGlow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.add_theme_stylebox_override("panel", _glow_style())
	_visual.add_child(_glow)

	_card_shell = Panel.new()
	_card_shell.name = "CardPanel"
	_card_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_shell.add_theme_stylebox_override("panel", _card_shell_style())
	_visual.add_child(_card_shell)

	_face = NichirinCardFace.acquire_ui_node("CardFace", CARD_FACE_SCRIPT)
	if _face == null:
		push_error("Card play animation could not acquire a NichirinCardFace.")
		return
	_face.name = "Face"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_shell.add_child(_face)


func _layout_visuals() -> void:
	if not is_instance_valid(_root):
		return
	var field := _usable_field_rect()
	_root.position = field.position
	_root.size = field.size
	_backdrop.position = Vector2.ZERO
	_backdrop.size = field.size

	# The caption and breathing room are included in the fit, so a narrow field
	# still receives a centered, entirely visible reveal rather than a clipped card.
	var available := field.size - Vector2(34.0, 58.0)
	var fit := minf(1.0, available.x / NOMINAL_CARD_SIZE.x)
	fit = minf(fit, available.y / (NOMINAL_CARD_SIZE.y + 34.0))
	fit = maxf(0.10, fit)
	var card_size := NOMINAL_CARD_SIZE * fit
	var shell_padding := maxf(3.0, 7.0 * fit)
	var caption_height := maxf(18.0, 30.0 * fit)
	var caption_gap := maxf(4.0, 8.0 * fit)
	var shell_size := card_size + Vector2.ONE * shell_padding * 2.0
	var visual_size := Vector2(shell_size.x, caption_height + caption_gap + shell_size.y)
	_visual.position = (field.size - visual_size) * 0.5
	_visual.size = visual_size

	_caption_panel.position = Vector2.ZERO
	_caption_panel.size = Vector2(shell_size.x, caption_height)
	_caption_accent.position = Vector2.ZERO
	_caption_accent.size = Vector2(maxf(3.0, 4.0 * fit), caption_height)
	var caption_inset := maxf(7.0, 11.0 * fit)
	var owner_width := shell_size.x * 0.42
	_owner_caption.position = Vector2(caption_inset, 0.0)
	_owner_caption.size = Vector2(owner_width - caption_inset, caption_height)
	_context_caption.position = Vector2(owner_width, 0.0)
	_context_caption.size = Vector2(shell_size.x - owner_width - caption_inset, caption_height)
	var caption_font_size := maxi(8, int(11.0 * fit))
	_owner_caption.add_theme_font_size_override("font_size", caption_font_size)
	_context_caption.add_theme_font_size_override("font_size", caption_font_size)

	_card_shell.position = Vector2(0.0, caption_height + caption_gap)
	_card_shell.size = shell_size
	_card_shell.pivot_offset = shell_size * 0.5
	_glow.position = _card_shell.position - Vector2.ONE * maxf(5.0, 10.0 * fit)
	_glow.size = shell_size + Vector2.ONE * maxf(10.0, 20.0 * fit)
	if is_instance_valid(_face):
		_face.position = Vector2.ONE * shell_padding
		_face.size = card_size
		_face.pivot_offset = card_size * 0.5


func _prepare_face(card: Dictionary) -> void:
	if not is_instance_valid(_face):
		return
	# CardFace internally acquires labels and texture targets; return those nodes
	# before rebuilding so repeated reveals do not accumulate UI or stale art targets.
	NichirinCardFace.recycle_children(_face)
	_face.setup(card, true, _face.size, false)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_caption(owner_label: String, context_label: String) -> void:
	_owner_caption.text = owner_label.to_upper()
	_context_caption.text = context_label.to_upper()
	_owner_caption.tooltip_text = owner_label
	_context_caption.tooltip_text = context_label


func _wait_for_duration(token: int, _duration: float) -> bool:
	while token == _serial and is_inside_tree():
		if _active_tween == null or not _active_tween.is_running():
			return true
		await get_tree().process_frame
	return false


func _usable_field_rect() -> Rect2:
	if _field_rect.size.x > 0.0 and _field_rect.size.y > 0.0:
		return _field_rect
	if is_inside_tree():
		return get_viewport().get_visible_rect()
	return Rect2(Vector2.ZERO, NOMINAL_CARD_SIZE + Vector2(60.0, 80.0))


func _card_id(card: Dictionary) -> String:
	var identifier := str(card.get("id", card.get("card_id", card.get("slug", ""))))
	if identifier.is_empty():
		identifier = str(card.get("number", card.get("name", "card")))
	return identifier


func _new_caption_label(tint: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", UI_FONT)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_outline_color", Color("#050914"))
	label.add_theme_constant_override("outline_size", 1)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	return label


func _caption_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.97)
	style.border_color = Color(GOLD, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 5
	return style


func _glow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GOLD, 0.06)
	style.border_color = Color(GOLD, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(GOLD, 0.16)
	style.shadow_size = 14
	return style


func _card_shell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.98)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 12
	return style


func _exit_tree() -> void:
	cancel()
	if is_instance_valid(_face):
		# Its children were acquired from CardFace's static UI pool and must be
		# recycled before the face itself is returned to that pool.
		NichirinCardFace.recycle_children(_face)
		NichirinCardFace.recycle_tree(_face)
	_face = null
