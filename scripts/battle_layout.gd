class_name EmberpanBattleLayout
extends RefCounted

const DESIGN_SIZE := Vector2(1440, 900)
const PROFILE_STANDARD := &"standard"
const PROFILE_COMPACT := &"compact"
const MIN_SAFE_REMAINDER := 0.01
const ZONES := {
	&"enemy_active": Rect2(433, 145, 154, 224),
	&"player_active": Rect2(433, 457, 154, 224),
	&"enemy_bench": Rect2(660, 152, 396, 183),
	&"player_bench": Rect2(660, 485, 396, 183),
	&"hand": Rect2(148, 738, 928, 138),
	&"actions": Rect2(1110, 135, 290, 716),
	&"history": Rect2(150, 154, 228, 514),
}

var viewport_size := DESIGN_SIZE
var safe_insets := Vector4.ZERO
var profile: StringName = PROFILE_STANDARD
var safe_area := Rect2(Vector2.ZERO, DESIGN_SIZE)
var fit_scale := 1.0
var fit_offset := Vector2.ZERO


func configure(new_viewport_size: Vector2 = DESIGN_SIZE, new_safe_insets: Vector4 = Vector4.ZERO, new_profile: StringName = PROFILE_STANDARD) -> void:
	viewport_size = Vector2(
		new_viewport_size.x if is_finite(new_viewport_size.x) and new_viewport_size.x > 0.0 else DESIGN_SIZE.x,
		new_viewport_size.y if is_finite(new_viewport_size.y) and new_viewport_size.y > 0.0 else DESIGN_SIZE.y
	)
	profile = new_profile

	var left := _valid_inset(new_safe_insets.x)
	var top := _valid_inset(new_safe_insets.y)
	var right := _valid_inset(new_safe_insets.z)
	var bottom := _valid_inset(new_safe_insets.w)
	var horizontal := _clamp_inset_pair(left, right, viewport_size.x)
	var vertical := _clamp_inset_pair(top, bottom, viewport_size.y)
	left = horizontal.x
	right = horizontal.y
	top = vertical.x
	bottom = vertical.y
	safe_insets = Vector4(left, top, right, bottom)
	safe_area = Rect2(left, top, viewport_size.x - left - right, viewport_size.y - top - bottom)

	fit_scale = minf(safe_area.size.x / DESIGN_SIZE.x, safe_area.size.y / DESIGN_SIZE.y)
	fit_offset = safe_area.position + (safe_area.size - DESIGN_SIZE * fit_scale) * 0.5


func _valid_inset(value: float) -> float:
	return maxf(value, 0.0) if is_finite(value) else 0.0


func _clamp_inset_pair(first: float, second: float, extent: float) -> Vector2:
	var total := first + second
	var maximum_total := extent * (1.0 - MIN_SAFE_REMAINDER)
	if total > maximum_total and total > 0.0:
		var ratio := maximum_total / total
		return Vector2(first * ratio, second * ratio)
	return Vector2(first, second)


func safe_rect() -> Rect2:
	return safe_area


func safe_canvas() -> Rect2:
	return safe_area


func zone(identifier: StringName) -> Rect2:
	return from_reference(ZONES.get(identifier, Rect2()))


func bench(side: int, index: int) -> Rect2:
	var reference_rect := Rect2(660 + index * 134, 152 if side == 1 else 485, 118, 173)
	return from_reference(reference_rect)


func to_viewport(point: Vector2) -> Vector2:
	return fit_offset + point * fit_scale


func from_viewport(point: Vector2) -> Vector2:
	return (point - fit_offset) / fit_scale


func from_reference(reference_rect: Rect2) -> Rect2:
	return Rect2(to_viewport(reference_rect.position), reference_rect.size * fit_scale)


func to_reference(viewport_rect: Rect2) -> Rect2:
	return Rect2(from_viewport(viewport_rect.position), viewport_rect.size / fit_scale)
