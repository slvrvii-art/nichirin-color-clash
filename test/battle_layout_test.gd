extends SceneTree

const LAYOUT := preload("res://scripts/battle_layout.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[BATTLE_LAYOUT_FAIL] " + message)


func _expect_near(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> void:
	_expect(actual.distance_to(expected) <= tolerance, "%s (%s / %s)" % [message, actual, expected])


func _run() -> void:
	var layout = LAYOUT.new()
	var cases := [
		{"size": Vector2(1440, 900), "insets": Vector4.ZERO, "profile": LAYOUT.PROFILE_STANDARD},
		{"size": Vector2(1920, 1080), "insets": Vector4.ZERO, "profile": LAYOUT.PROFILE_STANDARD},
		{"size": Vector2(1280, 720), "insets": Vector4(24, 16, 24, 16), "profile": LAYOUT.PROFILE_STANDARD},
		{"size": Vector2(1024, 768), "insets": Vector4(32, 24, 32, 24), "profile": LAYOUT.PROFILE_COMPACT},
		{"size": Vector2(2560, 1080), "insets": Vector4(48, 0, 48, 0), "profile": LAYOUT.PROFILE_STANDARD},
		{"size": Vector2(960, 1200), "insets": Vector4(12, 40, 12, 40), "profile": LAYOUT.PROFILE_COMPACT},
	]
	var reference_probe := Rect2(230, 158, 819, 133)

	for test_case: Dictionary in cases:
		layout.configure(test_case.size, test_case.insets, test_case.profile)
		var safe: Rect2 = layout.safe_rect()
		_expect(layout.profile == test_case.profile, "configured profile is retained")
		_expect(safe.position.x >= 0.0 and safe.position.y >= 0.0, "safe rectangle starts inside the viewport")
		_expect(safe.end.x <= test_case.size.x + 0.001 and safe.end.y <= test_case.size.y + 0.001, "safe rectangle ends inside the viewport")
		_expect(safe.size.x > 0.0 and safe.size.y > 0.0 and layout.fit_scale > 0.0, "safe area and fit scale remain positive")
		if test_case.size == LAYOUT.DESIGN_SIZE and test_case.insets == Vector4.ZERO:
			_expect(safe == Rect2(Vector2.ZERO, LAYOUT.DESIGN_SIZE), "reference viewport keeps a full zero-inset safe area")
			for zone_name: StringName in LAYOUT.ZONES:
				_expect(layout.zone(zone_name) == LAYOUT.ZONES[zone_name], "%s keeps its authored reference coordinates" % zone_name)
			_expect(layout.bench(0, 2) == Rect2(928, 485, 118, 173), "bench keeps its authored reference coordinates")

		for zone_name: StringName in LAYOUT.ZONES:
			var mapped_zone: Rect2 = layout.zone(zone_name)
			_expect(safe.grow(0.01).encloses(mapped_zone), "%s remains inside safe area at %s" % [zone_name, test_case.size])
		var mapped_bench: Rect2 = layout.bench(0, 2)
		_expect(safe.grow(0.01).encloses(mapped_bench), "bench zone remains inside safe area at %s" % test_case.size)

		var runtime_probe: Rect2 = layout.from_reference(reference_probe)
		var round_trip: Rect2 = layout.to_reference(runtime_probe)
		_expect_near(round_trip.position, reference_probe.position, 0.01, "reference position round-trips at %s" % test_case.size)
		_expect_near(round_trip.size, reference_probe.size, 0.01, "reference size round-trips at %s" % test_case.size)
		_expect_near(layout.from_viewport(layout.to_viewport(reference_probe.position)), reference_probe.position, 0.01, "point transform round-trips at %s" % test_case.size)

	layout.configure(Vector2(1280, 720), Vector4(-40, 6000, 6000, -20), LAYOUT.PROFILE_STANDARD)
	var clamped_safe: Rect2 = layout.safe_rect()
	_expect(clamped_safe.position.x >= 0.0 and clamped_safe.position.y >= 0.0, "negative insets clamp to zero")
	_expect(clamped_safe.end.x <= 1280.0 and clamped_safe.end.y <= 720.0, "oversized insets clamp within viewport")
	_expect(clamped_safe.size.x > 0.0 and clamped_safe.size.y > 0.0, "oversized insets leave a usable safe rectangle")
	_expect(layout.safe_insets.x == 0.0 and layout.safe_insets.w == 0.0, "invalid negative insets are discarded")
	for zone_name: StringName in LAYOUT.ZONES:
		_expect(clamped_safe.grow(0.01).encloses(layout.zone(zone_name)), "%s stays inside clamped safe area" % zone_name)

	if failures.is_empty():
		print("[BATTLE_LAYOUT_PASS] safe-area fitting and reversible design mapping validated")
		quit(0)
	else:
		quit(1)
