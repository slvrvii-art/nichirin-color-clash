extends SceneTree

const TWEAKS := preload("res://scripts/runtime_tweak_controls.gd")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[AUDIO_MUTE_FAIL] " + message)

func _run() -> void:
	var initial_bus_states: Array[Dictionary] = []
	for index in range(AudioServer.get_bus_count()):
		initial_bus_states.append({
			"volume_db": AudioServer.get_bus_volume_db(index),
			"muted": AudioServer.is_bus_mute(index),
		})

	var master_index := AudioServer.get_bus_index(&"Master")
	var music_index := AudioServer.get_bus_index(&"Music")
	var controls := TWEAKS.new()
	root.add_child(controls)
	await process_frame

	_expect(master_index >= 0, "Master output bus exists")
	_expect(music_index >= 0, "Music bus exists for per-bus volume verification")
	if master_index >= 0 and music_index >= 0:
		controls.set_value(&"audio.master_db", -6.0)
		controls.set_value(&"audio.music_db", -12.0)
		var master_volume := AudioServer.get_bus_volume_db(master_index)
		var music_volume := AudioServer.get_bus_volume_db(music_index)
		_expect(is_equal_approx(master_volume, -6.0), "Master volume control updates its stored bus volume")
		_expect(is_equal_approx(music_volume, -12.0), "Music volume control updates its stored bus volume")

		controls.set_value(&"audio.muted", true)
		_expect(controls.get_bool(&"audio.muted"), "mute request is retained")
		_expect(AudioServer.is_bus_mute(master_index), "mute request sets the Master output bus mute flag")
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(master_index), master_volume), "muting does not overwrite Master volume")
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(music_index), music_volume), "muting does not overwrite Music volume")

		controls.set_value(&"audio.muted", false)
		_expect(not controls.get_bool(&"audio.muted"), "unmute request is retained")
		_expect(not AudioServer.is_bus_mute(master_index), "unmute request clears the Master output bus mute flag")
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(master_index), master_volume), "unmuting restores audio without changing Master volume")
		_expect(is_equal_approx(AudioServer.get_bus_volume_db(music_index), music_volume), "unmuting preserves the Music volume setting")

	controls.free()
	for index in range(mini(initial_bus_states.size(), AudioServer.get_bus_count())):
		AudioServer.set_bus_volume_db(index, float(initial_bus_states[index].volume_db))
		AudioServer.set_bus_mute(index, bool(initial_bus_states[index].muted))

	if failures.is_empty():
		print("[AUDIO_MUTE_PASS] mute/unmute uses the Master bus flag and preserves bus volumes")
		quit(0)
	else:
		push_error("[AUDIO_MUTE_FAIL] %d assertions failed" % failures.size())
		quit(1)
