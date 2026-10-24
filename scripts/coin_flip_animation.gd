extends CanvasLayer

const GOLD := Color("#edca79")
const SUN_RED := Color("#7f2632")
const INK := Color("#111a29")
const CREAM := Color("#f4ead6")

func play(heads: bool, reduced_motion: bool) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var overlay := Control.new()
	overlay.name = "NichirinCoinFlip"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var frame := Panel.new()
	frame.size = Vector2(284, 236)
	frame.position = (viewport_size - frame.size) * 0.5
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(INK, 0.96)
	frame_style.border_color = GOLD
	frame_style.set_border_width_all(2)
	frame_style.set_corner_radius_all(12)
	frame.add_theme_stylebox_override("panel", frame_style)
	overlay.add_child(frame)

	var title := _label("NICHIRIN  /  SUN CREST", Rect2(10, 12, 264, 24), 13, GOLD)
	frame.add_child(title)

	var coin := Panel.new()
	coin.position = Vector2(78, 43)
	coin.size = Vector2(128, 128)
	coin.pivot_offset = coin.size * 0.5
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = SUN_RED
	coin_style.border_color = GOLD
	coin_style.set_border_width_all(7)
	coin_style.set_corner_radius_all(64)
	coin.add_theme_stylebox_override("panel", coin_style)
	frame.add_child(coin)

	for ray_index in range(12):
		var angle: float = TAU * float(ray_index) / 12.0
		var ray := ColorRect.new()
		ray.color = GOLD
		ray.size = Vector2(4, 15)
		var center := Vector2(64, 64)
		var direction := Vector2(cos(angle), sin(angle))
		ray.position = center + direction * 45.0 - ray.size * 0.5
		ray.rotation = angle + PI * 0.5
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.add_child(ray)

	var core := Panel.new()
	core.position = Vector2(24, 24)
	core.size = Vector2(80, 80)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var core_style := StyleBoxFlat.new()
	core_style.bg_color = Color("#351c27")
	core_style.border_color = Color("#f4dfac")
	core_style.set_border_width_all(2)
	core_style.set_corner_radius_all(40)
	core.add_theme_stylebox_override("panel", core_style)
	coin.add_child(core)

	var face := _label("SUN", Rect2(2, 19, 76, 39), 18, GOLD)
	face.add_theme_font_size_override("font_size", 18)
	core.add_child(face)
	var subtitle := _label("NICHIRIN", Rect2(0, 55, 80, 15), 8, CREAM)
	core.add_child(subtitle)

	var result := _label("FLIPPING", Rect2(10, 180, 264, 30), 19, CREAM)
	frame.add_child(result)
	var hint := _label("SUN BREATHING  •  HEADS OR TAILS", Rect2(10, 211, 264, 15), 8, GOLD)
	frame.add_child(hint)

	var step := 0.08 if reduced_motion else 0.13
	var flips := 2 if reduced_motion else 4
	for flip_index in range(flips):
		face.text = "SUN" if flip_index % 2 == 0 else "NICHIRIN"
		var tween := create_tween()
		tween.tween_property(coin, "scale:x", 0.08, step)
		tween.tween_property(coin, "scale:x", 1.0, step)
		await tween.finished

	result.text = "HEADS" if heads else "TAILS"
	result.add_theme_color_override("font_color", GOLD if heads else Color("#ec8273"))
	var finish := create_tween()
	finish.tween_property(coin, "scale", Vector2(1.12, 1.12), 0.08 if reduced_motion else 0.14)
	finish.tween_property(coin, "scale", Vector2.ONE, 0.08 if reduced_motion else 0.14)
	await finish.finished
	await get_tree().create_timer(0.14 if reduced_motion else 0.34).timeout
	if is_instance_valid(overlay):
		overlay.queue_free()

func _label(value: String, rect: Rect2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
