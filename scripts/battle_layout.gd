class_name EmberpanBattleLayout
extends RefCounted

const DESIGN_SIZE := Vector2(1440,900)
const PROFILE_STANDARD := &"standard"
const PROFILE_COMPACT := &"compact"
const ZONES := {
	&"enemy_active":Rect2(433,145,154,224),
	&"player_active":Rect2(433,457,154,224),
	&"enemy_bench":Rect2(660,152,396,183),
	&"player_bench":Rect2(660,485,396,183),
	&"hand":Rect2(148,738,928,138),
	&"actions":Rect2(1110,135,290,716),
	&"history":Rect2(150,154,228,514)
}
var viewport_size := DESIGN_SIZE
func configure(new_viewport_size: Vector2 = DESIGN_SIZE, _safe_insets: Vector4 = Vector4.ZERO, _profile: StringName = PROFILE_STANDARD) -> void:
	viewport_size = new_viewport_size
func zone(identifier: StringName) -> Rect2:
	return ZONES.get(identifier,Rect2())
func bench(side: int, index: int) -> Rect2:
	return Rect2(660+index*134,152 if side==1 else 485,118,173)
