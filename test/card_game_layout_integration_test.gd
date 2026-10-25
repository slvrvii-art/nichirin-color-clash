extends SceneTree

const CARD_GAME := preload("res://scripts/card_game.gd")
const LAYOUT := preload("res://scripts/battle_layout.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[CARD_GAME_LAYOUT_FAIL] " + message)


func _expect_near(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(actual.distance_to(expected) <= 0.01, "%s (%s / %s)" % [message, actual, expected])


func _rect_after_root_transform(game: Variant, reference_rect: Rect2) -> Rect2:
	var root := game.root_ui as Control
	var scale := root.scale.x
	return Rect2(root.position + reference_rect.position * scale, reference_rect.size * scale)


func _run() -> void:
	var game = CARD_GAME.new()
	var root_ui := Control.new()
	root_ui.size = LAYOUT.DESIGN_SIZE
	game.root_ui = root_ui
	game.add_child(root_ui)

	game._apply_battle_layout(LAYOUT.DESIGN_SIZE, Vector4.ZERO)
	_expect(root_ui.position == Vector2.ZERO and root_ui.scale == Vector2.ONE, "authored viewport keeps the root transform neutral")
	_expect(game._battle_reference_zone(&"player_active") == LAYOUT.ZONES[&"player_active"], "board zone is converted back to authored coordinates before child placement")

	var viewport_size := Vector2(1280, 720)
	var safe_insets := Vector4(24, 16, 24, 16)
	game._apply_battle_layout(viewport_size, safe_insets)
	var safe_rect: Rect2 = game.battle_layout.safe_rect()
	_expect(root_ui.position == game.battle_layout.fit_offset, "root canvas is offset into the safe area")
	_expect(is_equal_approx(root_ui.scale.x, game.battle_layout.fit_scale) and is_equal_approx(root_ui.scale.y, game.battle_layout.fit_scale), "root canvas uses the uniform viewport fit scale")

	for zone_name: StringName in [&"enemy_active", &"player_active", &"enemy_bench", &"player_bench"]:
		var reference_rect: Rect2 = game._battle_reference_zone(zone_name)
		var mapped_rect := _rect_after_root_transform(game, reference_rect)
		var expected_rect: Rect2 = game.battle_layout.zone(zone_name)
		_expect_near(mapped_rect.position, expected_rect.position, "%s maps once into viewport space" % zone_name)
		_expect_near(mapped_rect.size, expected_rect.size, "%s keeps its scaled size" % zone_name)
		_expect(safe_rect.grow(0.01).encloses(mapped_rect), "%s stays within the safe rectangle" % zone_name)

	var bench_reference: Rect2 = game._battle_reference_bench(0, 2)
	var bench_mapped := _rect_after_root_transform(game, bench_reference)
	var expected_bench: Rect2 = game.battle_layout.bench(0, 2)
	_expect_near(bench_mapped.position, expected_bench.position, "bench position maps once")
	_expect_near(bench_mapped.size, expected_bench.size, "bench size maps once")
	_expect(safe_rect.grow(0.01).encloses(bench_mapped), "bench stays within the safe rectangle")

	game.free()
	if failures.is_empty():
		print("[CARD_GAME_LAYOUT_PASS] root transform and board geometry honor viewport and safe-area inputs")
		quit(0)
	else:
		quit(1)
