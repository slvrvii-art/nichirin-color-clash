extends SceneTree

const CARD_GAME := preload("res://scripts/card_game.gd")
const ATOMIC_JSON := preload("res://scripts/atomic_json_file.gd")
const TEST_PATH := "user://card_game_save_handling_test.json"
const BLOCKER_PATH := "user://card_game_save_handling_blocker"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("[CARD_GAME_SAVE_FAIL] " + message)


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _cleanup() -> void:
	for path in [TEST_PATH, TEST_PATH + ATOMIC_JSON.BACKUP_SUFFIX, TEST_PATH + ATOMIC_JSON.TEMPORARY_SUFFIX, BLOCKER_PATH]:
		_remove(path)


func _run() -> void:
	_cleanup()
	var game := CARD_GAME.new()
	game.wins = 2
	game.matches = 4
	game.match_record_saved = false

	var blocker := FileAccess.open(BLOCKER_PATH, FileAccess.WRITE)
	_expect(blocker != null, "test can create a file that blocks the save directory")
	if blocker != null:
		blocker.store_string("directory blocker")
		blocker.close()
		var failed_save: bool = game._persist_save(BLOCKER_PATH + "/save.json")
		_expect(not failed_save, "atomic write failure is returned to the card-game save handler")
		_expect(game.save_pending, "failed write keeps local progress marked pending")
		_expect(game.last_save_error != OK, "failed write retains the returned error code")
		_expect(game.notice.contains("Local save failed"), "failed write produces a visible save failure notice")
		_expect(not game.match_record_saved, "failed write does not mark the match record as saved")

	_remove(BLOCKER_PATH)
	var recovered_save: bool = game._persist_save(TEST_PATH)
	_expect(recovered_save, "a later write can retry and recover the pending save")
	_expect(not game.save_pending and game.last_save_error == OK, "successful retry clears pending/error state")
	_expect(game.match_record_saved, "successful retry records that the match result is now saved")
	var saved := ATOMIC_JSON.load_dictionary(TEST_PATH)
	_expect(int(saved.get("wins", -1)) == 2 and int(saved.get("matches", -1)) == 4, "retry persists the latest match counters")

	_cleanup()
	game.free()
	if failures.is_empty():
		print("[CARD_GAME_SAVE_PASS] save errors surface and pending match data retries successfully")
		quit(0)
	else:
		quit(1)
